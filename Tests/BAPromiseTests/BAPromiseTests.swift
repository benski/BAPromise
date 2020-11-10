import XCTest
@testable import BAPromise

enum TestError: Error {
  case error
}

final class BAPromiseTests: XCTestCase {
    func testExample() {
      let promise = Promise<Int>()
      promise.then({ (myInt) -> PromiseResult<Int> in
        XCTAssertEqual(myInt, 42)
        return .success(myInt)
      }, rejected: { (error) -> PromiseResult<Int> in
        XCTFail()
        return .failure(TestError.error)
      },
      always: {
        // always
      }, queue: .main)
      promise.fulfill(with: .success(42))
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
