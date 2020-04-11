//
//  MapTests.swift
//  BAPromise
//
//  Created by Ben Allison on 4/11/20.
//  Copyright © 2020 Ben Allison. All rights reserved.
//

import XCTest

class MapTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    var dummyError: Error {
         return NSError(domain: "whatever", code: -31337, userInfo: nil)
     }

    func testMap() {
        let expectation = XCTestExpectation()
        let promise = Promise<String>("1.4")
        promise.map({ value -> Int in
            XCTAssertEqual(value, "1.4")
            return 7
        }, queue: DispatchQueue.main)
            .then({ (value) in
                XCTAssertEqual(value, 7)
                expectation.fulfill()
            }, queue: DispatchQueue.main)
        self.wait(for: [expectation], timeout: 0.5)
    }

    func testMapThrow() {
        let expectation = XCTestExpectation()
        let promise = Promise<String>("1.4")
        promise.map({ value -> Int in
            XCTAssertEqual(value, "1.4")
            throw self.dummyError
        }, queue: DispatchQueue.main)
            .then({ (value) in
                XCTFail("Unexpected fulfillment")
            }, rejected:{ (error) in
                expectation.fulfill()
            }, queue: DispatchQueue.main)
        self.wait(for: [expectation], timeout: 0.5)
    }

    func testFlatMap() {
        let expectation = XCTestExpectation()
        let promise = Promise<String>("1.4")
        promise.flatMap({ value -> Promise<Int> in
            XCTAssertEqual(value, "1.4")
            return Promise<Int>(7)
        }, queue: DispatchQueue.main)
            .then({ (value) in
                XCTAssertEqual(value, 7)
                expectation.fulfill()
            }, queue: DispatchQueue.main)
        self.wait(for: [expectation], timeout: 0.5)
    }

    func testFlatMapThrow() {
        let expectation = XCTestExpectation()
        let promise = Promise<String>("1.4")
        promise.flatMap({ value -> Promise<Int> in
            XCTAssertEqual(value, "1.4")
            throw self.dummyError
        }, queue: DispatchQueue.main)
            .then({ (value) in
                XCTFail("Unexpected fulfillment")
            }, rejected:{ (error) in
                expectation.fulfill()
            }, queue: DispatchQueue.main)
        self.wait(for: [expectation], timeout: 0.5)
    }


}
