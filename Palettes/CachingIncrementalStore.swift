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

typealias InsertOrUpdateCompletion = (managedObjects:AnyObject, backingObjects:AnyObject) -> Void

@objc(CachingIncrementalStore)

/// An Incremental Store subclass for retrieving Palettes from the Colour Lovers API
class CachingIncrementalStore : NSIncrementalStore {
    
    /// The cache of managed object ids
    private let cache = NSMutableDictionary()
    
    /// The cache of managed object ids for the backing store
    private let backingObjectIDCache = NSCache()
    
    /// A map of registered objects ids
    private let registeredObjectIDsMap = NSMutableDictionary()
    
    class var storeType: String {
        return NSStringFromClass(CachingIncrementalStore.self)
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
        let url = NSURL.applicationDocumentsDirectory().URLByAppendingPathComponent(path)
        let options = [NSMigratePersistentStoresAutomaticallyOption: NSNumber(bool: true),
            NSInferMappingModelAutomaticallyOption: NSNumber(bool: true)];
        
        if coordinator.addPersistentStoreWithType(storeType, configuration: nil, URL: url, options: options, error: &error) == nil {
            if let code = error?.code {
                if code == NSMigrationMissingMappingModelError {
                    println("Error, migration failed. Delete model at \(url)")
                }
                else {
                    println("Error creating persistent store: \(error?.description)")
                }
            }
            abort()
        }
        
        return coordinator
    }()
    
