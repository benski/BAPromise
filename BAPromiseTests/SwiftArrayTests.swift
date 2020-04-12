//
//  SwiftArrayTests.swift
//  BAPromise
//
//  Created by Ben Allison on 4/11/20.
//  Copyright © 2020 Ben Allison. All rights reserved.
//

import XCTest
@testable import BAPromise

class SwiftArrayTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    var dummyError: Error {
        return NSError(domain: "whatever", code: -31337, userInfo: nil)
    }

    func testAllSuccesses() {
        let resultArray = [PromiseResult<Int>(value: 2), PromiseResult<Int>(value: 3)]
        XCTAssertEqual(resultArray.successes(), [2, 3])
    }

    func testMixedSuccesses() {
        let resultArray = [PromiseResult<Int>(error: dummyError), PromiseResult<Int>(value: 3)]
        XCTAssertEqual(resultArray.successes(), [3])
    }

    func testNoSuccesses() {
        let resultArray = [PromiseResult<Int>(error: dummyError), PromiseResult<Int>(error: dummyError)]
        XCTAssertEqual(resultArray.successes(), [])
    }


}
