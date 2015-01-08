//
//  CoreDataManager.swift
//  Ascent
//
//  Created by Andrew Shepard on 12/10/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import CoreData

class CoreDataManager: NSObject {
    
    // MARK: - Lifecycle
    
    class var sharedManager: CoreDataManager {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: CoreDataManager? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = CoreDataManager()
        }
        return Static.instance!
    }
    
    override init() {
        super.init()
    }
    
    // MARK: - Core Data stack
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return managedObjectContext
    }()
    
    // MARK: - Public
    
    func fetchedResultsControllerForEntityName(name:String, sortDescriptors:Array<NSSortDescriptor>, predicate:NSPredicate! = nil) -> NSFetchedResultsController {
        let managedObjectContext = self.managedObjectContext
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: managedObjectContext!)
        
        fetchRequest.entity = entity
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        
        var error: NSError? = nil
        if !fetchedResultsController.performFetch(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            println("Unresolved error: \(error)")
            abort()
        }
        
        return fetchedResultsController;
    }
    
    // MARK: - Private
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
//        let storeType = LocalIncrementalStore.storeType
        let storeType = RemoteIncrementalStore.storeType
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = NSURL.applicationDocumentsDirectory().URLByAppendingPathComponent("Palettes.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
        let options = [NSMigratePersistentStoresAutomaticallyOption: NSNumber(bool: true), NSInferMappingModelAutomaticallyOption: NSNumber(bool: true)];
        
        if coordinator!.addPersistentStoreWithType(storeType, configuration: nil, URL: url, options: options, error: &error) == nil {
            coordinator = nil
            if let code = error?.code {
                if code == NSMigrationMissingMappingModelError {
                    println("Error, migration failed. Delete model at \(url)")
                }
                else {
                    println("Error creating persistent store: \(error?.description)")
                }
            }
            abort()
        }
        
        return coordinator
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("Palettes", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
}
