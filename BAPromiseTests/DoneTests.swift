//
//  DoneTests.swift
//  BAPromise
//
//  Created by Ben Allison on 8/21/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import XCTest
@testable import BAPromise

class DoneTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDone() {
        let expectation = XCTestExpectation()
        let promise = Promise<Void>()
        DispatchQueue.global().async {
            promise.fulfill(with: .success)
        }
        
        promise.then({ _ in
            expectation.fulfill()
        }, queue:DispatchQueue.main)
        
        self.wait(for: [expectation], timeout: 0.5)
    }
    
}
