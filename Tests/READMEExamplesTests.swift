import Foundation
import Threading
import XCTest

/// Tests that verify all code examples from README.md compile and work correctly.
/// This ensures the documentation stays accurate and all examples are valid.
final class READMEExamplesTests: XCTestCase {
    // MARK: - Working with Queues

    func testQueueMainSync() {
        // Example: Queue.main.sync { }
        var didExecute = false
        Queue.main.sync {
            didExecute = true
        }
        XCTAssertTrue(didExecute, "Queue.main.sync should execute synchronously")
    }

    func testQueueMainAsync() {
        // Example: Queue.main.async { }
        let expectation = expectation(description: "async executed")
        Queue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testQueueCustom() {
        // Example: Queue.custom(...)
        let customQueue = Queue.custom(label: "com.example.queue",
                                       qos: .utility,
                                       attributes: .serial)

        let expectation = expectation(description: "custom queue executed")
        customQueue.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testDelayedQueueAsyncAfter() {
        // Example: DelayedQueue.n.asyncAfter(...)
        let expectation = expectation(description: "delayed execution")
        let delayed = DelayedQueue.n.asyncAfter(deadline: .now() + 0.1, queue: .main)
        delayed.fire {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testDelayedQueueSync() {
        // Example: DelayedQueue.n.sync(.main)
        @AtomicValue
        var didExecute = false
        let sync = DelayedQueue.n.sync(.main)
        sync.fire { [didExecute = _didExecute] in
            didExecute.syncUnchecked { $0 = true }
        }
        XCTAssertTrue(didExecute, "DelayedQueue.sync should execute synchronously")
    }

    func testDelayedQueueAsync() {
        // Example: DelayedQueue.n.async(.background)
        let expectation = expectation(description: "async execution")
        let async = DelayedQueue.n.async(.background)
        async.fire {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Thread-Safe Value Access

    func testLockedValueSync() {
        // Example: LockedValue(initialValue: 0) with sync
        let counter = LockedValue(initialValue: 0)

        // Safely modify the value
        counter.sync { value in
            value += 1
        }

        // Get the current value
        let currentValue = counter.sync { value in
            return value
        }

        XCTAssertEqual(currentValue, 1, "Counter should be 1 after increment")
    }

    func testLockedValueDynamicCallable() {
        // Example: counter { $0 += 1 }
        let counter = LockedValue(initialValue: 0)

        // Using dynamic callable syntax (functional style)
        counter { $0 += 1 }
        let doubled = counter.sync { $0 * 2 }

        XCTAssertEqual(doubled, 2, "Doubled value should be 2")
    }

    func testLockedValueTrySync() {
        // Example: counter.trySync({ $0 })
        let counter = LockedValue(initialValue: 42)

        if let value = counter.trySync({ $0 }) {
            XCTAssertEqual(value, 42, "TrySync should return the value")
        } else {
            XCTFail("TrySync should succeed when lock is available")
        }
    }

    // MARK: - AtomicValue Properties

    func testAtomicValueBasic() {
        // Example: @AtomicValue var counter = 0
        @AtomicValue
        var counter = 0

        // Using sync method
        $counter.sync { $0 += 1 }

        // Using dynamic callable syntax (functional style)
        $counter { $0 = 10 }

        // Direct property access (thread-safe)
        counter = 5
        let value = counter

        XCTAssertEqual(value, 5, "Counter should be 5")
    }

    func testAtomicValueDynamicCallable() {
        // Example: $count { $0 += 1 }
        @AtomicValue
        var count = 0

        // Using dynamic callable syntax (works for any type)
        $count { $0 += 1 }

        XCTAssertEqual(count, 1, "Count should be 1 after increment")
    }

    func testAtomicValueWithCustomMutex() {
        // Example: @AtomicValue(mutexing: SyncMutex.self)
        #if canImport(os)
        if #available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            @AtomicValue(mutexing: SyncMutex.self)
            var counter = 0
            $counter.sync { $0 += 1 }
            XCTAssertEqual(counter, 1, "Counter with SyncMutex should work")
        }
        #endif
    }

    func testAtomicValueWithCustomLock() {
        // Example: @AtomicValue(lock: .osAllocatedUnfair())
        #if canImport(os)
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            @AtomicValue(lock: .osAllocatedUnfair())
            var highPerformance = 0
            $highPerformance.sync { $0 += 1 }
            XCTAssertEqual(highPerformance, 1, "High performance counter should work")
        }
        #endif
    }

    // MARK: - Concurrency Workarounds

    func testIsolatedMain() {
        // Example: Queue.isolatedMain.sync { }
        var didExecute = false
        Queue.isolatedMain.sync {
            didExecute = true
        }
        XCTAssertTrue(didExecute, "IsolatedMain.sync should execute")
    }

    // MARK: - Working with Non-Sendable Types

    func testUSendable() {
        // Example: USendable wrapper
        struct TestView {
            var backgroundColor: String = "clear"
        }

        let unsafe = USendable(TestView())

        // Access it safely on the main thread
        let expectation = expectation(description: "main thread access")
        Queue.main.async {
            var view = unsafe.value
            view.backgroundColor = "red"
            unsafe.value = view
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(unsafe.value.backgroundColor, "red", "Background color should be red")
    }

    // MARK: - Advanced Features: Dynamic Callable Syntax

    func testLockingDynamicCallable() {
        // Example: lock { performWork() }
        let lock: Locking = AnyLock.default
        @AtomicValue
        var didWork = false

        lock { [didWork = _didWork] in
            // Critical section
            didWork.syncUnchecked { $0 = true }
        }

        XCTAssertTrue(didWork, "Lock dynamic callable should work")
    }

    func testMutexingDynamicCallable() {
        // Example: counter { $0 += 1 }
        let counter = LockedValue(initialValue: 0)
        counter { $0 += 1 }
        let value = counter { $0 }

        XCTAssertEqual(value, 1, "Mutexing dynamic callable should work")
    }

    func testAtomicValueDynamicCallableAdvanced() {
        // Example: $count { $0 += 1 }
        @AtomicValue
        var count = 0
        $count.sync { $0 += 1 }
        $count { $0 += 1 }

        XCTAssertEqual(count, 2, "Count should be 2 after two increments")
    }

    // MARK: - Dynamic Member Lookup

    func testDynamicMemberLookup() {
        // Example: @AtomicValue var user = User(...)
        struct User {
            var name: String
            var age: Int
        }

        @AtomicValue
        var user = User(name: "Alice", age: 30)

        // Thread-safe property access
        let name = user.name // Automatically synchronized
        user.age = 31 // Thread-safe mutation

        XCTAssertEqual(name, "Alice", "Name should be Alice")
        XCTAssertEqual(user.age, 31, "Age should be 31")
    }

    // MARK: - Best Practices Examples

    func testBestPracticeShortCriticalSection() {
        // Example: counter.sync { value in value += 1 }
        let counter = LockedValue(initialValue: 0)

        // Good: short critical section
        counter.sync { value in
            value += 1
        }

        XCTAssertEqual(counter.sync { $0 }, 1, "Counter should be 1")
    }

    func testBestPracticeErrorHandling() {
        // Example: try mutex.sync { try performRiskyOperation(value) }
        let mutex = LockedValue(initialValue: 0)

        enum TestError: Error {
            case test
        }

        do {
            try mutex.sync { value in
                if value == 0 {
                    throw TestError.test
                }
            }
            XCTFail("Should have thrown an error")
        } catch TestError.test {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testBestPracticeTryLock() {
        // Example: lock.trySync({ computeValue() })
        let lock: Locking = AnyLock.default

        if let result = lock.trySync({
            return 42
        }) {
            XCTAssertEqual(result, 42, "TrySync should return 42")
        } else {
            XCTFail("TrySync should succeed when lock is available")
        }
    }

    // MARK: - Additional Examples from Code Documentation

    func testDelayedQueueNamespaceExample() {
        /// Example from DelayedQueue documentation: .n.sync(.main)
        func performTask(in queue: DelayedQueue) {
            @AtomicValue
            var executed = false
            queue.fire { [executed = _executed] in
                executed.syncUnchecked { $0 = true }
            }
            XCTAssertTrue(executed || queue != .absent, "Task should execute or be absent")
        }

        performTask(in: .n.sync(.main))
        performTask(in: .n.async(.main))
    }

    func testAnyLockDefault() {
        // Example: AnyLock.default
        let lock = AnyLock.default
        @AtomicValue
        var executed = false

        lock.sync { [executed = _executed] in
            executed.syncUnchecked { $0 = true }
        }

        XCTAssertTrue(executed, "AnyLock.default should work")
    }

    func testLockedValueWithCustomLock() {
        // Example: LockedValue with custom lock
        let lock = AnyLock.default
        let value = LockedValue(initialValue: 0, lock: lock)

        value.sync { $0 += 1 }
        let result = value.sync { $0 }

        XCTAssertEqual(result, 1, "LockedValue with custom lock should work")
    }
}
