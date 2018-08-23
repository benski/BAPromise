//
//  DoneTests.swift
//  BAPromise
//
//  Created by Ben Allison on 8/21/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import XCTest
@testable import BAPromise

class DoneTestsSwift: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDoneVoid() {
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
    
    func testDonePrimitive() {
        let expectation = XCTestExpectation()
        let promise = Promise<Float?>()
        DispatchQueue.global().async {
            promise.fulfill(with: .success(3.14))
        }
        
        promise.then({ value in
            XCTAssertEqual(value, 3.14, "Unexpected Value")
            expectation.fulfill()
        }, queue:DispatchQueue.main)
        
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    struct MyStructIsAwesome {
        let a: Double = 4.0
        let b: String = "yes"
    }
    
    func testDoneStruct() {
        let expectation = XCTestExpectation()
        let promise = Promise<MyStructIsAwesome>()
        DispatchQueue.global().async {
            promise.fulfill(with: .success(MyStructIsAwesome()))
        }
        
        promise.then({ value in
            XCTAssertEqual(value.a, 4, "Unexpected Value")
            XCTAssertEqual(value.b, "yes", "Unexpected Value")
            expectation.fulfill()
        }, queue:DispatchQueue.main)
        
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    func testDoneVerifyQueue() {
        let expectation = XCTestExpectation()
        let key = DispatchSpecificKey<String>()
        let promise = Promise<Void>()
        let myQueue = DispatchQueue(label: "myQueue")
        myQueue.setSpecific(key: key, value: "testDoneVerifyQueue")
        DispatchQueue.global().async {
            promise.fulfill(with: .success)
        }
        promise.then({
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), "testDoneVerifyQueue")
            expectation.fulfill()
        }, queue:myQueue)
        self.wait(for: [expectation], timeout: 0.5)
    }
  
    func testFulfillmentFirst() {
        let expectation = XCTestExpectation()
        let promise = Promise<Void>()
        promise.fulfill(with: .success)
        
        promise.then({ value in
            expectation.fulfill()
        }, queue:DispatchQueue.main)
        
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    func testFulfillmentSecond() {
        let expectation = XCTestExpectation()
        let promise = Promise<Void>()
        
        promise.then({ value in
            expectation.fulfill()
        }, queue:DispatchQueue.main)
        
        promise.fulfill(with: .success)
        
        self.wait(for: [expectation], timeout: 0.5)
    }   
}
