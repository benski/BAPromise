//
//  InteropTests.swift
//  BAPromise
//
//  Created by Ben Allison on 4/11/20.
//  Copyright © 2020 Ben Allison. All rights reserved.
//

import XCTest
import BAPromise

class InteropTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    var dummyError: Error {
        return NSError(domain: "whatever", code: -31337, userInfo: nil)
    }

    func testObjcPromiseFulfill() {
        let expectation = XCTestExpectation()
        let promise = Promise<NSString>()
        let baPromise = promise.objcPromise()
        baPromise.done({ string in
            XCTAssertEqual(string, "test")
            expectation.fulfill()
        }, rejected: { error in
            XCTFail("Unexpected rejection")
        })
        promise.fulfill(with: .success("test"))
        self.wait(for: [expectation], timeout: 0.5)
    }

    func testObjcPromiseReject() {
        let expectation = XCTestExpectation()
        let promise = Promise<NSString>()
        let baPromise = promise.objcPromise()
        baPromise.done({ string in
            XCTFail("Unexpected succest")
        }, rejected: { error in
            expectation.fulfill()
        })
        promise.fulfill(with: .failure(dummyError))
        self.wait(for: [expectation], timeout: 0.5)
    }

    func testObjcCancel() {
        let expectation = XCTestExpectation()
        let promise = Promise<NSString>()
        promise.cancelled({
            expectation.fulfill()
        }, on: .main)

        let baPromise = promise.objcPromise()
        baPromise.cancel()
        self.wait(for: [expectation], timeout: 0.5)
    }

    /// make sure that we don't cancel early when only one of several converted promises cancels
    func testObjcCancelMultiple() {
        let expectation = XCTestExpectation()
        let promise = Promise<NSString>()
        promise.cancelled({
            expectation.fulfill()
        }, on: .main)

        let baPromise = promise.objcPromise()
        let baPromise2 = promise.objcPromise()
        baPromise.cancel()
        baPromise2.cancel()
        self.wait(for: [expectation], timeout: 0.5)
    }

    /// make sure that we don't cancel early when only one of several converted promises cancels
    func testObjcCancelMultipleOnlyOne() {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        let promise = Promise<NSString>()
        promise.cancelled({
            expectation.fulfill()
        }, on: .main)

        let baPromise = promise.objcPromise()
        _ = promise.objcPromise()
        baPromise.cancel()
        self.wait(for: [expectation], timeout: 0.5)
    }

    func testSwiftFulfill() {
        let expectation = XCTestExpectation()
        let baPromise = BAPromise<NSString>()
        let promise = Promise(from: baPromise)
        promise.then({ string in
            XCTAssertEqual(string, "test")
            expectation.fulfill()
        }, rejected: { error in
            XCTFail("Unexpected rejection")
        }, queue: .main)
        baPromise.fulfill(with: "test")
        self.wait(for: [expectation], timeout: 0.5)
    }

    func testSwiftReject() {
        let expectation = XCTestExpectation()
        let baPromise = BAPromise<NSString>()
        let promise = Promise(from: baPromise)
        promise.then({ string in
            XCTFail("Unexpected succest")
        }, rejected: { error in
            expectation.fulfill()
        }, queue: .main)
        baPromise.reject()
        self.wait(for: [expectation], timeout: 0.5)
    }

    func testSwiftNil() {
        let expectation = XCTestExpectation()
        let baPromise = BAPromise<NSString>()
        let promise = Promise(from: baPromise)
        promise.then({ string in
            XCTFail("Unexpected succest")
        }, rejected: { error in
            XCTAssertTrue(error is BAPromiseNilError)
            expectation.fulfill()
        }, queue: .main)
        baPromise.fulfill(with: nil)
        self.wait(for: [expectation], timeout: 0.5)
    }

    func testSwiftCancel() {
        let expectation = XCTestExpectation()
        let baPromise = BAPromise<NSString>()
        baPromise.cancelled {
            expectation.fulfill()
        }

        let promise = Promise(from: baPromise)
        promise.cancel()
        self.wait(for: [expectation], timeout: 0.5)
    }

    /// make sure that we don't cancel early when only one of several converted promises cancels
    func testSwiftCancelMultiple() {
        let expectation = XCTestExpectation()
        let baPromise = BAPromise<NSString>()
        baPromise.cancelled {
            expectation.fulfill()
        }

        let promise = Promise(from: baPromise)
        let promise2 = Promise(from: baPromise)
        promise.cancel()
        promise2.cancel()
        self.wait(for: [expectation], timeout: 0.5)
    }

    /// make sure that we don't cancel early when only one of several converted promises cancels
    func testSwiftCancelMultipleOnlyOne() {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        let baPromise = BAPromise<NSString>()
        baPromise.cancelled {
            expectation.fulfill()
        }

        let promise = Promise(from: baPromise)
        _ = Promise(from: baPromise)
        promise.cancel()
        self.wait(for: [expectation], timeout: 0.5)
    }

}
