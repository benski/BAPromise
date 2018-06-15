//
//  PromiseBlocksTests.swift
//  OS XTests
//
//  Created by Ben Allison on 6/15/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import XCTest
@testable import BAPromise

class PromiseBlocksTests: XCTestCase {
    
    enum DummyError: Error {
        case dummy
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testKeepBlockEmpty() {
        let promiseBlock = Promise.PromiseBlock(cancellationToken: PromiseCancelToken())
        XCTAssertFalse(promiseBlock.shouldKeepPromise)
    }
    
    func testKeepBlockObserved() {
        let promiseBlock = Promise.PromiseBlock(cancellationToken: PromiseCancelToken())
        promiseBlock.observed = { (obj) in }
        XCTAssertFalse(promiseBlock.shouldKeepPromise)
    }
    
    func testKeepBlockDone() {
        let promiseBlock = Promise.PromiseBlock(cancellationToken: PromiseCancelToken())
        promiseBlock.done = { (obj) in }
        XCTAssertTrue(promiseBlock.shouldKeepPromise)
    }
    
    func testKeepBlockRejected() {
        let promiseBlock = Promise.PromiseBlock(cancellationToken: PromiseCancelToken())
        promiseBlock.rejected = { (obj) in }
        XCTAssertTrue(promiseBlock.shouldKeepPromise)
    }
    
    func testKeepBlockAlways() {
        let promiseBlock = Promise.PromiseBlock(cancellationToken: PromiseCancelToken())
        promiseBlock.always = { }
        XCTAssertTrue(promiseBlock.shouldKeepPromise)
    }
    
    func testCallNonError() {
        let promiseBlock = Promise.PromiseBlock(cancellationToken: PromiseCancelToken())
        let callObj = 7
        
        let doneExpect = XCTestExpectation()
        promiseBlock.done = { (obj) in
            XCTAssertEqual(obj as! Int, callObj)
            doneExpect.fulfill()
        }
        
        let observedExpect = XCTestExpectation()
        promiseBlock.observed = { (obj) in
            XCTAssertEqual(obj as! Int, callObj)
            observedExpect.fulfill()
        }
        
        promiseBlock.rejected = { (obj) in
            XCTFail("unexpected rejection")
        }
        
        let alwaysExpect = XCTestExpectation()
        promiseBlock.always = {
            alwaysExpect.fulfill()
        }
        
        promiseBlock.call(with: callObj)
        
        self.wait(for: [doneExpect, observedExpect, alwaysExpect], timeout: 10)
    }
 
    func testCallNonErrorOnQueue() {
        let promiseBlock = Promise.PromiseBlock(cancellationToken: PromiseCancelToken())
        let key = DispatchSpecificKey<String>()
        promiseBlock.queue = DispatchQueue(label: "testCallNonErrorOnQueue")
        promiseBlock.queue?.setSpecific(key: key, value: "testCallNonErrorOnQueue")
        let callObj = 7
        
        let doneExpect = XCTestExpectation()
        promiseBlock.done = { obj in
            XCTAssertEqual(obj as! Int, callObj)
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), "testCallNonErrorOnQueue")
            doneExpect.fulfill()
        }
        
        let observedExpect = XCTestExpectation()
        promiseBlock.observed = { obj in
            XCTAssertEqual(obj as! Int, callObj)
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), "testCallNonErrorOnQueue")
            observedExpect.fulfill()
        }
        
        promiseBlock.rejected = { obj in
            XCTFail("unexpected rejection")
        }
        
        let alwaysExpect = XCTestExpectation()
        promiseBlock.always = {
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), "testCallNonErrorOnQueue")
            alwaysExpect.fulfill()
        }
        
        promiseBlock.call(with: callObj)
        
        self.wait(for: [doneExpect, observedExpect, alwaysExpect], timeout: 10)
    }
    
    func testCallError() {
        let promiseBlock = Promise.PromiseBlock(cancellationToken: PromiseCancelToken())
        let callObj = DummyError.dummy
        
        promiseBlock.done = { obj in
            XCTFail("unexpected success")
            
        }
        
        promiseBlock.observed = { obj in
            XCTFail("unexpected success")
        }
        
        let rejectedExpectation = XCTestExpectation()
        promiseBlock.rejected = { obj in
            rejectedExpectation.fulfill()
        }
        
        let alwaysExpect = XCTestExpectation()
        promiseBlock.always = {
            alwaysExpect.fulfill()
        }
        
        promiseBlock.call(with: callObj)
        
        self.wait(for: [rejectedExpectation, alwaysExpect], timeout: 10)
    }
    
    func testCallErrorOnQueue() {
        let promiseBlock = Promise.PromiseBlock(cancellationToken: PromiseCancelToken())
        let key = DispatchSpecificKey<String>()
        promiseBlock.queue = DispatchQueue(label: "testCallNonErrorOnQueue")
        promiseBlock.queue?.setSpecific(key: key, value: "testCallNonErrorOnQueue")
        let callObj = DummyError.dummy
        
        promiseBlock.done = { obj in
            XCTFail("unexpected success")
        }
        
        promiseBlock.observed = { obj in
            XCTFail("unexpected success")
        }
        
        let rejectedExpectation = XCTestExpectation()
        promiseBlock.rejected = { obj in
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), "testCallNonErrorOnQueue")
            rejectedExpectation.fulfill()
        }
        
        let alwaysExpect = XCTestExpectation()
        promiseBlock.always = {
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), "testCallNonErrorOnQueue")
            alwaysExpect.fulfill()
        }
        
        promiseBlock.call(with: callObj)
        
        self.wait(for: [rejectedExpectation, alwaysExpect], timeout: 10)
    }
    
}
