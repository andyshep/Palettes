//
//  LocalIncrementalStore.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/2/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import CoreData

@objc(LocalIncrementalStore)
final class LocalIncrementalStore: NSIncrementalStore {
    
    enum Error: Swift.Error {
        case objectIDMissing
        case cachedValuesMissing
        case entityNotFound
//        case wrongObjectType
        case wrongRequestType
//        case missingContext
        case invalidData
    }
    
    private typealias CachedObjectValues = [String: Any]
    
    /// The cache of attribute values and managed object ids
    private var cache: [NSManagedObjectID: CachedObjectValues] = [:]
    
    class var storeType: String {
        return String(describing: LocalIncrementalStore.self)
    }
    
    // MARK: NSIncrementalStore
    
    override func loadMetadata() throws {
        self.metadata = [
            NSStoreTypeKey: RemoteIncrementalStore.storeType,
            NSStoreUUIDKey: ProcessInfo.processInfo.globallyUniqueString
        ]
    }
    
    override func execute(_ request: NSPersistentStoreRequest,
                          with context: NSManagedObjectContext?) throws -> Any {
        guard
            let fetchRequest = request as? NSFetchRequest<NSManagedObject>,
            fetchRequest.resultType == .managedObjectResultType
        else { throw Error.wrongRequestType }
        
        return try entities(for: fetchRequest, with: context)
    }
    
    override func newValuesForObject(with objectID: NSManagedObjectID,
                                     with context: NSManagedObjectContext) throws -> NSIncrementalStoreNode {
        guard let values = cache[objectID] else { throw Error.cachedValuesMissing }
        return NSIncrementalStoreNode(objectID: objectID, withValues: values, version: 1)
    }
}

extension LocalIncrementalStore {
    
    private func entities(for request: NSFetchRequest<NSManagedObject>, with context: NSManagedObjectContext?) throws -> [AnyObject] {
        
        // Only Palette entity types are supported. If the model had more object types,
        // switch here on request.entity and handle accordingly.
        guard request.entity == Palette.entity() else { throw Error.wrongRequestType }
        
        return try loadPalettesFromJSON().map { item -> Palette in
            guard
                let entity = request.entity,
                let objectId = try? objectIdForNewObject(entityDescription: entity, cachedValues: item),
                let object = context?.object(with: objectId) as? Palette
            else { throw Error.entityNotFound }
            
            return object
        }
    }
        
    private func objectIdForNewObject(entityDescription: NSEntityDescription, cachedValues: CachedObjectValues) throws -> NSManagedObjectID {
        guard let referenceID = cachedValues["id"] as? Int else { throw Error.objectIDMissing }
        let objectId = newObjectID(for: entityDescription, referenceObject: referenceID)
        
        cache[objectId] = Palette.extractAttributeValues(from: cachedValues)
        
        return objectId
    }
    
    private func loadPalettesFromJSON() throws -> [CachedObjectValues] {
        guard
            let filePath = Bundle.main.path(forResource: "palettes", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: filePath))
        else { throw Error.invalidData }
        
        return try JSONSerialization.jsonObject(with: data) as? [CachedObjectValues] ?? []
    }
}
