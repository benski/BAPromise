//
//  PromiseInitTests.swift
//  BAPromise
//
//  Created by Vyrko, Mihail on 1/22/19.
//  Copyright © 2019 Ben Allison. All rights reserved.
//

import Foundation

import XCTest
import BAPromise

class PromiseInitTests: XCTestCase {

    func testSuccess() {
        let expectation = self.expectation(description: "\(self)")
        let value = 5
        let promise = Promise(value)
        promise.then({ (response) in
            XCTAssert(response == value)
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

    func testFailure() {
        let expectation = self.expectation(description: "\(self)")
        let error = NSError(domain: "domain", code: 0, userInfo: nil)
        let promise = Promise<Any>(error: error)
        promise.then({ (_) in
            XCTFail()
        }, rejected: { (remoteError) in
            XCTAssert((error as NSError) == (remoteError as NSError))
            expectation.fulfill()
        }, queue: .main)
        wait(for: [expectation], timeout: 0.5)
    }

}
