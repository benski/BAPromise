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
        
        let promise = BAPromiseClient<NSString>.promise({fulfill, reject in
            fulfill("Success" as NSString)
        });
        
        promise.then { value in
            expectation.fulfill()
        }.rejected { error in
            XCTFail("the promise should never be rejected")
        }
    }
    
    func testRejectWithFactoryMethod() {
        let expectation = XCTestExpectation()
        
        let promise = BAPromiseClient<NSString>.promise({fulfill, reject in
            reject(NSError(domain: "promise test", code: 0, userInfo: nil))
        });
        
        promise.then { value in
            XCTFail("the promise should never be fulfilled")
        }.rejected { error in
            expectation.fulfill()
        }
    }
}
