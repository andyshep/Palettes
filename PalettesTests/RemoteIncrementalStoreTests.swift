//
//  RemoteIncrementalStoreTests.swift
//  Palettes
//
//  Created by Andrew Shepard on 1/12/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import XCTest
import CoreData

class RemoteIncrementalStoreTests: XCTestCase {
    var managedObjectContext: NSManagedObjectContext?
    
    override func setUp() {
        super.setUp()
        
        let storeType = RemoteIncrementalStore.storeType
        self.managedObjectContext = TestingContextProvider.contextWithStoreType(storeType)
        
        XCTAssertNotNil(managedObjectContext, "context should not be nil")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testRemoteObjectsCanBeFetched() {
        let request = self.fetchRequest()
        
        var error: NSError?
        let results = managedObjectContext?.executeFetchRequest(request, error: &error) as! [Palette]
        
        XCTAssertGreaterThan(results.count, 0, "results should be greater than zero")
    }
    
    func testRemoteObjectsCanBeFetchedAsynchronously() {
        let expectation = expectationWithDescription("asynchronous requests should succeed")
        
        let request = self.fetchRequest()
        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: request) { (result) -> Void in
            XCTAssertGreaterThan(result.finalResult!.count, 0, "results should be greater than zero")
            expectation.fulfill()
        }
        
        var error: NSError?
        let result = self.managedObjectContext?.executeRequest(asyncRequest, error: &error)
        
        waitForExpectationsWithTimeout(60, handler:nil)
    }
    
    func fetchRequest() -> NSFetchRequest {
        let request = NSFetchRequest(entityName: "Palette")
        request.fetchLimit = 30
        request.sortDescriptors = Palette.defaultSortDescriptors
        return request
    }
}
