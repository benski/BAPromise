//
//  CancelTestsSwift.swift
//  BAPromise
//
//  Created by Ben Allison on 8/23/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import XCTest

class CancelTestsSwift: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCancel() {
        let expectation = XCTestExpectation()
        let promise = Promise<Void>()
        promise.cancelled({ expectation.fulfill() }, on: DispatchQueue.main)
        promise.cancel()
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    func testDoneAfterCancel() {
        let expectation = XCTestExpectation()
        let promise = Promise<Void>()
        promise.cancelled({ expectation.fulfill() }, on: DispatchQueue.main)
        
        let token = promise.then({
            XCTFail("Cancelation should prevent calling of done block")
        }, observed: { _ in
            XCTFail("Cancelation should prevent calling of observed block")
        }, rejected: { (error) in
            XCTFail("Cancelation should prevent calling of rejected block")
        }, always: {
            XCTFail("Cancelation should prevent calling of finally block")
        }, queue: DispatchQueue.main)
        token.cancel()
        
        self.wait(for: [expectation], timeout: 0.5)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    }
    
    func testCancelTokenAfterFulfillment() {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        let promise = Promise<Void>()
        promise.fulfill(with: .success)
        promise.cancelled({
            XCTFail("Unexpected cancelled callback")
            expectation.fulfill()
        }, on: DispatchQueue.main)

        let forFulfillment = XCTestExpectation()
        let token = promise.then({ forFulfillment.fulfill() }, queue: DispatchQueue.main)
        self.wait(for: [forFulfillment], timeout: 0.5)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            token.cancel()
        }
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    func testCancelPromiseAfterFulfilment() {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        let promise = Promise<Void>()
        promise.fulfill(with: .success)
        promise.cancelled({
            XCTFail("Unexpected cancelled callback")
            expectation.fulfill()
        }, on: DispatchQueue.main)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            promise.cancel()
        }
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    func testCancelPromiseAfterRejection() {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        let promise = Promise<Void>()
        promise.fulfill(with: .failure(NSError()))
        promise.cancelled({
            XCTFail("Unexpected cancelled callback")
expectation.fulfill()
        }, on: DispatchQueue.main)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            promise.cancel()
        }
        self.wait(for: [expectation], timeout: 0.5)
    }
   
    func testLateCancelCallback() {
        let expectation = XCTestExpectation()
        let promise = Promise<Void>()
        promise.cancel()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            promise.cancelled({ expectation.fulfill() }, on: DispatchQueue.main)
        }
        
        self.wait(for: [expectation], timeout: 0.5)
    }

    func testCancelToken() {
        let expectation = XCTestExpectation()
        let promise = Promise<Void>()
        promise.cancelled({  XCTFail("unepected onCancel") }, on: DispatchQueue.main)
        promise.fulfill(with: .success)
        
        let token = promise.then({
            XCTFail("Cancelation should prevent calling of done block")
        }, observed: { _ in
            XCTFail("Cancelation should prevent calling of observed block")
        }, rejected: { (error) in
            XCTFail("Cancelation should prevent calling of rejected block")
        }, always: {
            XCTFail("Cancelation should prevent calling of finally block")
        }, queue: DispatchQueue.main)
        token.cancel()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 0.5)
        
    }
    
    func testCancelAsyncARC() {
        let expectation = XCTestExpectation()
        let promise = Promise<Void>()
        promise.cancelled({  XCTFail("unepected onCancel") }, on: DispatchQueue.main)
        
        DispatchQueue.main.async {
            promise.fulfill(with: .success)
            let token = promise.then({
                XCTFail("Cancelation should prevent calling of done block")
            }, observed: { _ in
                XCTFail("Cancelation should prevent calling of observed block")
            }, rejected: { (error) in
                XCTFail("Cancelation should prevent calling of rejected block")
            }, always: {
                XCTFail("Cancelation should prevent calling of finally block")
            }, queue: DispatchQueue.main)
            token.cancel()
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 0.5)
        
    }
    
    func testCancelReject() {
        let expectation = XCTestExpectation()
        let promise = Promise<Void>()
        promise.cancelled({  XCTFail("unepected onCancel") }, on: DispatchQueue.main)
        promise.fulfill(with: .failure(NSError()))
        
        let token = promise.then({
            XCTFail("Cancelation should prevent calling of done block")
        }, observed: { _ in
            XCTFail("Cancelation should prevent calling of observed block")
        }, rejected: { (error) in
            XCTFail("Cancelation should prevent calling of rejected block")
        }, always: {
            XCTFail("Cancelation should prevent calling of finally block")
        }, queue: DispatchQueue.main)
        token.cancel()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 0.5)
        
    }
    
    func testCancelAsyncARCReject() {
        let expectation = XCTestExpectation()
        let promise = Promise<Void>()
        promise.cancelled({  XCTFail("unepected onCancel") }, on: DispatchQueue.main)
        
        DispatchQueue.main.async {
            promise.fulfill(with: .failure(NSError()))
            let token = promise.then({
                XCTFail("Cancelation should prevent calling of done block")
            }, observed: { _ in
                XCTFail("Cancelation should prevent calling of observed block")
            }, rejected: { (error) in
                XCTFail("Cancelation should prevent calling of rejected block")
            }, always: {
                XCTFail("Cancelation should prevent calling of finally block")
            }, queue: DispatchQueue.main)
            token.cancel()
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 0.5)
        
    }
    
    func testCancelThen() {
        let expectation1 = XCTestExpectation()
        let thenPromise = Promise<Void>()
        let fulfilledPromise = Promise<Void>()
        fulfilledPromise.fulfill(with: .success)
        let cancelToken = fulfilledPromise.then({ () -> PromiseResult<Void> in
            expectation1.fulfill()
            return .promise(thenPromise)
        }, queue: DispatchQueue.main)
        self.wait(for: [expectation1], timeout: 0.5)
        
        let expectation2 = XCTestExpectation()
        thenPromise.cancelled({
            expectation2.fulfill()
        }, on: DispatchQueue.main)
        
        cancelToken.cancel()
        self.wait(for: [expectation2], timeout: 0.5)
    }
    
    func testCancelThenRaceCondition() {
        let expectation = XCTestExpectation()
        let thenPromise = Promise<Void>()
        thenPromise.cancelled({
            expectation.fulfill()
        }, on: DispatchQueue.main)
        
        let fulfilledPromise = Promise<Void>()
        fulfilledPromise.fulfill(with: .success)
        
        let cancelToken = fulfilledPromise.then({ () -> PromiseResult<Void> in
            return .promise(thenPromise)
        }, queue: DispatchQueue.main)

        DispatchQueue.main.async {
            cancelToken.cancel()
        }
        self.wait(for: [expectation], timeout: 0.5)
    }
}
