//
//  LocalIncrementalStore.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/2/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import CoreData

@objc(LocalIncrementalStore)
class LocalIncrementalStore : NSIncrementalStore {
    
    // The cache of attribute values and managed object ids
    private let cache = NSMutableDictionary()
    
    class var storeType: String {
        return NSStringFromClass(LocalIncrementalStore.self)
    }
    
    override class func initialize() {
        NSPersistentStoreCoordinator.registerStoreClass(self, forStoreType:self.storeType)
    }
    
    // MARK: - NSIncrementalStore
    
    override func loadMetadata() throws {
        let uuid = NSProcessInfo.processInfo().globallyUniqueString
        self.metadata = [NSStoreTypeKey : LocalIncrementalStore.storeType, NSStoreUUIDKey : uuid]
    }
    
    override func executeRequest(request: NSPersistentStoreRequest, withContext context: NSManagedObjectContext?) throws -> AnyObject {
        guard let context = context else {
            fatalError("context is missing")
        }
        
        if request.requestType == .FetchRequestType {
            let fetchRequest = request as! NSFetchRequest
            if fetchRequest.resultType == .ManagedObjectResultType {
                return self.entitiesForFetchRequest(fetchRequest, inContext: context)
            }
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
    Executes a fetch request within the context provided
    
    :param: request The request for the store.
    :param: context The context to execure the request within
    
    :returns: An array of managed objects
    */
    
    func entitiesForFetchRequest(request:NSFetchRequest, inContext context:NSManagedObjectContext) -> [AnyObject] {
        let items = self.loadPalettesFromJSON()
        
        let entities = items.map({ (item: NSDictionary) -> Palette in
            let objectId = self.objectIdForNewObjectOfEntity(request.entity!, cacheValues: item)
            let palette = context.objectWithID(objectId) as! Palette
            return palette
        })
        
        return entities
    }
    
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
    Loads Palette data from a local JSON file
    
    :returns: Array of Palette objects in dictionary form.
    */
    
    func loadPalettesFromJSON() -> [NSDictionary] {
        let filePath: String? = NSBundle.mainBundle().pathForResource("palettes", ofType: "json")
        let data: NSData = NSData(contentsOfFile: filePath!)!
        
        do {
            guard let result = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [AnyObject] else {
                return [[:]]
            }
            
            let palettes = result.filter({ (obj: AnyObject) -> Bool in
                return (obj is NSDictionary)
            }) as! [NSDictionary]
            
            return palettes
        }
        catch {
            print("error fetching palettes: \(error)")
            return [[:]]
        }
    }
}
