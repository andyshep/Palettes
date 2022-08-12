//
//  RemoteIncrementalStore.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/7/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import CoreData

@objc(RemoteIncrementalStore)
final class RemoteIncrementalStore: NSIncrementalStore {
    
    enum Error: Swift.Error {
        case objectIDMissing
        case cachedValuesMissing
        case wrongObjectType
        case wrongRequestType
        case invalidResponse
        case invalidJSON
        case entityNotFound
        case missingContext
    }
    
    private typealias CachedObjectValues = [String: Any]
    
    /// The cache of managed object ids
    private var cache: [NSManagedObjectID: CachedObjectValues] = [:]
    
    class var storeType: String {
        return String(describing: RemoteIncrementalStore.self)
    }
    
    // MARK: NSIncrementalStore overrides
    
    override func loadMetadata() throws {
        self.metadata = [
            NSStoreTypeKey: RemoteIncrementalStore.storeType,
            NSStoreUUIDKey: ProcessInfo.processInfo.globallyUniqueString
        ]
    }
    
    override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> Any {
        guard request.requestType == .fetchRequestType else { throw Error.wrongRequestType }
        return try executeFetchRequest(request, with: context)
    }
    
    override func newValuesForObject(with objectID: NSManagedObjectID, with context: NSManagedObjectContext) throws -> NSIncrementalStoreNode {
        guard let values = cache[objectID] else { throw Error.cachedValuesMissing }
        return NSIncrementalStoreNode(objectID: objectID, withValues: values, version: 1)
    }
}

extension RemoteIncrementalStore {
    private func objectIdForNewObject(entityDescription: NSEntityDescription, cacheValues: CachedObjectValues) -> NSManagedObjectID? {
        guard let referenceID = cacheValues["id"] as? Int else { return nil }
        
        let objectId = newObjectID(for: entityDescription, referenceObject: referenceID)
        let extracted = Palette.extractAttributeValues(from: cacheValues)
        
        cache[objectId] = extracted
        
        return objectId
    }
    
    private func executeFetchRequest(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> Any {
        guard let fetchRequest = request as? NSFetchRequest<NSManagedObject> else { throw Error.wrongRequestType  }
        guard let context = context else { throw Error.missingContext }
        return try fetchRemoteObjects(matching: fetchRequest, with: context)
    }
    
    private func fetchRemoteObjects(matching request: NSFetchRequest<NSManagedObject>, with context: NSManagedObjectContext) throws -> [AnyObject] {
        let offset = request.fetchOffset
        let limit = request.fetchLimit
        let httpRequest = ColourLovers.topPalettes.request(offset: offset, limit: limit)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        guard let entity = request.entity else { throw Error.entityNotFound }
        
        return try context.performAndWait { () throws -> [Palette] in
            guard
                let data = try session.sendSynchronousDataTask(request: httpRequest)
            else { throw Error.invalidResponse }
            
            guard
                let results = try JSONSerialization.jsonObject(with: data, options: []) as? [CachedObjectValues]
            else { throw Error.invalidJSON }
            
            return try results.map { item -> Palette in
                guard let objectId = objectIdForNewObject(entityDescription: entity, cacheValues: item) else {
                    throw Error.objectIDMissing
                }
                guard let palette = context.object(with: objectId) as? Palette else {
                    throw Error.wrongObjectType
                }
                return palette
            }
        }
    }
}

// FIXME: refactor this away
extension URLSession {
    func sendSynchronousDataTask(request: URLRequest) throws -> Data? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Data? = nil
        var error: Error? = nil
        
        let task = self.dataTask(with: request) { (data, response, err) -> Void in
            result = data
            error = err
            semaphore.signal()
        }
        
        task.resume()
        
        let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        if let error = error {
            throw error
        }
        
        return result
    }
}
