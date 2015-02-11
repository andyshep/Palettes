//
//  LocalIncrementalStoreTests.swift
//  PalettesTests
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import XCTest
import CoreData
import Foundation

class LocalIncrementalStoreTests: XCTestCase {
    
    var managedObjectContext: NSManagedObjectContext?
    
    override func setUp() {
        super.setUp()
        
        let storeType = LocalIncrementalStore.storeType
        self.managedObjectContext = TestingContextProvider.contextWithStoreType(storeType)
        
        XCTAssertNotNil(managedObjectContext, "context should not be nil")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testLocalObjectsCanBeFetched() {
        let request = NSFetchRequest(entityName: "Palette")
        request.fetchLimit = 30
        request.sortDescriptors = Palette.defaultSortDescriptors
        
        var error: NSError?
        let results = managedObjectContext?.executeFetchRequest(request, error: &error) as! [Palette]
        
        XCTAssertGreaterThan(results.count, 0, "results should be greater than zero")
    }
    
}
