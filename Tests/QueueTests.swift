import Dispatch
import Foundation
import NSpry
import XCTest

@testable import NQueue
@testable import NQueueTestHelpers

final class QueueTests: XCTestCase {
    func test_async() {
        let callExpectation = expectation(description: "should be called")
        let subject = Queue.main
        subject.async {
            callExpectation.fulfill()
        }
        wait(for: [callExpectation], timeout: 0.1)
    }

    func test_asyncAfter() {
        let callExpectation = expectation(description: "should be called")
        let subject = Queue.main
        subject.asyncAfter(deadline: .delayInSeconds(0.1)) {
            callExpectation.fulfill()
        }
        wait(for: [callExpectation], timeout: 0.2)
    }

    func test_sync() {
        var didCall = false
        let subject = Queue.main
        subject.sync {
            didCall = true
        }
        XCTAssertTrue(didCall)
    }
}
