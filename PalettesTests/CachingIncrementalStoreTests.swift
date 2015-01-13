//
//  CachingIncrementalStoreTests.swift
//  Palettes
//
//  Created by Andrew Shepard on 1/12/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import XCTest
import CoreData

class CachingIncrementalStoreTests: XCTestCase {
    var managedObjectContext: NSManagedObjectContext?
    
    override func setUp() {
        super.setUp()
        
        self.removeSQLCache()
        
        let storeType = CachingIncrementalStore.storeType
        self.managedObjectContext = TestingContextProvider.contextWithStoreType(storeType)
        
        XCTAssertNotNil(managedObjectContext, "context should not be nil")
    }
    
    override func tearDown() {
        self.removeSQLCache()
        super.tearDown()
    }
    
    func testRemoteObjectsCanBeFetched() {
        let request = NSFetchRequest(entityName: "Palette")
        request.fetchLimit = 30
        request.sortDescriptors = Palette.defaultSortDescriptors
        
        let expectation = expectationWithDescription("save notification should be observed")
        
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextDidSaveNotification, object: nil, queue: nil) { (notification) -> Void in
            println("notification called!")
            
            struct Static {
                static var onceToken : dispatch_once_t = 0
            }
            dispatch_once(&Static.onceToken) {
                expectation.fulfill()
            }
        }
        
        var error: NSError?
        let results = managedObjectContext?.executeFetchRequest(request, error: &error) as [Palette]
        
        XCTAssertLessThanOrEqual(results.count, 0, "there should be no cached results")
        
        waitForExpectationsWithTimeout(60, handler: nil)
    }
    
    func removeSQLCache() -> Void {
        let path = CachingIncrementalStore.storeType + ".sqlite"
        let url = NSURL.applicationDocumentsDirectory().URLByAppendingPathComponent(path)
        
        var error: NSError? = nil
        NSFileManager.defaultManager().removeItemAtURL(url, error: &error)
    }
}
