#if canImport(SpryMacroAvailable)
import Foundation
import SpryKit
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
        queue.stub(.syncWithExecute).andReturn()

        let subject: DelayedQueue = .sync(queue)
        let didCall = expectation(description: "didCall")
        subject.fire {
            didCall.fulfill()
        }
        wait(for: [didCall], timeout: 0)
        XCTAssertHaveReceived(queue, .syncWithExecute)
    }

    func test_fake_queue_async() {
        let queue: FakeQueueable = .init()
        queue.stub(.asyncWithExecute).andReturn()

        let subject: DelayedQueue = .async(queue)
        let didCall = expectation(description: "didCall")
        subject.fire {
            didCall.fulfill()
        }
        XCTAssertHaveReceived(queue, .asyncWithExecute)

        queue.asyncWorkItem?()
        wait(for: [didCall], timeout: 1)
    }

    func test_fake_queue_async_after() {
        let dispatchTime = DispatchTime.delayInSeconds(1)

        let queue: FakeQueueable = .init()
        queue.stub(.asyncAfterWithDeadline_Flags_Execute).andReturn()

        let subject: DelayedQueue = .asyncAfter(deadline: dispatchTime, queue: queue)
        let didCall = expectation(description: "didCall")
        subject.fire {
            didCall.fulfill()
        }
        XCTAssertHaveReceived(queue, .asyncAfterWithDeadline_Flags_Execute, with: dispatchTime, Queue.Flags.absent, Argument.anything)

        queue.asyncWorkItem?()
        wait(for: [didCall], timeout: 0)
    }

    func test_fake_queue_async_after_with_flags() {
        let dispatchTime = DispatchTime.delayInSeconds(1)

        let queue: FakeQueueable = .init()
        queue.stub(.asyncAfterWithDeadline_Flags_Execute).andReturn()

        let subject: DelayedQueue = .asyncAfterWithFlags(deadline: dispatchTime, flags: .barrier, queue: queue)
        let didCall = expectation(description: "didCall")
        subject.fire {
            didCall.fulfill()
        }
        XCTAssertHaveReceived(queue, .asyncAfterWithDeadline_Flags_Execute, with: dispatchTime, Queue.Flags.barrier, Argument.anything)

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
#endif
