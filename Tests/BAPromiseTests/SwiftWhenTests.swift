//
//  SwiftWhenTests.swift
//  BAPromise
//
//  Created by Ben Allison on 4/12/20.
//  Copyright © 2020 Ben Allison. All rights reserved.
//

import XCTest
@testable import BAPromise

class SwiftWhenTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    var dummyError: Error {
        return NSError(domain: "whatever", code: -31337, userInfo: nil)
    }

    func testWhen() {
        let expectation = self.expectation(description: "\(self)")
        let promises = [Promise<Int>(3), Promise<Int>(4), Promise<Int>(8)]
        promises.when().then({ ints in
            XCTAssertEqual(ints, [3, 4, 8])
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

    func testWhenPartial() {
        let expectation = self.expectation(description: "\(self)")
        expectation.isInverted = true
        let promises = [Promise<Int>(3), Promise<Int>(4), Promise<Int>()]
        promises.when().then({ ints in
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

    func testWhenEmpty() {
        let expectation = self.expectation(description: "\(self)")
        let promises: [Promise<Int>] = []
        promises.when().then({ ints in
            XCTAssertEqual(ints, [])
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

    func testWhenCanceled() {
        let expectation1 = self.expectation(description: "Promise 1 cancellation")
        let expectation2 = self.expectation(description: "Promise 2 cancellation")

        let promise1 = Promise<Int>()
        let promise2 = Promise<Int>()

        promise1.cancelled({
            expectation1.fulfill()
        }, on: .main)

        promise2.cancelled({
            expectation2.fulfill()
        }, on: .main)

        let promises = [promise1, promise2]
        promises.when().then({ ints in
            XCTFail("Unexpected success")
        }, queue: .main).cancel()

        wait(for: [expectation1, expectation2], timeout: 0.5)
    }

    func testWhenFail() {
        let expectation = self.expectation(description: "\(self)")
        let promises = [Promise<Int>(3), Promise<Int>(error: dummyError), Promise<Int>(8)]
        promises.when().then({ ints in
            XCTFail("Unexpected success")
        }, rejected: { error in
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

    func testJoin() {
        let expectation = self.expectation(description: "\(self)")
        let promises = [Promise<Int>(3), Promise<Int>(4), Promise<Int>(8)]
        promises.join().then({ ints in
            XCTAssertEqual(ints, [PromiseResult<Int>(value: 3), PromiseResult<Int>(value: 4), PromiseResult<Int>(value: 8)])
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

    func testJoinPartial() {
        let expectation = self.expectation(description: "\(self)")
        expectation.isInverted = true
        let promises = [Promise<Int>(3), Promise<Int>(), Promise<Int>(8)]
        promises.join().then({ ints in
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

    func testJoinMixed() {
        let expectation = self.expectation(description: "\(self)")
        let promises = [Promise<Int>(3), Promise<Int>(error: dummyError), Promise<Int>(8)]
        promises.join().then({ ints in
            XCTAssertEqual(ints.successes(), [3, 8])
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

    func testCompactJoinMixed() {
        let expectation = self.expectation(description: "\(self)")
        let promises = [Promise<Int>(3), Promise<Int>(error: dummyError), Promise<Int>(8)]
        promises.compactJoin().then({ ints in
            XCTAssertEqual(ints, [3, 8])
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

    func testJoinFail() {
        let expectation = self.expectation(description: "\(self)")
        let promises = [Promise<Int>(error: dummyError), Promise<Int>(error: dummyError)]
        promises.join().then({ ints in
            XCTAssertEqual(ints.successes(), [])
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

    func testCompactJoinFail() {
        let expectation = self.expectation(description: "\(self)")
        let promises = [Promise<Int>(error: dummyError), Promise<Int>(error: dummyError)]
        promises.compactJoin().then({ ints in
            XCTAssertEqual(ints, [])
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

    func testJoinEmpty() {
        let expectation = self.expectation(description: "\(self)")
        let promises: [Promise<Int>] = []
        promises.join().then({ ints in
            XCTAssertEqual(ints, [])
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

    func testJoinCanceled() {
        let expectation1 = self.expectation(description: "Promise 1 cancellation")
        let expectation2 = self.expectation(description: "Promise 2 cancellation")

        let promise1 = Promise<Int>()
        let promise2 = Promise<Int>()

        promise1.cancelled({
            expectation1.fulfill()
        }, on: .main)

        promise2.cancelled({
            expectation2.fulfill()
        }, on: .main)

        let promises = [promise1, promise2]
        promises.join().then({ ints in
            XCTFail("Unexpected success")
        }, queue: .main).cancel()

        wait(for: [expectation1, expectation2], timeout: 0.5)
    }

    func testVoidJoin() {
           let expectation = self.expectation(description: "\(self)")
        let promises = [Promise<Void>.completed(), Promise<Void>.completed()]
           promises.join().then({
               expectation.fulfill()
           }, queue: .main)
           wait(for: [expectation], timeout: 0.5)
       }

    /// benski> not sure I like this behavior. we might want to reconsider having it return a Completable (only for `when`)
    func testVoidJoinFail() {
        let expectation = self.expectation(description: "\(self)")
        let promises = [Promise<Void>(error: dummyError), Promise<Void>(error: dummyError)]
        promises.join().then({
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

    func testVoidJoinCanceled() {
        let expectation1 = self.expectation(description: "Promise 1 cancellation")
        let expectation2 = self.expectation(description: "Promise 2 cancellation")

        let promise1 = Promise<Void>()
        let promise2 = Promise<Void>()

        promise1.cancelled({
            expectation1.fulfill()
        }, on: .main)

        promise2.cancelled({
            expectation2.fulfill()
        }, on: .main)

        let promises = [promise1, promise2]
        promises.join().then({ 
            XCTFail("Unexpected success")
        }, queue: .main).cancel()

        wait(for: [expectation1, expectation2], timeout: 0.5)
    }
}
