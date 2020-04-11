//
//  ChainTestsSwift.swift
//  BAPromise
//
//  Created by Ben Allison on 8/23/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import XCTest
@testable import BAPromise

class ChainTestsSwift: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSimpleFulfill() {
        let expectation = XCTestExpectation()
        let promise = Promise<Int>()
        let anotherPromise = Promise<Int>()
        anotherPromise.fulfill(with: .success(7))
        promise.fulfill(with: .promise(anotherPromise))
        promise.then({ (value) in
            XCTAssertEqual(value, 7)
            expectation.fulfill()
        }, queue: DispatchQueue.main)
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    func testAsyncFulfill() {
        let expectation = XCTestExpectation()
        let promise = Promise<Int>()
        let anotherPromise = Promise<Int>()
        
        promise.fulfill(with: .promise(anotherPromise))
        promise.then({ (value) in
            XCTAssertEqual(value, 7)
            expectation.fulfill()
        }, queue: DispatchQueue.main)
        
        DispatchQueue.global().async {
            anotherPromise.fulfill(with: .success(7))
        }
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    func testSimpleFail() {
        let expectation = XCTestExpectation()
        let promise = Promise<Int>()
        let anotherPromise = Promise<Int>()
        anotherPromise.fulfill(with: .failure(NSError()))
        promise.fulfill(with: .promise(anotherPromise))
        promise.then(rejected:{ (error) in
            expectation.fulfill()
        }, queue: DispatchQueue.main)
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    func testAsyncFail() {
        let expectation = XCTestExpectation()
        let promise = Promise<Int>()
        let anotherPromise = Promise<Int>()
        
        promise.fulfill(with: .promise(anotherPromise))
        promise.then(rejected:{ (error) in
            expectation.fulfill()
        }, queue: DispatchQueue.main)
        
        DispatchQueue.global().async {
            anotherPromise.fulfill(with: .failure(NSError()))
        }
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    func testSimpleFinallySuccess() {
        let expectation = XCTestExpectation()
        let promise = Promise<Int>()
        let anotherPromise = Promise<Int>()
        anotherPromise.fulfill(with: .success(7))
        promise.fulfill(with: .promise(anotherPromise))
        promise.then(always:{
            expectation.fulfill()
        }, queue: DispatchQueue.main)
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    func testAsyncFinallySuccess() {
        let expectation = XCTestExpectation()
        let promise = Promise<Int>()
        let anotherPromise = Promise<Int>()
        
        promise.fulfill(with: .promise(anotherPromise))
        promise.then(always:{
            expectation.fulfill()
        }, queue: DispatchQueue.main)
        
        DispatchQueue.global().async {
            anotherPromise.fulfill(with: .success(7))
        }
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    func testSimpleFinallyFailure() {
        let expectation = XCTestExpectation()
        let promise = Promise<Int>()
        let anotherPromise = Promise<Int>()
        anotherPromise.fulfill(with: .failure(NSError()))
        promise.fulfill(with: .promise(anotherPromise))
        promise.then(always:{
            expectation.fulfill()
        }, queue: DispatchQueue.main)
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    func testAsyncFinallyFailure() {
        let expectation = XCTestExpectation()
        let promise = Promise<Int>()
        let anotherPromise = Promise<Int>()
        
        promise.fulfill(with: .promise(anotherPromise))
        promise.then(always:{
            expectation.fulfill()
        }, queue: DispatchQueue.main)
        
        DispatchQueue.global().async {
            anotherPromise.fulfill(with: .failure(NSError()))
        }
        self.wait(for: [expectation], timeout: 0.5)
    }

    /// This test is actually undefined behavior, as the Promise spec doesn't specify an order here due to chained promises not counting as fulfillment
    func testFulfillSeveralTimes() {
        let testExpectation = expectation(description: "\(self)")
        
        let promise = Promise<Int>()
        let promise1 = Promise<Int>()
        let promise2 = Promise<Int>()
        
        promise.fulfill(with: .promise(promise1))
        promise.fulfill(with: .promise(promise2))
        
        promise2.fulfill(with: .success(2))
        promise1.fulfill(with: .success(1))
        
        promise.then({ (number) in
//            XCTAssertEqual(number, 2)
            testExpectation.fulfill()
        }, queue: .main)
        
        wait(for: [testExpectation], timeout: 5)
    }
}
