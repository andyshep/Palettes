//
//  CoreDataManager.swift
//  Ascent
//
//  Created by Andrew Shepard on 12/10/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import CoreData

final class CoreDataManager {
    
    // MARK: Lifecycle
    
    static let sharedManager = CoreDataManager()
    
    init() {
        NSPersistentStoreCoordinator.registerStoreClass(
            CachingIncrementalStore.self,
            forStoreType: CachingIncrementalStore.storeType
        )
    }
    
    // MARK: Core Data stack
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        persistentStoreContainer.viewContext
    }()
    
    lazy var persistentStoreContainer: NSPersistentContainer = {
        var persistentStoreContainer = NSPersistentContainer(name: "Container", managedObjectModel: managedObjectModel)
        
        let url = URL.applicationDocumentsDirectory().appendingPathComponent("Palettes.sqlite")
        var description = NSPersistentStoreDescription(url: url)
        description.type = CachingIncrementalStore.storeType
        
        persistentStoreContainer.persistentStoreDescriptions = [
            description
        ]
        
        return persistentStoreContainer
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "Palettes", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
}

extension NSPersistentContainer {
    func loadPersistentStores() async throws -> NSPersistentStoreDescription {
        try await withCheckedThrowingContinuation { continuation in
            loadPersistentStores { description, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(with: .success(description))
                }
            }
        }
    }
}
