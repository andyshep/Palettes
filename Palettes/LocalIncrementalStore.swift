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
        return String(describing: LocalIncrementalStore.self)
    }
    
    // MARK: - NSIncrementalStore
    
    override func loadMetadata() throws {
        let uuid = ProcessInfo.processInfo.globallyUniqueString
        self.metadata = [NSStoreTypeKey : LocalIncrementalStore.storeType, NSStoreUUIDKey : uuid]
    }
    
    override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> Any {
        guard context != nil else { fatalError("missing context") }
        
        if request.requestType == .fetchRequestType {
            let fetchRequest = request as! NSFetchRequest<NSManagedObject>
            if fetchRequest.resultType == NSFetchRequestResultType() {
                return self.entitiesForFetchRequest(fetchRequest, inContext: context!)
            }
        }
        
        return []
    }
    
    override func newValuesForObject(with objectID: NSManagedObjectID, with context: NSManagedObjectContext) throws -> NSIncrementalStoreNode {
        guard let values = cache.object(forKey: objectID) as? [String: AnyObject] else {
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
    
    func entitiesForFetchRequest(_ request:NSFetchRequest<NSManagedObject>, inContext context:NSManagedObjectContext) -> [AnyObject] {
        let items = self.loadPalettesFromJSON()
        
        let entities = items.map({ (item: NSDictionary) -> Palette in
            guard let entity = request.entity else { fatalError("missing entity") }
            guard let objectId = self.objectIdForNewObjectOfEntity(entity, cacheValues: item) else {
                fatalError("missing object id")
            }
            guard let palette = context.object(with: objectId) as? Palette else {
                fatalError("wrong object found")
            }
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

    func objectIdForNewObjectOfEntity(_ entityDescription:NSEntityDescription, cacheValues values:AnyObject!) -> NSManagedObjectID! {
        if let dict = values as? NSDictionary {
            let _ = entityDescription.name
            
            let referenceId = dict.numberValueForKey("id").stringValue
            guard referenceId != "" else { return nil }
            
            let objectId = self.newObjectID(for: entityDescription, referenceObject: referenceId)
            let values = Palette.extractAttributeValues(dict)
            cache.setObject(values, forKey: objectId)
            return objectId
        }
        
        return nil
    }
    
    /**
    Loads Palette data from a local JSON file
    
    :returns: Array of Palette objects in dictionary form.
    */
    
    func loadPalettesFromJSON() -> [NSDictionary] {
        let filePath: String? = Bundle.main.path(forResource: "palettes", ofType: "json")
        let data: Data = try! Data(contentsOf: URL(fileURLWithPath: filePath!))
        
        do {
            let results = try JSONSerialization.jsonObject(with: data, options: [])
            guard let palettes = results as? [NSDictionary] else {
                return [[:]]
            }
            
            return palettes
        }
        catch {
            print("error fetching palettes: \(error)")
            return [[:]]
        }
    }
}
