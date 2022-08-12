//
//  CachingIncrementalStore.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/7/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import CoreData

@objc(CachingIncrementalStore)

/// An Incremental Store subclass for retrieving Palettes from the Colour Lovers API
class CachingIncrementalStore : NSIncrementalStore {
    
    enum Error: Swift.Error {
        case objectIDMissing
//        case cachedValuesMissing
        case entityNotFound
        case wrongObjectType
        case wrongReferenceObjectType
        case wrongRequestType
        case missingContext
        case invalidData
        case cannotCopyRequest
    }
    
    private enum Attributes {
        static let resourceIdentifier = "__pal__resourceIdentifier"
        static let lastModified = "__pal__lastModified"
    }
    
    /// The cache of managed object ids for the backing store
    private let backingObjectIDCache = NSCache<NSManagedObjectID, NSManagedObjectID>()
    
    class var storeType: String {
        return String(describing: CachingIncrementalStore.self)
    }
    
    // MARK: Lazy Accessors
    
    /// The persistent store coordinator attached to the backing store.
    lazy var backingPersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: augmentedModel)
        
        do {
            try coordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: URL.applicationDocumentsDirectory()
                    .appendingPathComponent(
                        CachingIncrementalStore.storeType + ".sqlite"
                    ),
                options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true
                ]
            )
        } catch {
            abort()
        }
        
        return coordinator
    }()
    
    /// The managed object context for the backing store
    lazy var backingManagedObjectContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = backingPersistentStoreCoordinator
        context.retainsRegisteredObjects = true
        
        return context
    }()
    
    /// The model for the backing store, augmented with custom attributes
    lazy var augmentedModel: NSManagedObjectModel = {
        guard
            let originalModel = persistentStoreCoordinator?.managedObjectModel,
            let augmentedModel = originalModel.copy() as? NSManagedObjectModel
        else { abort() }
        
        for entity in augmentedModel.entities {
            guard entity.superentity == nil else { continue }
            
            let resourceIdProperty = NSAttributeDescription()
            resourceIdProperty.name = Attributes.resourceIdentifier
            resourceIdProperty.attributeType = .stringAttributeType
//            resourceIdProperty.isIndexed = true
            
            let lastModifiedProperty = NSAttributeDescription()
            lastModifiedProperty.name = Attributes.lastModified
            lastModifiedProperty.attributeType = .dateAttributeType
//            lastModifiedProperty.isIndexed = false
            
            var properties = entity.properties
            properties.append(resourceIdProperty)
            properties.append(lastModifiedProperty)
            
            entity.properties = properties
        }
        
        return augmentedModel
    }()
    
    // MARK: - NSIncrementalStore
    
    override func loadMetadata() throws {
        self.metadata = [
            NSStoreTypeKey: CachingIncrementalStore.storeType,
            NSStoreUUIDKey: ProcessInfo.processInfo.globallyUniqueString
        ]
    }
    
    override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> Any {
        guard request.requestType == .fetchRequestType else { throw Error.wrongRequestType }
        return try executeFetchRequest(request, with: context)
    }

    override func newValuesForObject(with objectID: NSManagedObjectID, with context: NSManagedObjectContext) throws -> NSIncrementalStoreNode {
        guard let referenceObj = referenceObject(for: objectID) as? NSString else {
            throw Error.wrongReferenceObjectType
        }
        
        guard let entityName = objectID.entity.name else { throw Error.entityNotFound }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        fetchRequest.predicate = NSPredicate(
            format: "%K = %@", Attributes.resourceIdentifier, referenceObj.description
        )
        
        let results: [AnyObject] = try backingManagedObjectContext.performAndWait {
            try backingManagedObjectContext.fetch(fetchRequest)
        }
        
        let values = results.last as? [String: AnyObject] ?? [:]
        return NSIncrementalStoreNode(objectID: objectID, withValues: values, version: 1)
    }
}

// MARK: - Private

