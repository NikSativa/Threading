import Foundation

/// A thread-safe container that synchronizes access to a value using a dispatch queue barrier.
///
/// `QueueBarrier` uses a `DispatchQueue` with barrier flags to guarantee exclusive access during mutations,
/// while allowing concurrent reads on a concurrent queue. It is well-suited for GCD-based concurrency models.
///
/// ### Example
/// ```swift
/// let counter = QueueBarrier(initialValue: 0)
/// counter.sync { $0 += 1 }
/// let value = counter.sync { $0 }
/// ```
public final class QueueBarrier<Value> {
    private var value: Value
    private let queue: Queueable

    /// Creates a thread-safe container using the provided initial value and dispatch queue.
    ///
    /// - Parameters:
    ///   - value: The initial value to protect.
    ///   - queue: A dispatch queue that synchronizes access using `.barrier` flags.
    ///
    /// ### Example
    /// ```swift
    /// let customQueue = DispatchQueue(label: "com.example.queue", attributes: .concurrent)
    /// let barrier = QueueBarrier(initialValue: 42, queue: customQueue)
    /// ```
    public required init(initialValue value: Value, queue: Queueable) {
        self.queue = queue
        self.value = value
    }

    /// Creates a container initialized to `nil`.
    ///
    /// - Parameter queue: The dispatch queue used for synchronization.
    public convenience init(queue: Queueable) where Value: ExpressibleByNilLiteral {
        self.init(initialValue: nil, queue: queue)
    }

    /// Creates a container initialized to an empty array.
    ///
    /// - Parameter queue: The dispatch queue used for synchronization.
    ///
    /// ### Example
    /// ```swift
    /// let queue = DispatchQueue(label: "array.queue", attributes: .concurrent)
    /// let arrayContainer = QueueBarrier<[Int]>(queue: queue)
    /// ```
    public convenience init(queue: Queueable) where Value: ExpressibleByArrayLiteral {
        self.init(initialValue: [], queue: queue)
    }

    /// Creates a container initialized to an empty dictionary.
    ///
    /// - Parameter queue: The dispatch queue used for synchronization.
    ///
    /// ### Example
    /// ```swift
    /// let queue = DispatchQueue(label: "dict.queue", attributes: .concurrent)
    /// let dictContainer = QueueBarrier<[String: Int]>(queue: queue)
    /// ```
    public convenience init(queue: Queueable) where Value: ExpressibleByDictionaryLiteral {
        self.init(initialValue: [:], queue: queue)
    }
}

extension QueueBarrier: MutexInitializable {
    /// Creates a thread-safe container using a new serial dispatch queue.
    ///
    /// - Parameter value: The initial value to protect.
    ///
    /// ### Example
    /// ```swift
    /// let barrier = QueueBarrier(initialValue: "Hello")
    /// ```
    public convenience init(initialValue value: Value) {
        self.init(initialValue: value, queue: Queue.custom(label: "Barrier_\(UUID())", attributes: .serial))
    }
}

extension QueueBarrier: Mutexing {
    /// Executes a closure that reads or mutates the protected value synchronously.
    ///
    /// - Parameter body: A closure that receives an inout reference to the value.
    /// - Returns: The result of the closure.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let barrier = QueueBarrier(initialValue: 10)
    /// let doubled = barrier.sync { value in
    ///     value *= 2
    ///     return value
    /// }
    /// ```
    public func sync<R>(_ body: @Sendable (inout Value) throws -> R) rethrows -> R
    where R: Sendable, Value: Sendable {
        return try queue.sync(flags: .barrier) {
            return try body(&value)
        }
    }

    /// Executes a closure conditionally if the queue is available without blocking.
    ///
    /// - Parameter body: A closure that receives an inout reference to the value.
    /// - Returns: The result of the closure, or `nil` if the operation couldn't proceed.
    /// - Throws: Any error thrown by the closure.
    public func trySync<R>(_ body: @Sendable (inout Value) throws -> R) rethrows -> R?
    where R: Sendable, Value: Sendable {
        return try queue.sync(flags: .barrier) {
            return try body(&value)
        }
    }

    /// Executes a non-Sendable closure that reads or mutates the protected value.
    ///
    /// - Parameter body: A non-Sendable closure that receives an inout reference to the value.
    /// - Returns: The result of the closure.
    /// - Throws: Any error thrown by the closure.
    public func syncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R {
        return try queue.sync(flags: .barrier) {
            return try body(&value)
        }
    }

    /// Executes a non-Sendable closure conditionally if the queue is available.
    ///
    /// - Parameter body: A non-Sendable closure that receives an inout reference to the value.
    /// - Returns: The result of the closure, or `nil` if the operation couldn't proceed.
    /// - Throws: Any error thrown by the closure.
    public func trySyncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R? {
        return try queue.sync(flags: .barrier) {
            return try body(&value)
        }
    }
}

extension QueueBarrier: @unchecked Sendable {}
