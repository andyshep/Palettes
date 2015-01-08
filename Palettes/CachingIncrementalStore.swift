//
//  CachingIncrementalStore.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/7/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import CoreData

let kResourceIdentifierAttributeName = "__pal__resourceIdentifier"
let kLastModifiedAttributeName = "__pal__lastModified"

@objc(CachingIncrementalStore)
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
    
    /// The model for the backing store, augment with custom attributes
    lazy var augmentedModel: NSManagedObjectModel = {
        let augmentedModel = self.persistentStoreCoordinator?.managedObjectModel.copy() as NSManagedObjectModel
        for object in augmentedModel.entities {
            if let entity = object as? NSEntityDescription {
                if entity.superentity != nil {
                    continue
                }
                
                let resourceIdProperty = NSAttributeDescription()
                resourceIdProperty.name = kResourceIdentifierAttributeName
                resourceIdProperty.attributeType = NSAttributeType.StringAttributeType
                resourceIdProperty.indexed = true
                
                let lastModifiedProperty = NSAttributeDescription()
                lastModifiedProperty.name = kLastModifiedAttributeName
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
    
    override class func initialize() {
        NSPersistentStoreCoordinator.registerStoreClass(self, forStoreType:self.storeType)
    }
    
    override func loadMetadata(error: NSErrorPointer) -> Bool {
        let uuid = NSProcessInfo.processInfo().globallyUniqueString
        self.metadata = [NSStoreTypeKey : CachingIncrementalStore.storeType, NSStoreUUIDKey : uuid]
        return true
    }
    
    override func executeRequest(request: NSPersistentStoreRequest, withContext context: NSManagedObjectContext, error: NSErrorPointer) -> AnyObject? {
        if request.requestType == .FetchRequestType {
            return self.executeFetchRequest(request, withContext: context, error: error)
        }
        else if request.requestType == .SaveRequestType {
            return self.executeSaveRequest(request, withContext: context, error: error)
        }
        
        return nil
    }
    
    override func newValuesForObjectWithID(objectID: NSManagedObjectID, withContext context: NSManagedObjectContext, error: NSErrorPointer) -> NSIncrementalStoreNode? {
        if let values = cache.objectForKey(objectID) as? NSDictionary {
            return NSIncrementalStoreNode(objectID: objectID, withValues: values, version: 1)
        }
        
        return nil
    }
    
    // MARK: - Private

    func objectIdForNewObjectOfEntity(entityDescription:NSEntityDescription, cacheValues values:AnyObject!) -> NSManagedObjectID! {
        if let dict = values as? NSDictionary {
            let nativeKey = entityDescription.name
            
            if let referenceId = dict.objectForKey("id")?.stringValue {
                let objectId = self.newObjectIDForEntity(entityDescription, referenceObject: referenceId)
                cache.setObject(values, forKey: objectId)
                return objectId
            }
        }
        
        return nil
    }
    
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
        else {
            return nil
        }
    }
    
    /**
    Executes a save request within the context provided
    
    :param: request The request for the store.
    :param: context The context to execure the request within
    :param: error If an error occurs, on return contains an `NSError` object that describes the problem.
    
    :returns: An optional array of managed objects
    */
    
    func executeSaveRequest(request: NSPersistentStoreRequest!, withContext context: NSManagedObjectContext!, error: NSErrorPointer) -> [AnyObject]! {
        println("save requests not yet implemented")
        
        return []
    }
    
    /**
    Fetch remote objects
    
    :param: fetchRequest The request for the store.
    :param: context The context to execure the request within
    
    :returns: An array of managed objects
    */
    
    func fetchRemoteObjectsWithRequest(fetchRequest: NSFetchRequest, context: NSManagedObjectContext) -> Void {
        let offset = fetchRequest.fetchOffset
        let limit = fetchRequest.fetchLimit
        let httpRequest = ColourLovers.TopPalettes.request(offset: offset, limit: limit)
        
        NetworkController.task(httpRequest, completion: { (data, error) -> Void in
            var err: NSError?
            let jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) as [AnyObject]
            let palettes = jsonResult.filter({ (obj: AnyObject) -> Bool in
                return (obj is NSDictionary)
            })
            
            println("have \(palettes.count) palettes to parse")
            
            // TODO: handle result
            
        }).resume()
        
//        let entities = paletteObjs.map({ (item: NSDictionary) -> Palette in
//            let objectId = self.objectIdForNewObjectOfEntity(fetchRequest.entity!, cacheValues: item)
//            let palette = context.objectWithID(objectId) as Palette
//            palette.transform(dictionary: item)
//            return palette
//        })
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
}
