//
//  PALIncrementalStore.swift
//  Palettes
//
//  Created by Andrew Shepard on 6/14/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreData

let kPALResourceIdentifierAttributeName: NSString = "__pal__resourceIdentifier"
let kPALLastModifiedAttributeName = "__pal__lastModified"

typealias InsertOrUpdateCompletion = (managedObjects:AnyObject, backingObjects:AnyObject) -> Void

@objc(PALIncrementalStore)
class PALIncrementalStore : NSIncrementalStore {
    let cache = NSMutableDictionary()
    let backingObjectIDCache = NSCache()
    let registeredObjectIDsMap = NSMutableDictionary()
    
    lazy var backingPersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
        
        let storeType = NSSQLiteStoreType
        let url = NSURL.applicationDocumentsDirectory().URLByAppendingPathComponent("PALIncrementalStore.sqlite")
        var error: NSError? = nil
        
        let options = [NSMigratePersistentStoresAutomaticallyOption: NSNumber(bool: true), NSInferMappingModelAutomaticallyOption: NSNumber(bool: true)];
        
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
    
    lazy var backingManagedObjectContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.backingPersistentStoreCoordinator
        context.retainsRegisteredObjects = true
        return context
    }()
    
    lazy var model: NSManagedObjectModel = {
        let model = self.persistentStoreCoordinator?.managedObjectModel.copy() as NSManagedObjectModel
        for obj : AnyObject in model.entities {
            if let entity = obj as? NSEntityDescription {
                if entity.superentity != nil {
                    continue
                }
                
                var resourceIdProperty = NSAttributeDescription()
                resourceIdProperty.name = kPALResourceIdentifierAttributeName
                resourceIdProperty.attributeType = NSAttributeType.StringAttributeType
                resourceIdProperty.indexed = true
                
                var lastModifiedProperty = NSAttributeDescription()
                lastModifiedProperty.name = kPALLastModifiedAttributeName
                lastModifiedProperty.attributeType = NSAttributeType.StringAttributeType
                lastModifiedProperty.indexed = false
                
                var newProperties = NSArray(objects: lastModifiedProperty, resourceIdProperty)
                var existingProperties = NSArray(array: entity.properties)
                newProperties = newProperties.arrayByAddingObjectsFromArray(existingProperties)
                entity.properties = newProperties
                
                // TODO: set custom attributes for modification time
                // these would be used by the row cache
            }
        }
        
        return model
    }()
    
    override init(persistentStoreCoordinator root: NSPersistentStoreCoordinator, configurationName name: String?, URL url: NSURL, options: [NSObject : AnyObject]?) {
        super.init(persistentStoreCoordinator: root, configurationName: name, URL: url, options: options)
    }
    
    override func loadMetadata(error: NSErrorPointer) -> Bool {
        var uuid = NSProcessInfo.processInfo().globallyUniqueString
        self.metadata = [NSStoreTypeKey : "PALIncrementalStore", NSStoreUUIDKey: uuid]
        
        // TODO: support schema migration
        
        return true
    }
    
    override func executeRequest(request: NSPersistentStoreRequest, withContext context: NSManagedObjectContext, error: NSErrorPointer) -> AnyObject? {
        if request.requestType == .FetchRequestType {
            return self.executeFetchRequest(request, withContext: context, error: error)
        }
        
        // TODO: implement save requests
        
        return nil
    }
    
    override func newValuesForObjectWithID(objectID: NSManagedObjectID, withContext context: NSManagedObjectContext, error: NSErrorPointer) -> NSIncrementalStoreNode? {
        var fetchRequest = NSFetchRequest(entityName: objectID.entity.name!)
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
        
        var attributeValues = (results?.count > 0) ? results?.last as NSDictionary : NSDictionary()
        var node = NSIncrementalStoreNode(objectID: objectID, withValues: attributeValues, version: 1)
        
        return node
    }

    override func obtainPermanentIDsForObjects(array: [AnyObject], error: NSErrorPointer) -> [AnyObject]? {
        var ids = NSMutableArray()
        for obj : AnyObject in array {
            let mobj = obj as NSManagedObject
            let refObj = NSProcessInfo.processInfo().globallyUniqueString
            let moid = self.newObjectIDForEntity(mobj.entity, referenceObject: refObj)
            ids.addObject(moid)
        }
        
        return ids
    }
    
    // MARK: - Private
    
    func objectIdForNewObjectOfEntity(entityDescription:NSEntityDescription, cacheValues values:AnyObject!) -> NSManagedObjectID! {
        if let dict = values as? NSDictionary {
            let nativeKey = entityDescription.name
            let referenceId: AnyObject! = dict.objectForKey(nativeKey!)
            let objectId = self.newObjectIDForEntity(entityDescription, referenceObject: referenceId)
            
            cache.setObject(values, forKey: objectId)
            
            return objectId
        }
        
        return nil
    }
    
    override func managedObjectContextDidRegisterObjectsWithIDs(objectIDs: [AnyObject]) {
        super.managedObjectContextDidRegisterObjectsWithIDs(objectIDs)
        
        for obj : AnyObject in objectIDs {
            let objectId = obj as NSManagedObjectID
            var referenceObj : AnyObject! = self.referenceObjectForObjectID(objectId)
            if referenceObj != nil {
                continue
            }
            
            referenceObj = "__pal__" + referenceObj.description
            
            var objectIDsByResourceIdentifier : (AnyObject!) = self.registeredObjectIDsMap.objectForKey(objectId.entity.name!)
            if objectIDsByResourceIdentifier == nil {
                objectIDsByResourceIdentifier = NSMutableDictionary()
            }
            
            objectIDsByResourceIdentifier.setObject(objectId, forKey: referenceObj)
            self.registeredObjectIDsMap.setObject(objectIDsByResourceIdentifier, forKey: objectId.entity.name!)
        }
    }
    
    override func managedObjectContextDidUnregisterObjectsWithIDs(objectIDs: [AnyObject]) {
        super.managedObjectContextDidUnregisterObjectsWithIDs(objectIDs)
        
        for objectId : AnyObject in objectIDs {
            // TODO: implement, unregister objects
        }
    }
    
    func executeFetchRequest(request: NSPersistentStoreRequest!, withContext context: NSManagedObjectContext!, error: NSErrorPointer) -> [AnyObject]! {
        let fetchRequest = request as NSFetchRequest
        let httpRequest = ColourLovers.TopPalettes.request()
        
        NetworkController.task(httpRequest, completion: { (data, error) -> Void in
            var err: NSError?
            let jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) as NSArray
            
            var palettes: [AnyObject] = []
            for obj in jsonResult {
                if let paletteObj = obj as? NSDictionary {
                    palettes.append(paletteObj)
                }
            }
            
            context.performBlockAndWait(){
                let childContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                childContext.parentContext = context
                childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                
                childContext.performBlockAndWait(){
                    let result = self.insertOrUpdateObjects(palettes, ofEntity: fetchRequest.entity!, context: childContext, completionHandler:{(managedObjects: AnyObject, backingObjects: AnyObject) -> Void in
                        
                        var error: NSError? = nil
                        let childObjects = childContext.registeredObjects
                        if !childContext.save(&error) {
                            println("error: \(error)")
                        }
                        
                        self.backingManagedObjectContext.performBlockAndWait() {
                            if !self.backingManagedObjectContext.save(&error) {
                                println("error: \(error)")
                            }
                        }
                        
                        context.performBlockAndWait(){
                            for obj in childObjects.allObjects {
                                let childObject = obj as NSManagedObject
                                let parentObject = context.objectWithID(childObject.objectID)
                                context.refreshObject(parentObject, mergeChanges: true)
                            }
                        }
                    })
                }
            }
            
        }).resume()
        
        var error: NSError? = nil
        let backingContext = self.backingManagedObjectContext
        var cacheFetchRequest = request.copy() as NSFetchRequest
        cacheFetchRequest.entity = NSEntityDescription.entityForName(fetchRequest.entityName!, inManagedObjectContext: backingContext)
        
        if fetchRequest.resultType == .ManagedObjectResultType {
            cacheFetchRequest.resultType = .DictionaryResultType
            cacheFetchRequest.propertiesToFetch = [kPALResourceIdentifierAttributeName]
            let results: NSArray = backingContext.executeFetchRequest(cacheFetchRequest, error: &error)!
            var mutableObjs = NSMutableArray()
            let resourceIds = results.valueForKeyPath(kPALResourceIdentifierAttributeName) as NSArray
            for obj: AnyObject in resourceIds {
                let resourceId = obj as NSString
                let objectId = self.objectIDForEntity(fetchRequest.entity!, withResourceIdentifier: resourceId)
                let managedObject = context.objectWithID(objectId!) as Palette
                
                managedObject.name = ""
                managedObject.id = ""
                managedObject.username = ""
                managedObject.colors = []
                
                let key = "__pal__" + resourceId
//                managedObject.setValue(resourceId, forKey: key)
                
                mutableObjs.addObject(managedObject)
            }
            
            return mutableObjs
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
    
    func insertOrUpdateObjects(result: AnyObject?, ofEntity entity: NSEntityDescription, context: NSManagedObjectContext, completionHandler: InsertOrUpdateCompletion) -> Bool {
        if result == nil {
            return false
        }
        
        let backingContext = self.backingManagedObjectContext
        // TODO: grab last modified from server response, save on cache object
        // track mod date via custom attribute
        
        let objects = result as? NSArray
            if objects == nil {
            return false
        }
            
        var mutableManagedObjects = NSMutableArray()
        var mutableBackingObjects = NSMutableArray()
            
        if let objects = result as? [AnyObject] {
            for obj in objects {
                if let paletteObj = obj as? NSDictionary {
                    // find the shell palette, by the id
                    
                    let name = paletteObj.stringValueForKey("title")
                    let uniqueId = paletteObj.numberValueForKey("id").stringValue
                    
                    var managedObject: NSManagedObject? = nil
                    var backingObj: NSManagedObject? = nil
                    var error: NSError? = nil
                    
                    context.performBlockAndWait({ () -> Void in
                        // determine the object id based on the uniqueId of the entity
                        let objectId = self.objectIDForEntity(entity, withResourceIdentifier: uniqueId)
                        if objectId != nil {
                            managedObject = context.existingObjectWithID(objectId!, error: &error)
                        }
                    })
                    
                    managedObject?.transform(paletteObj)
                    
                    var backingObjId = self.objectIDFromPrivateContextForEntity(entity, withResourceIdentifier: uniqueId)
                    backingContext.performBlockAndWait(){
                        if backingObjId != nil {
                            backingObj = backingContext.existingObjectWithID(backingObjId!, error: &error)
                        } else {
                            backingObj = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: backingContext) as? NSManagedObject
                            backingObj?.managedObjectContext?.obtainPermanentIDsForObjects([backingObj!], error: &error)
                        }
                    }
                    
                    // TODO: set last modified too
                    backingObj?.setValue(uniqueId, forKey: kPALResourceIdentifierAttributeName)
                    backingObj?.transform(paletteObj)
                    
                    if backingObjId != nil {
                        context.insertObject(managedObject!)
                    }
                    
                    mutableManagedObjects.addObject(managedObject!)
                    mutableBackingObjects.addObject(backingObj!)
                }
            }
        }

        completionHandler(managedObjects:mutableManagedObjects, backingObjects:mutableBackingObjects)
            
        return true
    }
    
    func objectIDForEntity(entity:NSEntityDescription, withResourceIdentifier resourceIdentifier:NSString?) -> NSManagedObjectID? {
        if resourceIdentifier == nil {
            return nil
        }
        
        var managedObjectId: NSManagedObjectID? = nil
        var objectIDsByResourceIdentifier: NSDictionary? = self.registeredObjectIDsMap.objectForKey(entity.name!) as? NSDictionary
        if objectIDsByResourceIdentifier != nil {
            managedObjectId = objectIDsByResourceIdentifier!.objectForKey(resourceIdentifier!) as? NSManagedObjectID
        }
        
        if managedObjectId == nil {
            var referenceObject = resourceIdentifier! as NSString
            referenceObject = "__pal__" + referenceObject
            managedObjectId = self.newObjectIDForEntity(entity, referenceObject: referenceObject)
        }
        
        return managedObjectId
    }
    
    func objectIDFromPrivateContextForEntity(entity:NSEntityDescription, withResourceIdentifier resourceIdentifier:NSString?) -> NSManagedObjectID? {
        if resourceIdentifier == nil {
            return nil
        }
        
        let objectId = self.objectIDForEntity(entity, withResourceIdentifier: resourceIdentifier)
        var backingObjectId: NSManagedObjectID? = backingObjectIDCache.objectForKey(objectId!) as? NSManagedObjectID
        if backingObjectId != nil {
            return backingObjectId
        }
        
        var fetchRequest = NSFetchRequest(entityName: entity.name!)
        fetchRequest.resultType = NSFetchRequestResultType.ManagedObjectIDResultType
        fetchRequest.fetchLimit = 1
        
        let predicate = NSPredicate(format: "%K = %@", kPALResourceIdentifierAttributeName, resourceIdentifier!)
        fetchRequest.predicate = predicate
        
        var error: NSError? = nil
        let privateContext = self.backingManagedObjectContext
        privateContext.performBlockAndWait(){
            if let results = privateContext.executeFetchRequest(fetchRequest, error: &error) {
                backingObjectId = results.last as? NSManagedObjectID
            }
        }
        
        if backingObjectId != nil {
            backingObjectIDCache.setObject(backingObjectId!, forKey: objectId!)
        }
        
        return backingObjectId
    }
}
