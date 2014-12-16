//
//  BasicIncrementalStore.swift
//  Palettes
//
//  Created by Andrew Shepard on 6/14/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreData

@objc(BasicIncrementalStore)
class BasicIncrementalStore : NSIncrementalStore {
    private let cache = NSMutableDictionary()
    
    override func loadMetadata(error: NSErrorPointer) -> Bool {
        var uuid = NSProcessInfo.processInfo().globallyUniqueString
        self.metadata = [NSStoreTypeKey : "BasicIncrementalStore", NSStoreUUIDKey : uuid]
        return true
    }
    
    override func executeRequest(request: NSPersistentStoreRequest, withContext context: NSManagedObjectContext, error: NSErrorPointer) -> AnyObject? {
        if request.requestType == .FetchRequestType {
            var fetchRequest = request as NSFetchRequest
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

    func entitiesForFetchRequest(request:NSFetchRequest, inContext context:NSManagedObjectContext) -> NSArray! {
        var entities: [Palette] = []
        let items = DataController.loadPalettesFromJSON()
        
        for item: AnyObject in items {
            if let dictionary = item as? NSDictionary {
                var objectId = self.objectIdForNewObjectOfEntity(request.entity!, cacheValues: item)
                if let palette = context.objectWithID(objectId) as? Palette {
                    palette.transform(dictionary)
                    entities.append(palette)
                }
            }
        }
        
        return NSArray(array:entities)
    }

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
}
