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
        do {
            let request = self.fetchRequest()
            guard let results = try managedObjectContext?.fetch(request) as? [Palette] else {
                fatalError()
            }
            
            XCTAssertGreaterThan(results.count, 0, "results should be greater than zero")
        }
        catch {
            XCTFail("request should not fail")
        }
    }
    
    func testRemoteObjectsCanBeFetchedAsynchronously() {
        let expectation = self.expectation(withDescription: "asynchronous requests should succeed")
        
        let request = self.fetchRequest()
        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: request) { (result) -> Void in
            XCTAssertGreaterThan(result.finalResult!.count, 0, "results should be greater than zero")
            expectation.fulfill()
        }
        
        try! self.managedObjectContext?.execute(asyncRequest)
        
        waitForExpectations(withTimeout: 60, handler:nil)
    }
    
    func fetchRequest() -> NSFetchRequest<AnyObject> {
        let request = NSFetchRequest(entityName: "Palette")
        request.fetchLimit = 30
        request.sortDescriptors = Palette.defaultSortDescriptors
        return request
    }
}
