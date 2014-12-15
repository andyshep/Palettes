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
        let values = cache.objectForKey(objectID) as NSDictionary
        var node = NSIncrementalStoreNode(objectID: objectID, withValues: values, version: 1)
        return node
    }

    func entitiesForFetchRequest(request:NSFetchRequest, inContext context:NSManagedObjectContext) -> NSArray! {
        var entities = NSMutableArray()
        let items = DataController.loadPalettesFromJSON()
        
        for item: AnyObject in items {
            if let dictionary = item as? NSDictionary {
                var objectId = self.objectIdForNewObjectOfEntity(request.entity!, cacheValues: item)
                var obj = context.objectWithID(objectId)
                
                obj.transform(dictionary)
                
                entities.addObject(obj)
            }
        }
        
        return NSArray(array:entities)
    }

    func objectIdForNewObjectOfEntity(entityDescription:NSEntityDescription, cacheValues values:AnyObject!) -> NSManagedObjectID! {
        if let dict = values as? NSDictionary {
            let nativeKey = entityDescription.name
            let referenceId: AnyObject! = dict.objectForKey("id")?.stringValue
            let objectId = self.newObjectIDForEntity(entityDescription, referenceObject: referenceId)
            
            cache.setObject(values, forKey: objectId)
            
            return objectId
        }
        else {
            return nil
        }
    }
}
