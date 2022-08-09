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
    }
    
    private typealias CachedObjectValues = [String: Any]
    
    /// The cache of managed object ids
    private var cache: [NSManagedObjectID: CachedObjectValues] = [:]
    
    class var storeType: String {
        return String(describing: RemoteIncrementalStore.self)
    }
    
    // MARK: - NSIncrementalStore
    
    override func loadMetadata() throws {
        self.metadata = [
            NSStoreTypeKey: RemoteIncrementalStore.storeType,
            NSStoreUUIDKey: ProcessInfo.processInfo.globallyUniqueString
        ]
    }
    
    override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> Any {
        guard request.requestType == .fetchRequestType else { throw Error.wrongRequestType }
        return try executeFetchRequest(request, context: context) as Any
    }
    
    override func newValuesForObject(with objectID: NSManagedObjectID, with context: NSManagedObjectContext) throws -> NSIncrementalStoreNode {
        guard let values = cache[objectID] else { throw Error.cachedValuesMissing }
        return NSIncrementalStoreNode(objectID: objectID, withValues: values, version: 1)
    }
    
    // MARK: - Private
    
    /**
    Returns a new object id for the entity, and caches the values provided.
    
    :param: entityDescription
    :param: values
    
    :returns: A managed object ID
    */

    private func objectIdForNewObject(entityDescription: NSEntityDescription, cacheValues: CachedObjectValues) -> NSManagedObjectID? {
        guard let referenceID = cacheValues["id"] as? Int else { return nil }
        
        let objectId = newObjectID(for: entityDescription, referenceObject: referenceID)
        let extracted = Palette.extractAttributeValues(from: cacheValues)
        
        cache[objectId] = extracted
        
        return objectId
    }
    
    /**
    Executes a fetch request within the context provided
    
    :param: request The request for the store.
    :param: context The context to execure the request within
    
    :returns: An optional array of managed objects
    */
    
    private func executeFetchRequest(_ request: NSPersistentStoreRequest, context: NSManagedObjectContext?) throws -> [AnyObject] {
        guard let fetchRequest = request as? NSFetchRequest<NSManagedObject> else { return []  }
        return try fetchRemoteObjects(request: fetchRequest, context: context)
    }
    
    /**
    Fetches the remote objects associated with a request
    
    :param: fetchRequest The request for the store.
    :param: context The context to execure the request within
    
    :returns: An array of managed objects
    */
    
    private func fetchRemoteObjects(request: NSFetchRequest<NSManagedObject>, context: NSManagedObjectContext?) throws -> [AnyObject] {
        let offset = request.fetchOffset
        let limit = request.fetchLimit
        let httpRequest = ColourLovers.topPalettes.request(offset: offset, limit: limit)
        let session = URLSession(configuration: URLSessionConfiguration.default)        
        
        guard let entity = request.entity else { return [] }
        
        guard
            let data = try session.sendSynchronousDataTask(request: httpRequest)
        else { throw Error.invalidResponse }
        
        guard
            let results = try JSONSerialization.jsonObject(with: data, options: []) as? [CachedObjectValues]
        else { throw Error.invalidJSON }
        
        let entities = try results.map { item -> Palette in
            
            guard let objectId = objectIdForNewObject(entityDescription: entity, cacheValues: item) else {
                throw Error.objectIDMissing
            }
            guard let palette = context?.object(with: objectId) as? Palette else {
                throw Error.wrongObjectType
            }
            return palette
        }
        
        return entities
    }
}

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
