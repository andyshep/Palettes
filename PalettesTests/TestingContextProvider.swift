//
//  TestingContextProvider.swift
//  Palettes
//
//  Created by Andrew Shepard on 1/12/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import CoreData
import XCTest

struct TestingContextProvider {
    
    static func contextWithStoreType(storeType: String) -> NSManagedObjectContext? {
        let modelURL = NSBundle.mainBundle().URLForResource("Palettes", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOfURL: modelURL)
        XCTAssertNotNil(model, "model should not be nil")
        
        // copy and modify the model so the unit test target can find entities.
        // http://stackoverflow.com/a/25858758
        
        let testModel = model!.copy() as! NSManagedObjectModel
        for entity in testModel.entities as! [NSEntityDescription] {
            if entity.name == Palette.entityName {
                entity.managedObjectClassName = "PalettesTests." + Palette.entityName
            }
        }
        
        XCTAssertNotNil(model, "test model should not be nil")
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: testModel)
        XCTAssertNotNil(psc, "psc should not be nil")
        
        var error: NSError? = nil
        if psc.addPersistentStoreWithType(storeType, configuration: nil, URL: nil, options: nil, error: &error) == nil {
        }
        
        XCTAssertNil(error, "error should be nil after adding persistent store")
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        XCTAssertNotNil(managedObjectContext, "context should not be nil")
        
        return managedObjectContext
    }
}