extension CachingIncrementalStore {
    private func executeFetchRequest(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> [AnyObject] {
        guard
            let fetchRequest = request as? NSFetchRequest<NSFetchRequestResult>,
            fetchRequest.resultType == .managedObjectResultType
        else { throw Error.wrongRequestType }
        
        guard
            let entity = fetchRequest.entity,
            let entityName = fetchRequest.entityName
        else { throw Error.entityNotFound }
        
        guard let context = context else { throw Error.missingContext }
        
        Task {
            try await fetchRemoteObjects(matching: fetchRequest, with: context)
        }
        
        let cacheFetchRequest = fetchRequest
        cacheFetchRequest.entity = NSEntityDescription.entity(
            forEntityName: entityName,
            in: backingManagedObjectContext
        )
        cacheFetchRequest.resultType = .managedObjectResultType
        cacheFetchRequest.propertiesToFetch = [Attributes.resourceIdentifier]
        
        let results: [AnyObject] = try backingManagedObjectContext.performAndWait {
            try backingManagedObjectContext.fetch(cacheFetchRequest)
        }
        
        return try results
            .compactMap { $0.value(forKeyPath: Attributes.resourceIdentifier) as? String }
            .compactMap { resourceId -> NSManagedObject? in
                guard
                    let objectId = objectID(for: entity, resourceIdentifier: resourceId)
                else { throw Error.objectIDMissing }
                
                let predicate = NSPredicate(format: "%K = %@", Attributes.resourceIdentifier, resourceId)
                
                guard
                    let managedObject = context.object(with: objectId) as? Palette,
                    let backingObject = (results as NSArray).filtered(using: predicate).first as? Palette
                else { throw Error.wrongObjectType }

                managedObject.transform(using: backingObject)

                return managedObject
            }
    }
    
    private func insertOrUpdateObjects(_ objects: [AnyObject], ofEntity entity: NSEntityDescription, with context: NSManagedObjectContext) throws {
        for object in objects {
            guard let paletteObj = object as? NSDictionary else { continue }
            
            let uniqueId = paletteObj.numberValueForKey("id").stringValue
            
            let backingObjectId = try objectIDFromBackingContext(for: entity, resourceIdentifier: uniqueId)
            let backingObject = try existingOrNewObject(for: entity, objectID: backingObjectId, context: backingManagedObjectContext)
            
            if let backingPaletteObject = backingObject as? Palette {
                backingPaletteObject.setValue(uniqueId, forKey: Attributes.resourceIdentifier)
                backingPaletteObject.transform(using: paletteObj)
            }
            
            let managedObject = try context.performAndWait { () -> NSManagedObject in
                guard
                    let objectID = objectID(for: entity, resourceIdentifier: uniqueId)
                else { throw Error.objectIDMissing }
                
                return try context.existingObject(with: objectID)
            }
            
            if let managedPaletteObject = managedObject as? Palette {
                managedPaletteObject.transform(using: paletteObj)
            }
            
            context.insert(managedObject)
        }
    }
    
    private func existingOrNewObject(for entity: NSEntityDescription, objectID: NSManagedObjectID?, context: NSManagedObjectContext) throws -> NSManagedObject {
        guard let entityName = entity.name else { throw Error.entityNotFound }
        
        return try context.performAndWait { () -> NSManagedObject in
            if let objectId = objectID {
                return try context.existingObject(with: objectId)
            } else {
                let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
                try object.managedObjectContext?.obtainPermanentIDs(for: [object])
                return object
            }
        }
    }
    
    private func objectID(for entity: NSEntityDescription, resourceIdentifier identifier: String) -> NSManagedObjectID? {
        
        var managedObjectId: NSManagedObjectID? = nil
        
        // FIXME: nothing ever inserted here
//        if let objectIDsByResourceIdentifier = self.registeredObjectIDsMap.object(forKey: entity.name!) as? NSDictionary {
//            managedObjectId = objectIDsByResourceIdentifier.object(forKey: identifier) as? NSManagedObjectID
//        }
        
        if managedObjectId == nil {
            let referenceObject = "__pal__" + String(identifier)
            managedObjectId = newObjectID(for: entity, referenceObject: referenceObject)
        }
        
        return managedObjectId
    }
    
    private func objectIDFromBackingContext(for entity: NSEntityDescription, resourceIdentifier identifier: String) throws -> NSManagedObjectID {
        guard
            let objectId = objectID(for: entity, resourceIdentifier: identifier)
        else { throw Error.objectIDMissing }
        
        if let backingObjectId = backingObjectIDCache.object(forKey: objectId) {
            return backingObjectId
        }
        
        guard let entityName = entity.name else { throw Error.entityNotFound }
        
        let fetchRequest = NSFetchRequest<NSManagedObjectID>(entityName: entityName)
        fetchRequest.resultType = .managedObjectIDResultType
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K = %@", Attributes.resourceIdentifier, identifier)
        
        return try backingManagedObjectContext.performAndWait { () -> NSManagedObjectID in
            guard let object = try backingManagedObjectContext.fetch(fetchRequest).last else {
                throw Error.objectIDMissing
            }
            
            backingObjectIDCache.setObject(object, forKey: objectId)
            return object
        }
    }
    
    private func fetchRemoteObjects(matching fetchRequest: NSFetchRequest<NSFetchRequestResult>, with context: NSManagedObjectContext) async throws -> Void {
        guard let entity = fetchRequest.entity else { throw Error.entityNotFound }
        
        let offset = fetchRequest.fetchOffset
        let limit = fetchRequest.fetchLimit
        let httpRequest = ColourLovers.topPalettes.request(offset: offset, limit: limit)

        let (data, _) = try await URLSession.shared.data(for: httpRequest)
        guard
            let palettes = try JSONSerialization.jsonObject(with: data, options: []) as? [NSDictionary]
        else { throw Error.invalidData }

        let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        childContext.parent = context

        try await childContext.perform {
            try self.insertOrUpdateObjects(palettes, ofEntity: entity, with: childContext)
            try childContext.save()
            
            try self.backingManagedObjectContext.save()
            
            context.perform {
                childContext.registeredObjects.forEach { object in
                    let parentObject = context.object(with: object.objectID)
                    context.refresh(parentObject, mergeChanges: true)
                }
            }
        }
    }
}

// https://oleb.net/blog/2018/02/performandwait/

extension NSManagedObjectContext {
    func performAndWait<T>(_ block: () throws -> T) throws -> T {
        var result: Result<T, Error>?
        performAndWait {
            result = Result { try block() }
        }
        return try result!.get()
    }

    func performAndWait<T>(_ block: () -> T) -> T {
        var result: T?
        performAndWait {
            result = block()
        }
        return result!
    }
}

extension Array where Element == AnyObject {
    func filtered(using predicate: NSPredicate) -> [Any] {
        return (self as NSArray).filtered(using: predicate)
    }
}
