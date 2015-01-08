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
    private let cache = NSMutableDictionary()
    
    override class func initialize() {
        NSPersistentStoreCoordinator.registerStoreClass(self, forStoreType:self.storeType)
    }
    
    class var storeType: String {
        return NSStringFromClass(LocalIncrementalStore.self)
    }
    
    override func loadMetadata(error: NSErrorPointer) -> Bool {
        let uuid = NSProcessInfo.processInfo().globallyUniqueString
        self.metadata = [NSStoreTypeKey : LocalIncrementalStore.storeType, NSStoreUUIDKey : uuid]
        return true
    }
    
    override func executeRequest(request: NSPersistentStoreRequest, withContext context: NSManagedObjectContext, error: NSErrorPointer) -> AnyObject? {
        if request.requestType == .FetchRequestType {
            let fetchRequest = request as NSFetchRequest
            if fetchRequest.resultType == .ManagedObjectResultType {
                return self.entitiesForFetchRequest(fetchRequest, inContext: context)
            }
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
    
    /**
    Executes a fetch request within the context provided
    
    :param: request The request for the store.
    :param: context The context to execure the request within
    
    :returns: An array of managed objects
    */
    
    func entitiesForFetchRequest(request:NSFetchRequest, inContext context:NSManagedObjectContext) -> [AnyObject] {
        var entities: [Palette] = []
        let items = self.loadPalettesFromJSON()
        
        for item: AnyObject in items {
            if let dictionary = item as? NSDictionary {
                let objectId = self.objectIdForNewObjectOfEntity(request.entity!, cacheValues: item)
                if let palette = context.objectWithID(objectId) as? Palette {
                    palette.transform(dictionary: dictionary)
                    entities.append(palette)
                }
            }
        }
        
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
    Loads Palette data from a local JSON file
    
    :returns: Array of Palette objects in dictionary form.
    */
    
    func loadPalettesFromJSON() -> [AnyObject] {
        let filePath: String? = NSBundle.mainBundle().pathForResource("palettes", ofType: "json")
        var err: NSError?
        let data: NSData = NSData(contentsOfFile: filePath!)!
        let jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) as [AnyObject]
        
        if err != nil {
            println("error: \(err)")
        }
        
//        let palettes = jsonResult.filter({ (obj: AnyObject) -> Bool in
//            return (obj is NSDictionary)
//        }) as [NSDictionary]
        
        var palettes: [AnyObject] = []
        for obj in jsonResult {
            if let paletteObj = obj as? NSDictionary {
                palettes.append(paletteObj)
            }
        }
        
        return palettes
    }
}
