import XCTest
@testable import Threading

final class AtomicTests: XCTestCase {
    func test_init_with_locking_default() {
        @AtomicValue
        var counter: MySendable = 42
        XCTAssertEqual(counter.counter, 42)

        @AtomicValue
        var collector: [MySendable] = []
        concurrent_access(counter: _counter, collector: _collector)
    }

    #if canImport(os)
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func test_init_with_locking_osAllocatedUnfairLock() {
        @AtomicValue(lock: .osAllocatedUnfair())
        var counter: MySendable = 42
        XCTAssertEqual(counter.counter, 42)

        @AtomicValue(lock: .osAllocatedUnfair())
        var collector: [MySendable] = []
        concurrent_access(counter: _counter, collector: _collector)
    }
    #endif

    func test_init_with_locking_pthread() {
        @AtomicValue(lock: .pthread(.recursive))
        var counter: MySendable = 42
        XCTAssertEqual(counter.counter, 42)

        @AtomicValue(lock: .pthread(.recursive))
        var collector: [MySendable] = []
        concurrent_access(counter: _counter, collector: _collector)
    }

    func test_init_with_locking_semaphore() {
        @AtomicValue(lock: .semaphore())
        var counter: MySendable = 42
        XCTAssertEqual(counter.counter, 42)

        @AtomicValue(lock: .semaphore())
        var collector: [MySendable] = []
        concurrent_access(counter: _counter, collector: _collector)
    }

    func test_init_with_locking_unfair() {
        @AtomicValue(lock: .unfair())
        var counter: MySendable = 42
        XCTAssertEqual(counter.counter, 42)

        @AtomicValue(lock: .unfair())
        var collector: [MySendable] = []
        concurrent_access(counter: _counter, collector: _collector)
    }

    func test_init_with_locking_recursiveLock() {
        @AtomicValue(lock: .recursiveLock())
        var counter: MySendable = 42
        XCTAssertEqual(counter.counter, 42)

        @AtomicValue(lock: .recursiveLock())
        var collector: [MySendable] = []
        concurrent_access(counter: _counter, collector: _collector)
    }

    func test_init_with_locking_lock() {
        @AtomicValue(lock: .lock())
        var counter: MySendable = 42
        XCTAssertEqual(counter.counter, 42)

        @AtomicValue(lock: .lock())
        var collector: [MySendable] = []
        concurrent_access(counter: _counter, collector: _collector)
    }

    #if canImport(os)
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func test_init_with_mutexing_osAllocatedUnfairMutex() {
        @AtomicValue(mutex: .osAllocatedUnfair(initialValue: 42))
        var counter: MySendable
        XCTAssertEqual(counter.counter, 42)

        @AtomicValue(mutex: .osAllocatedUnfair())
        var collector: [MySendable]
        concurrent_access(counter: _counter, collector: _collector)
    }
    #endif

    func test_init_with_mutexing_locking() {
        @AtomicValue(mutex: .lock(initialValue: 42, .default))
        var counter: MySendable
        XCTAssertEqual(counter.counter, 42)

        @AtomicValue(mutex: .lock())
        var collector: [MySendable]
        concurrent_access(counter: _counter, collector: _collector)
    }

    func test_init_with_mutexing_queueBarrier() {
        @AtomicValue(mutex: .queueBarrier(initialValue: 42))
        var counter: MySendable
        XCTAssertEqual(counter.counter, 42)

        @AtomicValue(mutex: .queueBarrier())
        var collector: [MySendable]
        concurrent_access(counter: _counter, collector: _collector)
    }

    #if canImport(Synchronization) && supportsVisionOS && compiler(>=6.0)
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    func test_init_with_mutexing_syncMutex() {
        @AtomicValue(mutex: .syncMutex(initialValue: 42))
        var counter: MySendable
        XCTAssertEqual(counter.counter, 42)

        @AtomicValue(mutex: .syncMutex())
        var collector: [MySendable]
        concurrent_access(counter: _counter, collector: _collector)
    }

    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    func testCustomMutex() {
        @AtomicValue(mutexing: SyncMutex.self)
        var counter: MySendable = 0
        $counter.sync { $0.counter += 1 }
        XCTAssertEqual(counter.counter, 1)

        @AtomicValue(mutexing: SyncMutex.self)
        var collector: [MySendable] = []
        concurrent_access(counter: _counter, collector: _collector)
    }
    #endif

    func testValueMutation() {
        @AtomicValue
        var counter: MySendable = 0
        counter = 1
        XCTAssertEqual(counter.counter, 1)

        $counter { $0 = 10 }
        XCTAssertEqual(counter.counter, 10)

        @AtomicValue
        var collector: [MySendable] = []
        concurrent_access(counter: _counter, collector: _collector)
    }

    func testConcurrentAccess() {
        @AtomicValue
        var counter: MySendable = 0
        @AtomicValue
        var collector: [MySendable] = []

        let iterations = 1000
        let concurrentQueue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        let group = DispatchGroup()
        for idx in 0..<iterations {
            group.enter()
            concurrentQueue.async { [_counter, _collector] in
                _counter.syncUnchecked { $0.counter += 1 }
                _collector.syncUnchecked { $0.append(.init(integerLiteral: idx)) }
                group.leave()
            }
        }

        group.wait()
        XCTAssertEqual(counter.counter, iterations)
        XCTAssertEqual(collector.count, iterations)
    }
}

@inline(__always)
private func concurrent_access(counter: AtomicValue<MySendable>,
                               collector: AtomicValue<[MySendable]>,
                               file: StaticString = #filePath,
                               line: UInt = #line) {
    counter.syncUnchecked { $0.counter = 0 }
    collector.syncUnchecked { $0 = [] }

    let iterations = 1000
    let concurrentQueue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
    let group = DispatchGroup()
    for idx in 0..<iterations {
        group.enter()
        concurrentQueue.async { [counter, collector] in
            counter.syncUnchecked { $0.counter += 1 }
            collector.syncUnchecked { $0.append(.init(integerLiteral: idx)) }
            group.leave()
        }
    }
    group.wait()
    XCTAssertEqual(counter.wrappedValue.counter, iterations, file: file, line: line)
    XCTAssertEqual(collector.count, iterations, file: file, line: line)
}

private struct MySendable: Sendable, ExpressibleByIntegerLiteral {
    var counter: Int = 0

    init(integerLiteral value: IntegerLiteralType) {
        self.counter = value
    }
}
