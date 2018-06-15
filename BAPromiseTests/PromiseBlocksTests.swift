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
    
    
}
