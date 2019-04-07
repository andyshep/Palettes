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
        return String(describing: RemoteIncrementalStore.self)
    }
    
    // MARK: - NSIncrementalStore
    
    override func loadMetadata() throws {
        let uuid = ProcessInfo.processInfo.globallyUniqueString
        self.metadata = [NSStoreTypeKey : RemoteIncrementalStore.storeType, NSStoreUUIDKey : uuid]
    }
    
    override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> Any {
        if request.requestType == .fetchRequestType {
            var error: NSError? = nil
            return self.executeFetchRequest(request, withContext: context, error: &error) as Any
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
    Executes a fetch request within the context provided
    
    :param: request The request for the store.
    :param: context The context to execure the request within
    :param: error If an error occurs, on return contains an `NSError` object that describes the problem.
    
    :returns: An optional array of managed objects
    */
    
    func executeFetchRequest(_ request: NSPersistentStoreRequest!, withContext context: NSManagedObjectContext!, error: NSErrorPointer) -> [AnyObject]! {
        let fetchRequest = request as! NSFetchRequest<NSManagedObject>
        
        if fetchRequest.resultType == NSFetchRequestResultType() {
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
    
    func fetchRemoteObjectsWithRequest(_ fetchRequest: NSFetchRequest<NSManagedObject>, context: NSManagedObjectContext) -> [AnyObject] {
        let offset = fetchRequest.fetchOffset
        let limit = fetchRequest.fetchLimit
        let httpRequest = ColourLovers.topPalettes.request(offset, limit: limit)
        
        var response: URLResponse? = nil
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        do {
            let data = try session.sendSynchronousDataTaskWithRequest(httpRequest, response: &response)
            guard let results = try JSONSerialization.jsonObject(with: data!, options: []) as? [NSDictionary] else {
                print("json could not be parsed")
                return []
            }
            
            let entities = results.map({ (item: NSDictionary) -> Palette in
                guard let objectId = self.objectIdForNewObjectOfEntity(fetchRequest.entity!, cacheValues: item) else {
                    fatalError("missing object id")
                }
                guard let palette = context.object(with: objectId) as? Palette else {
                    fatalError("wrong object type")
                }
                return palette
            })
            
            return entities
        }
        catch {
            return []
        }
    }
}

extension URLSession {
    func sendSynchronousDataTaskWithRequest(_ request: URLRequest, response: inout URLResponse?) throws -> Data? {
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
