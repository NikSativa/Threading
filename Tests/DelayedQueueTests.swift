import Foundation
import Threading
import XCTest

final class DelayedQueueTests: XCTestCase {
    func test_fake_queue_absent() {
        let subject: DelayedQueue = .absent
        let didCall = expectation(description: "didCall")
        subject.fire {
            didCall.fulfill()
        }
        wait(for: [didCall], timeout: 0)
    }

    func test_fake_queue_sync() {
        let queue: FakeQueueable = .init()
        queue.shouldFireSyncClosures = true

        let subject: DelayedQueue = .sync(queue)
        let didCall = expectation(description: "didCall")
        subject.fire {
            didCall.fulfill()
        }
        wait(for: [didCall], timeout: 0)
        XCTAssertEqual(queue.syncCallCount, 1)
    }

    func test_fake_queue_async() {
        let queue: FakeQueueable = .init()

        let subject: DelayedQueue = .async(queue)
        let didCall = expectation(description: "didCall")
        subject.fire {
            didCall.fulfill()
        }
        XCTAssertEqual(queue.asyncCallCount, 1)

        queue.asyncWorkItem?()
        wait(for: [didCall], timeout: 1)
    }

    func test_fake_queue_async_after() {
        let dispatchTime = DispatchTime.delayInSeconds(1)

        let queue: FakeQueueable = .init()

        let subject: DelayedQueue = .asyncAfter(deadline: dispatchTime, queue: queue)
        let didCall = expectation(description: "didCall")
        subject.fire {
            didCall.fulfill()
        }
        XCTAssertEqual(queue.asyncAfterCallCount, 1)
        XCTAssertEqual(queue.lastFlags, .absent)

        queue.asyncWorkItem?()
        wait(for: [didCall], timeout: 0)
    }

    func test_fake_queue_async_after_with_flags() {
        let dispatchTime = DispatchTime.delayInSeconds(1)

        let queue: FakeQueueable = .init()

        let subject: DelayedQueue = .asyncAfterWithFlags(deadline: dispatchTime, flags: .barrier, queue: queue)
        let didCall = expectation(description: "didCall")
        subject.fire {
            didCall.fulfill()
        }
        XCTAssertEqual(queue.asyncAfterCallCount, 1)
        XCTAssertEqual(queue.lastFlags, .barrier)

        queue.asyncWorkItem?()
        wait(for: [didCall], timeout: 0)
    }

    func test_real_queue_absent() {
        let subject: DelayedQueue = .absent
        let didCall = expectation(description: "didCall")
        subject.fire {
            didCall.fulfill()
        }
        wait(for: [didCall], timeout: 0)
    }

    func test_real_queue_sync() {
        let queue = Queue.main
        let subject: DelayedQueue = .sync(queue)
        let didCall = expectation(description: "didCall")
        subject.fire {
            didCall.fulfill()
        }
        wait(for: [didCall], timeout: 0)
    }

    func test_real_queue_async() {
        let queue = Queue.main
        let subject: DelayedQueue = .async(queue)
        let didCall = expectation(description: "should be called")
        subject.fire {
            didCall.fulfill()
        }
        wait(for: [didCall], timeout: 0.1)
    }

    func test_real_queue_async_after() {
        let queue = Queue.main
        let dispatchTime = DispatchTime.delayInSeconds(0.1)
        let subject: DelayedQueue = .asyncAfter(deadline: dispatchTime, queue: queue)
        let didCall = expectation(description: "should be called")
        subject.fire {
            didCall.fulfill()
        }
        wait(for: [didCall], timeout: 0.2)
    }

    func test_real_queue_async_after_with_flags_barrier() {
        let queue = Queue.main
        let dispatchTime = DispatchTime.delayInSeconds(0.1)
        let subject: DelayedQueue = .asyncAfterWithFlags(deadline: dispatchTime, flags: .barrier, queue: queue)
        let didCall = expectation(description: "should be called")
        subject.fire {
            didCall.fulfill()
        }
        wait(for: [didCall], timeout: 0.2)
    }

    func test_real_queue_async_after_with_flags() {
        let queue = Queue.main
        let dispatchTime = DispatchTime.delayInSeconds(0.1)
        let subject: DelayedQueue = .asyncAfterWithFlags(deadline: dispatchTime, flags: .absent, queue: queue)
        let didCall = expectation(description: "should be called")
        subject.fire {
            didCall.fulfill()
        }
        wait(for: [didCall], timeout: 0.2)
    }
}
