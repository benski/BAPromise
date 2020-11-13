//
//  PromiseResultTests.swift
//  BAPromise
//
//  Created by Ben Allison on 4/11/20.
//  Copyright © 2020 Ben Allison. All rights reserved.
//

import XCTest
@testable import BAPromise

class PromiseResultTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    var dummyError: Error {
        return NSError(domain: "whatever", code: -31337, userInfo: nil)
    }
    func testResolvedSuccess() {
        let result = PromiseResult<Int>(value: 42)
        XCTAssertTrue(result.resolved)
    }

    func testResolvedSuccessVoid() {
        let result = PromiseResult<Void>()
        XCTAssertTrue(result.resolved)
    }

    func testResolvedPromise() {
        let result = PromiseResult<Int>(promise: Promise<Int>())
        XCTAssertFalse(result.resolved)
    }

    func testResolvedFailure() {
        let result = PromiseResult<Int>(error: dummyError)
        XCTAssertTrue(result.resolved)
    }

    func testEqual() {
        XCTAssertEqual(PromiseResult<Int>(value: 42), PromiseResult<Int>(value: 42))
    }

    func testNotEqual() {
        let commonError = dummyError
        XCTAssertNotEqual(PromiseResult<Int>(error: commonError), PromiseResult<Int>(error: commonError)) // Error isn't Equatable
        XCTAssertNotEqual(PromiseResult<Int>(value: 42), PromiseResult<Int>(value: 43))
        XCTAssertNotEqual(PromiseResult<Int>(promise: Promise<Int>()), PromiseResult<Int>(promise: Promise<Int>()))
    }
}