    /// The managed object context for the backing store
    lazy var backingManagedObjectContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.backingPersistentStoreCoordinator
        context.retainsRegisteredObjects = true
        return context
    }()
    
    /// The model for the backing store, augmented with custom attributes
    lazy var augmentedModel: NSManagedObjectModel = {
        let augmentedModel = self.persistentStoreCoordinator?.managedObjectModel.copy() as NSManagedObjectModel
        for object in augmentedModel.entities {
            if let entity = object as? NSEntityDescription {
                if entity.superentity != nil {
                    continue
                }
                
                let resourceIdProperty = NSAttributeDescription()
                resourceIdProperty.name = kPALResourceIdentifierAttributeName
                resourceIdProperty.attributeType = NSAttributeType.StringAttributeType
                resourceIdProperty.indexed = true
                
                let lastModifiedProperty = NSAttributeDescription()
                lastModifiedProperty.name = kPALLastModifiedAttributeName
                lastModifiedProperty.attributeType = NSAttributeType.DateAttributeType
                lastModifiedProperty.indexed = false
                
                var properties = entity.properties
                properties.append(resourceIdProperty)
                properties.append(lastModifiedProperty)
                
                entity.properties = properties
            }
        }
        
        return augmentedModel
    }()
    
    // MARK: - NSIncrementalStore
    
    override func loadMetadata(error: NSErrorPointer) -> Bool {
        let uuid = NSProcessInfo.processInfo().globallyUniqueString
        self.metadata = [NSStoreTypeKey : CachingIncrementalStore.storeType, NSStoreUUIDKey: uuid]
        
        return true
    }
    
    override func executeRequest(request: NSPersistentStoreRequest, withContext context: NSManagedObjectContext, error: NSErrorPointer) -> AnyObject? {
        if request.requestType == .FetchRequestType {
            return self.executeFetchRequest(request, withContext: context, error: error)
        }
        
        return nil
    }
    
    override func newValuesForObjectWithID(objectID: NSManagedObjectID, withContext context: NSManagedObjectContext, error: NSErrorPointer) -> NSIncrementalStoreNode? {
        let fetchRequest = NSFetchRequest(entityName: objectID.entity.name!)
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        
        let refObj = self.referenceObjectForObjectID(objectID) as NSString
        let predicate = NSPredicate(format: "%K = %@", kPALResourceIdentifierAttributeName, refObj.description)
        fetchRequest.predicate = predicate
        
        var error: NSError? = nil
        var results: [AnyObject]? = nil
        let privateContext = self.backingManagedObjectContext
        privateContext.performBlockAndWait(){
            results = privateContext.executeFetchRequest(fetchRequest, error: &error)
        }
        
        let attributeValues = (results?.count > 0) ? results?.last as NSDictionary : NSDictionary()
        let node = NSIncrementalStoreNode(objectID: objectID, withValues: attributeValues, version: 1)
        
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
    
    func executeFetchRequest(request: NSPersistentStoreRequest!, withContext context: NSManagedObjectContext!, error: NSErrorPointer) -> [AnyObject]! {
        var error: NSError? = nil
        let fetchRequest = request as NSFetchRequest
        let backingContext = self.backingManagedObjectContext
        
        if fetchRequest.resultType == .ManagedObjectResultType {
            self.fetchRemoteObjectsWithRequest(fetchRequest, context: context)
            
            let cacheFetchRequest = request.copy() as NSFetchRequest
            cacheFetchRequest.entity = NSEntityDescription.entityForName(fetchRequest.entityName!, inManagedObjectContext: backingContext)
            cacheFetchRequest.resultType = .ManagedObjectResultType
            cacheFetchRequest.propertiesToFetch = [kPALResourceIdentifierAttributeName]
            
            let results = backingContext.executeFetchRequest(cacheFetchRequest, error: &error)! as NSArray
            let resourceIds = results.valueForKeyPath(kPALResourceIdentifierAttributeName) as [NSString]
            
            let managedObjects = resourceIds.map({ (resourceId: NSString) -> NSManagedObject in
                let objectId = self.objectIDForEntity(fetchRequest.entity!, withResourceIdentifier: resourceId)
                let managedObject = context.objectWithID(objectId!) as Palette
                
                let predicate = NSPredicate(format: "%K = %@", kPALResourceIdentifierAttributeName, resourceId)
                let backingObj = results.filteredArrayUsingPredicate(predicate!).first as Palette
                
                managedObject.transform(palette: backingObj)
                return managedObject
            })
            
            return managedObjects
        }
        else if fetchRequest.resultType == .ManagedObjectIDResultType {
            let objectIds = backingContext.executeFetchRequest(fetchRequest, error: &error)
            return []
        }
        else if fetchRequest.resultType == .CountResultType || fetchRequest.resultType == .DictionaryResultType {
            return backingContext.executeFetchRequest(fetchRequest, error: &error)
        }
        else {
            return nil
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
    
    func insertOrUpdateObjects(result: [AnyObject]?, ofEntity entity: NSEntityDescription, context: NSManagedObjectContext, completion: InsertOrUpdateCompletion) -> Bool {
        if let objects = result {
            var managedObjects: [AnyObject] = []
            var backingObjects: [AnyObject] = []
            
            for obj in objects {
                if let paletteObj = obj as? NSDictionary {
                    let name = paletteObj.stringValueForKey("title")
                    let uniqueId = paletteObj.numberValueForKey("id").stringValue
                    
                    var error: NSError? = nil
                    
                    var backingObject: Palette? = nil
                    
                    let backingObjectId = self.objectIDFromBackingContextForEntity(entity, withResourceIdentifier: uniqueId)
                    let backingContext = self.backingManagedObjectContext
                    
                    backingContext.performBlockAndWait(){
                        if backingObjectId != nil {
                            backingObject = backingContext.existingObjectWithID(backingObjectId!, error: &error) as? Palette
                        }
                        else {
                            backingObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: backingContext) as? Palette
                            backingObject?.managedObjectContext?.obtainPermanentIDsForObjects([backingObject!], error: &error)
                        }
                    }
                    
                    backingObject?.setValue(uniqueId, forKey: kPALResourceIdentifierAttributeName)
                    backingObject?.transform(dictionary: paletteObj)
                    
                    var managedObject: Palette? = nil
                    context.performBlockAndWait({ () -> Void in
                        if let objectId = self.objectIDForEntity(entity, withResourceIdentifier: uniqueId) {
                            managedObject = context.existingObjectWithID(objectId, error: &error) as? Palette
                        }
                    })
                    
                    managedObject?.transform(dictionary: paletteObj)
                    
                    if backingObjectId != nil {
                        context.insertObject(managedObject!)
                    }
                    
                    managedObjects.append(managedObject!)
                    backingObjects.append(backingObject!)
                }
            }
            
            completion(managedObjects: managedObjects, backingObjects: backingObjects)
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
    
    func objectIDForEntity(entity:NSEntityDescription, withResourceIdentifier identifier:NSString?) -> NSManagedObjectID? {
        if identifier == nil {
            return nil
        }
        
        var managedObjectId: NSManagedObjectID? = nil
        if let objectIDsByResourceIdentifier = self.registeredObjectIDsMap.objectForKey(entity.name!) as? NSDictionary {
            managedObjectId = objectIDsByResourceIdentifier.objectForKey(identifier!) as? NSManagedObjectID
        }
        
        if managedObjectId == nil {
            let referenceObject = "__pal__" + identifier!
            managedObjectId = self.newObjectIDForEntity(entity, referenceObject: referenceObject)
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
    
    func objectIDFromBackingContextForEntity(entity:NSEntityDescription, withResourceIdentifier identifier:NSString?) -> NSManagedObjectID? {
        if identifier == nil {
            return nil
        }
        
        let objectId = self.objectIDForEntity(entity, withResourceIdentifier: identifier)
        var backingObjectId: NSManagedObjectID? = backingObjectIDCache.objectForKey(objectId!) as? NSManagedObjectID
        if backingObjectId != nil {
            return backingObjectId
        }
        
        let fetchRequest = NSFetchRequest(entityName: entity.name!)
        fetchRequest.resultType = NSFetchRequestResultType.ManagedObjectIDResultType
        fetchRequest.fetchLimit = 1
        
        let predicate = NSPredicate(format: "%K = %@", kPALResourceIdentifierAttributeName, identifier!)
        fetchRequest.predicate = predicate
        
        var error: NSError? = nil
        let privateContext = self.backingManagedObjectContext
        privateContext.performBlockAndWait() {
            if let results = privateContext.executeFetchRequest(fetchRequest, error: &error) {
                backingObjectId = results.last as? NSManagedObjectID
            }
        }
        
        if backingObjectId != nil {
            backingObjectIDCache.setObject(backingObjectId!, forKey: objectId!)
        }
        
        return backingObjectId
    }
    
    /**
    Fetches remote objects associated with a request. The remote objects will be inserted or updated
    into the context provided. The objects will also be saved into the backing context.
    
    :param: fetchRequest The fetch request used to return remote objects.
    :param: identifier A context
    */
    
    func fetchRemoteObjectsWithRequest(fetchRequest: NSFetchRequest, context: NSManagedObjectContext) -> Void {
        
        let responseHandler: (NSData -> Void) = {(data) in
            var err: NSError?
            let jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) as [AnyObject]
            let palettes = jsonResult.filter({ (obj: AnyObject) -> Bool in
                return (obj is NSDictionary)
            })
            
            context.performBlockAndWait(){
                let childContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                childContext.parentContext = context
                
                childContext.performBlockAndWait(){
                    let result = self.insertOrUpdateObjects(palettes, ofEntity: fetchRequest.entity!, context: childContext, completion:{(managedObjects: AnyObject, backingObjects: AnyObject) -> Void in
                        
                        childContext.saveOrLogError()
                        
                        self.backingManagedObjectContext.performBlockAndWait() {
                            self.backingManagedObjectContext.saveOrLogError()
                        }
                        
                        context.performBlockAndWait() {
                            let objects = childContext.registeredObjects.allObjects
                            objects.map({ (obj: AnyObject) -> Void in
                                let childObject = obj as NSManagedObject
                                let parentObject = context.objectWithID(childObject.objectID)
                                context.refreshObject(parentObject, mergeChanges: true)
                            })
                        }
                    })
                }
            }
        }
        
        let offset = fetchRequest.fetchOffset
        let limit = fetchRequest.fetchLimit
        let httpRequest = ColourLovers.TopPalettes.request(offset: offset, limit: limit)
        
        NetworkController.task(httpRequest, result: { (taskResult) -> Void in
            switch taskResult {
            case .Success(let data):
                responseHandler(data)
            case .Failure(let reason):
                println(reason.description())
            }
        }).resume()
    }
}

extension NSManagedObjectContext {
    func saveOrLogError() -> Void {
        var error: NSError? = nil
        if !self.save(&error) {
            println("error saving context: \(error)")
        }
    }
}
