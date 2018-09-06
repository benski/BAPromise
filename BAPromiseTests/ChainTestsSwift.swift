//
//  ChainTestsSwift.swift
//  BAPromise
//
//  Created by Ben Allison on 8/23/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import XCTest

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
}
