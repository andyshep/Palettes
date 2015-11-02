//
//  RemoteIncrementalStore.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/7/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import CoreData

@objc(RemoteIncrementalStore)
class RemoteIncrementalStore : NSIncrementalStore {
    
    /// The cache of managed object ids
    private let cache = NSMutableDictionary()
    
    class var storeType: String {
        return NSStringFromClass(RemoteIncrementalStore.self)
    }
    
    override class func initialize() {
        NSPersistentStoreCoordinator.registerStoreClass(self, forStoreType:self.storeType)
    }
    
    // MARK: - NSIncrementalStore
    
    override func loadMetadata() throws {
        let uuid = NSProcessInfo.processInfo().globallyUniqueString
        self.metadata = [NSStoreTypeKey : RemoteIncrementalStore.storeType, NSStoreUUIDKey : uuid]
    }
    
    override func executeRequest(request: NSPersistentStoreRequest, withContext context: NSManagedObjectContext?) throws -> AnyObject {
        if request.requestType == .FetchRequestType {
            var error: NSError? = nil
            return self.executeFetchRequest(request, withContext: context, error: &error)
        }
        
        return []
    }
    
    override func newValuesForObjectWithID(objectID: NSManagedObjectID, withContext context: NSManagedObjectContext) throws -> NSIncrementalStoreNode {
        guard let values = cache.objectForKey(objectID) as? [String: AnyObject] else {
            fatalError("values are missing")
        }
        
        return NSIncrementalStoreNode(objectID: objectID, withValues: values, version: 1)
    }
    
    // MARK: - Private
    
    /**
    Returns a new object id for the entity, and caches the values provided.
    
    :param: entityDescription
    :param: values
    
    :returns: A managed object ID
    */

    func objectIdForNewObjectOfEntity(entityDescription:NSEntityDescription, cacheValues values:AnyObject!) -> NSManagedObjectID! {
        if let dict = values as? NSDictionary {
            let _ = entityDescription.name
            
            if let referenceId = dict.objectForKey("id")?.stringValue {
                let objectId = self.newObjectIDForEntity(entityDescription, referenceObject: referenceId)
                let values = Palette.extractAttributeValues(dict)
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
        let fetchRequest = request as! NSFetchRequest
        
        if fetchRequest.resultType == .ManagedObjectResultType {
            let managedObjects = self.fetchRemoteObjectsWithRequest(fetchRequest, context: context)
            return managedObjects
        }
        else {
            return nil
        }
    }
    
    /**
    Fetches the remote objects associated with a request
    
    :param: fetchRequest The request for the store.
    :param: context The context to execure the request within
    
    :returns: An array of managed objects
    */
    
    func fetchRemoteObjectsWithRequest(fetchRequest: NSFetchRequest, context: NSManagedObjectContext) -> [AnyObject] {
        let offset = fetchRequest.fetchOffset
        let limit = fetchRequest.fetchLimit
        let httpRequest = ColourLovers.TopPalettes.request(offset, limit: limit)
        
        var response: NSURLResponse? = nil
        let data = try! NSURLConnection.sendSynchronousRequest(httpRequest, returningResponse: &response)
        
        let jsonResult = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as! [AnyObject]
        let paletteObjs = jsonResult.filter({ (obj: AnyObject) -> Bool in
            return (obj is NSDictionary)
        }) as! [NSDictionary]
        
        let entities = paletteObjs.map({ (item: NSDictionary) -> Palette in
            let objectId = self.objectIdForNewObjectOfEntity(fetchRequest.entity!, cacheValues: item)
            let palette = context.objectWithID(objectId) as! Palette
            return palette
        })
        
        return entities
    }
}
