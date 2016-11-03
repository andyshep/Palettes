//
//  CachingIncrementalStore.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/7/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import CoreData

let kPALResourceIdentifierAttributeName = "__pal__resourceIdentifier"
let kPALLastModifiedAttributeName = "__pal__lastModified"

typealias InsertOrUpdateCompletion = (_ managedObjects: [AnyObject], _ backingObjects:[AnyObject]) -> Void

@objc(CachingIncrementalStore)

/// An Incremental Store subclass for retrieving Palettes from the Colour Lovers API
class CachingIncrementalStore : NSIncrementalStore {
    
    /// The cache of managed object ids
    private let cache = NSMutableDictionary()
    
    /// The cache of managed object ids for the backing store
    private let backingObjectIDCache = NSCache<NSManagedObjectID, NSManagedObjectID>()
    
    /// A map of registered objects ids
    private let registeredObjectIDsMap = NSMutableDictionary()
    
    class var storeType: String {
        return String(describing: CachingIncrementalStore.self)
    }
    
    override class func initialize() {
        NSPersistentStoreCoordinator.registerStoreClass(self, forStoreType:self.storeType)
    }
    
    // MARK: - Lazy Accessors
    
    /// The persistent store coordinator attached to the backing store.
    lazy var backingPersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.augmentedModel)
        
        var error: NSError? = nil
        let storeType = NSSQLiteStoreType
        let path = CachingIncrementalStore.storeType + ".sqlite"
        let url = URL.applicationDocumentsDirectory().appendingPathComponent(path)
        let options = [NSMigratePersistentStoresAutomaticallyOption: NSNumber(value: true),
            NSInferMappingModelAutomaticallyOption: NSNumber(value: true)];
        
        do {
            try coordinator.addPersistentStore(ofType: storeType, configurationName: nil, at: url, options: options)
        }
        catch (let error) {
            abort()
        }
        
        return coordinator
    }()
    
    /// The managed object context for the backing store
    lazy var backingManagedObjectContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.backingPersistentStoreCoordinator
        context.retainsRegisteredObjects = true
        return context
    }()
    
    /// The model for the backing store, augmented with custom attributes
    lazy var augmentedModel: NSManagedObjectModel = {
        let augmentedModel = self.persistentStoreCoordinator?.managedObjectModel.copy() as! NSManagedObjectModel
        for entity in augmentedModel.entities {
            if entity.superentity != nil {
                continue
            }
            
            let resourceIdProperty = NSAttributeDescription()
            resourceIdProperty.name = kPALResourceIdentifierAttributeName
            resourceIdProperty.attributeType = NSAttributeType.stringAttributeType
            resourceIdProperty.isIndexed = true
            
            let lastModifiedProperty = NSAttributeDescription()
            lastModifiedProperty.name = kPALLastModifiedAttributeName
            lastModifiedProperty.attributeType = NSAttributeType.dateAttributeType
            lastModifiedProperty.isIndexed = false
            
            var properties = entity.properties
            properties.append(resourceIdProperty)
            properties.append(lastModifiedProperty)
            
            entity.properties = properties
        }
        
        return augmentedModel
    }()
    
    // MARK: - NSIncrementalStore
    
    override func loadMetadata() throws {
        let uuid = ProcessInfo.processInfo.globallyUniqueString
        self.metadata = [NSStoreTypeKey : CachingIncrementalStore.storeType, NSStoreUUIDKey: uuid]
    }
    
    override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> Any {
        let error: NSError? = nil
        if request.requestType == .fetchRequestType {
            return try self.executeFetchRequest(request, withContext: context)
        }
        
        throw error!
    }

    override func newValuesForObject(with objectID: NSManagedObjectID, with context: NSManagedObjectContext) throws -> NSIncrementalStoreNode {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: objectID.entity.name!)
        fetchRequest.resultType = NSFetchRequestResultType.dictionaryResultType
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        
        let refObj = self.referenceObject(for: objectID) as! NSString
        let predicate = NSPredicate(format: "%K = %@", kPALResourceIdentifierAttributeName, refObj.description)
        fetchRequest.predicate = predicate
        
        var results: [AnyObject]? = nil
        let privateContext = self.backingManagedObjectContext
        privateContext.performAndWait(){
            results = try! privateContext.fetch(fetchRequest)
        }
        
        let values = results?.last as? [String: AnyObject] ?? [:]
        let node = NSIncrementalStoreNode(objectID: objectID, withValues: values, version: 1)
        return node
    }
    
    // MARK: - Private
    
    /**
    Executes a fetch request within the context provided
    
    :param: request The request for the store.
    :param: context The context to execure the request within
    :param: error If an error occurs, on return contains an `NSError` object that describes the problem.
    
    :returns: An optional array of managed objects
    */
    
    func executeFetchRequest(_ request: NSPersistentStoreRequest!, withContext context: NSManagedObjectContext!) throws -> [AnyObject] {
        var error: NSError? = nil
        guard let fetchRequest = request as? NSFetchRequest<NSFetchRequestResult> else { fatalError() }
        let backingContext = self.backingManagedObjectContext
        
        if fetchRequest.resultType == NSFetchRequestResultType() {
            self.fetchRemoteObjectsWithRequest(fetchRequest, context: context)
            
            let cacheFetchRequest = request.copy() as! NSFetchRequest<NSFetchRequestResult>
            cacheFetchRequest.entity = NSEntityDescription.entity(forEntityName: fetchRequest.entityName!, in: backingContext)
            cacheFetchRequest.resultType = NSFetchRequestResultType()
            cacheFetchRequest.propertiesToFetch = [kPALResourceIdentifierAttributeName]
            
            let results = (try! backingContext.fetch(cacheFetchRequest)) as NSArray
            let resourceIds = results.value(forKeyPath: kPALResourceIdentifierAttributeName) as! [NSString]
            
            let managedObjects = resourceIds.map({ (resourceId: NSString) -> NSManagedObject in
                let objectId = self.objectIDForEntity(fetchRequest.entity!, withResourceIdentifier: resourceId)
                let managedObject = context.object(with: objectId!) as! Palette
                
                let predicate = NSPredicate(format: "%K = %@", kPALResourceIdentifierAttributeName, resourceId)
                let backingObj = results.filtered(using: predicate).first as! Palette
                
                managedObject.transformWithPalette(backingObj)
                return managedObject
            })
            
            return managedObjects
        }
        else if fetchRequest.resultType == .managedObjectIDResultType {
            do {
                try backingContext.fetch(fetchRequest)
            } catch let error as NSError {
                print("erorr fetching object ids: \(error)")
            }
            return []
        }
        else if fetchRequest.resultType == .countResultType || fetchRequest.resultType == .dictionaryResultType {
            do {
                return try backingContext.fetch(fetchRequest)
            } catch let error1 as NSError {
                error = error1
                throw error!
            }
        }
        else {
            throw error!
        }
    }
    
    /**
    Insert or updates an entity set from the result provided. The entity set will be inserted into context provide
    and into the backing context. The completion function will be called with valid references to the update objects.
    
    :param: result An set of `NSManagedObjects` that has been retrieved
    :param: entity A valid entity within the model
    :param: context A managed object context
    :param: completion A function that accepts inserted objects and backing objects
    
    :returns: success A Bool representing success or failure
    */
    
    func insertOrUpdateObjects(_ result: [AnyObject]?, ofEntity entity: NSEntityDescription, context: NSManagedObjectContext, completion: InsertOrUpdateCompletion) -> Bool {
        if let objects = result {
            var managedObjects: [AnyObject] = []
            var backingObjects: [AnyObject] = []
            
            for obj in objects {
                if let paletteObj = obj as? NSDictionary {
                    let _ = paletteObj.stringValueForKey("title")
                    let uniqueId = NSString(string: paletteObj.numberValueForKey("id").stringValue)
                    
                    var backingObject: Palette? = nil
                    
                    let backingObjectId = self.objectIDFromBackingContextForEntity(entity, withResourceIdentifier: uniqueId as NSString?)
                    let backingContext = self.backingManagedObjectContext
                    
                    backingContext.performAndWait() {
                        if let backingObjectId = backingObjectId {
                            do {
                                backingObject = try backingContext.existingObject(with: backingObjectId) as? Palette
                            }
                            catch {
                                fatalError("existing object matching id not found")
                            }
                        }
                        else {
                            guard let backingObj = NSEntityDescription.insertNewObject(forEntityName: entity.name!, into: backingContext) as? Palette else {
                                fatalError("backingObject not found")
                            }
                            
                            backingObject = backingObj
                            
                            do {
                                try backingObject!.managedObjectContext?.obtainPermanentIDs(for: [backingObject!])
                            }
                            catch {
                                fatalError("permanent object ids could not be obtained")
                            }
                        }
                    }
                    
                    backingObject?.setValue(uniqueId, forKey: kPALResourceIdentifierAttributeName)
                    backingObject?.transformWithDictionary(paletteObj)
                    
                    var managedObject: Palette? = nil
                    context.performAndWait({ () -> Void in
                        if let objectId = self.objectIDForEntity(entity, withResourceIdentifier: uniqueId) {
                            
                            do {
                                managedObject = try context.existingObject(with: objectId) as? Palette
                            }
                            catch {
                                //
                            }
                            
                        }
                    })
                    
                    managedObject?.transformWithDictionary(paletteObj)
                    
                    guard let _ = managedObject else {
                        fatalError("managedObject should not be nil")
                    }
                    
                    if backingObjectId != nil {
                        context.insert(managedObject!)
                    }
                    
                    if let _ = managedObject {
                        managedObjects.append(managedObject!)
                    }
                    
                    if let _ = backingObject {
                        backingObjects.append(backingObject!)
                    }
                }
            }
            
            completion(managedObjects, backingObjects)
            return true
        }
        
        return false
    }
    
    /**
    Finds an objectID for an entity using an associated resource identifier.
    
    :param: entity A valid entity within the model
    :param: identifier A resource identifier
    
    :returns: objectId
    */
    
    func objectIDForEntity(_ entity:NSEntityDescription, withResourceIdentifier identifier:NSString?) -> NSManagedObjectID? {
        if identifier == nil {
            return nil
        }
        
        var managedObjectId: NSManagedObjectID? = nil
        if let objectIDsByResourceIdentifier = self.registeredObjectIDsMap.object(forKey: entity.name!) as? NSDictionary {
            managedObjectId = objectIDsByResourceIdentifier.object(forKey: identifier!) as? NSManagedObjectID
        }
        
        if managedObjectId == nil {
            let referenceObject = "__pal__" + String(identifier!)
            managedObjectId = self.newObjectID(for: entity, referenceObject: referenceObject)
        }
        
        return managedObjectId
    }
    
    /**
    Finds an objectID for an entity using an associated resource identifier. The objectId returned
    will belong to the backing context
    
    :param: entity A valid entity within the model
    :param: identifier A resource identifier
    
    :returns: objectId
    */
    
    func objectIDFromBackingContextForEntity(_ entity:NSEntityDescription, withResourceIdentifier identifier:NSString?) -> NSManagedObjectID? {
        if identifier == nil {
            return nil
        }
        
        let objectId = self.objectIDForEntity(entity, withResourceIdentifier: identifier)
        var backingObjectId = backingObjectIDCache.object(forKey: objectId!)
        if backingObjectId != nil {
            return backingObjectId
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObjectID>(entityName: entity.name!)
        fetchRequest.resultType = NSFetchRequestResultType.managedObjectIDResultType
        fetchRequest.fetchLimit = 1
        
        let predicate = NSPredicate(format: "%K = %@", kPALResourceIdentifierAttributeName, identifier!)
        fetchRequest.predicate = predicate
        
        let privateContext = self.backingManagedObjectContext
        privateContext.performAndWait() {
            do {
                let results = try privateContext.fetch(fetchRequest)
                backingObjectId = results.last
                
                if backingObjectId != nil {
                    self.backingObjectIDCache.setObject(backingObjectId!, forKey: objectId!)
                }
            }
            catch (let error) {
                print("error executing fetch request: \(error)")
            }
        }
        
        return backingObjectId
    }
    
    /**
    Fetches remote objects associated with a request. The remote objects will be inserted or updated
    into the context provided. The objects will also be saved into the backing context.
    
    :param: fetchRequest The fetch request used to return remote objects.
    :param: identifier A context
    */
    
    func fetchRemoteObjectsWithRequest(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>, context: NSManagedObjectContext) -> Void {
        
        let parseJsonData = { (data: Data) -> Void in
            guard let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyObject] else {
                return
            }
            
            let palettes = jsonResult.filter({ (obj: AnyObject) -> Bool in
                return (obj is NSDictionary)
            })
            
            context.performAndWait(){
                let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                childContext.parent = context
                
                childContext.performAndWait(){
                    let _ = self.insertOrUpdateObjects(palettes, ofEntity: fetchRequest.entity!, context: childContext, completion:{(managedObjects: [AnyObject], backingObjects: [AnyObject]) -> Void in
                        
                        childContext.saveOrLogError()
                        
                        self.backingManagedObjectContext.performAndWait() {
                            self.backingManagedObjectContext.saveOrLogError()
                        }
                        
                        context.performAndWait() {
                            let objects = childContext.registeredObjects as NSSet
                            
                            objects.forEach({ (object) in
                                let childObject = object as! NSManagedObject
                                let parentObject = context.object(with: childObject.objectID)
                                context.refresh(parentObject, mergeChanges: true)
                            })
                        }
                    })
                }
            }
        }
        
        let responseHandler: ((Data) -> Void) = {(data) in
            do {
                try parseJsonData(data)
            }
            catch (let error) {
                print("error handling json response: \(error)")
            }
        }
        
        let offset = fetchRequest.fetchOffset
        let limit = fetchRequest.fetchLimit
        let httpRequest = ColourLovers.topPalettes.request(offset, limit: limit)
        
        NetworkController.task(httpRequest, result: { (taskResult) -> Void in
            switch taskResult {
            case .success(let data):
                responseHandler(data)
            case .failure(let error):
                print(error)
            }
        }).resume()
    }
}

extension NSManagedObjectContext {
    func saveOrLogError() -> Void {
        var error: NSError? = nil
        do {
            try self.save()
        } catch let error1 as NSError {
            error = error1
            print("error saving context: \(error)")
        }
    }
}
