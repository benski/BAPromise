//
//  HelperTests.swift
//  BAPromise
//
//  Created by Taichi Matsumoto on 12/28/16.
//  Copyright © 2016 Ben Allison. All rights reserved.
//

import XCTest
import BAPromise

class HelperTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFulfillWithFactoryMethod() {
        let expectation = XCTestExpectation()
        
        Promise<NSString> {fulfill, reject in
            fulfill("Success" as NSString)
        }.then { value in
            expectation.fulfill()
        }.rejected { error in
            XCTFail("the promise should never be rejected")
        }
    }
    
    func testRejectWithFactoryMethod() {
        let expectation = XCTestExpectation()
        
        Promise<NSString> {fulfill, reject in
            reject(NSError(domain: "promise test", code: 0, userInfo: nil))
        }.then { value in
            XCTFail("the promise should never be fulfilled")
        }.rejected { error in
            expectation.fulfill()
        }
    }
}
