import Dispatch
import Foundation
import NSpry
import XCTest

@testable import NQueue
@testable import NQueueTestHelpers

final class DelayedQueueTests: XCTestCase {
    // MARK: - fake

    func test_fake_queue_absent() {
        let subject: DelayedQueue = .absent
        var didCall = false
        subject.fire {
            didCall = true
        }
        XCTAssertTrue(didCall)
    }

    func test_fake_queue_sync() {
        let queue: FakeQueueable = .init()
        queue.shouldFireSyncClosures = true
        queue.stub(.sync).andReturn()

        let subject: DelayedQueue = .sync(queue)
        var didCall = false
        subject.fire {
            didCall = true
        }
        XCTAssertTrue(didCall)
        XCTAssertHaveReceived(queue, .sync)
    }

    func test_fake_queue_async() {
        let queue: FakeQueueable = .init()
        queue.shouldFireSyncClosures = true
        queue.stub(.async).andReturn()

        let subject: DelayedQueue = .async(queue)
        var didCall = false
        subject.fire {
            didCall = true
        }
        XCTAssertFalse(didCall)
        XCTAssertHaveReceived(queue, .async)

        queue.asyncWorkItem?()
        XCTAssertTrue(didCall)
    }

    func test_fake_queue_async_after() {
        let dispatchTime = DispatchTime.delayInSeconds(1)

        let queue: FakeQueueable = .init()
        queue.shouldFireSyncClosures = true
        queue.stub(.asyncAfter).andReturn()

        let subject: DelayedQueue = .asyncAfter(deadline: dispatchTime, queue: queue)
        var didCall = false
        subject.fire {
            didCall = true
        }
        XCTAssertFalse(didCall)
        XCTAssertHaveReceived(queue, .asyncAfter, with: dispatchTime, Argument.anything)

        queue.asyncWorkItem?()
        XCTAssertTrue(didCall)
    }

    func test_fake_queue_async_after_with_flags() {
        let dispatchTime = DispatchTime.delayInSeconds(1)

        let queue: FakeQueueable = .init()
        queue.shouldFireSyncClosures = true
        queue.stub(.asyncAfterWithFlags).andReturn()

        let subject: DelayedQueue = .asyncAfterWithFlags(deadline: dispatchTime, flags: .barrier, queue: queue)
        var didCall = false
        subject.fire {
            didCall = true
        }
        XCTAssertFalse(didCall)
        XCTAssertHaveReceived(queue, .asyncAfterWithFlags, with: dispatchTime, Queue.Flags.barrier, Argument.anything)

        queue.asyncWorkItem?()
        XCTAssertTrue(didCall)
    }

    // MARK: - real

    func test_real_queue_absent() {
        let subject: DelayedQueue = .absent
        var didCall = false
        subject.fire {
            didCall = true
        }
        XCTAssertTrue(didCall)
    }

    func test_real_queue_sync() {
        let queue = Queue.main
        let subject: DelayedQueue = .sync(queue)
        var didCall = false
        subject.fire {
            didCall = true
        }
        XCTAssertTrue(didCall)
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
