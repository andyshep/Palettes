//
//  TestingContextProvider.swift
//  Palettes
//
//  Created by Andrew Shepard on 1/12/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import CoreData
import XCTest
@testable import Palettes

struct TestingContextProvider {
    
    static func contextWithStoreType(_ storeType: String) -> NSManagedObjectContext? {
        let modelURL = Bundle.main.url(forResource: "Palettes", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)
        XCTAssertNotNil(model, "model should not be nil")
        
        // copy and modify the model so the unit test target can find entities.
        // http://stackoverflow.com/a/25858758
        
        let testModel = model!.copy() as! NSManagedObjectModel
        for entity in testModel.entities {
            if entity.name == Palette.entityName {
                entity.managedObjectClassName = "PalettesTests." + Palette.entityName
            }
        }
        
        XCTAssertNotNil(model, "test model should not be nil")
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: testModel)
        XCTAssertNotNil(psc, "psc should not be nil")
        
        do {
            try psc.addPersistentStore(ofType: storeType, configurationName: nil, at: nil, options: nil)
        }
        catch {
           XCTFail("could not add persistent store")
        }
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        XCTAssertNotNil(managedObjectContext, "context should not be nil")
        
        return managedObjectContext
    }
}
