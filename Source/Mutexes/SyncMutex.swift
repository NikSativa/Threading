#if canImport(Synchronization) && supportsVisionOS && compiler(>=6.0)
import Foundation
import Synchronization

/// A thread-safe container that synchronizes access to a value using the system’s native mutex.
///
/// `SyncMutex` wraps a `Synchronization.Mutex` to ensure mutually exclusive access to a mutable value.
/// It supports recursive locking, priority inheritance, and low-latency performance, making it ideal
/// for highly concurrent, performance-sensitive applications.
///
/// ### Example
/// ```swift
/// let counter = SyncMutex(initialValue: 0)
/// counter.sync { $0 += 1 }
/// print(counter.sync { $0 }) // 1
/// ```
///
/// > Important: Available on platforms that support the `Synchronization` module and Swift 6 or later.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public final class SyncMutex<Value: Sendable> {
    /// The underlying system mutex used to synchronize access to the protected value.
    ///
    /// This mutex supports recursive locking and priority inheritance, and is managed automatically by the system.
    ///
    /// You can access it directly if lower-level control is needed.
    ///
    /// ### Example
    /// ```swift
    /// let wrapper = SyncMutex(initialValue: 42)
    /// let rawMutex = wrapper.mutex
    /// ```
    public let mutex: Synchronization.Mutex<Value>

    /// Creates a mutex-protected container with the specified initial value.
    ///
    /// - Parameter value: The initial value to be protected by the system mutex.
    public required init(initialValue value: Value) {
        self.mutex = .init(value)
    }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension SyncMutex: MutexInitializable {}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension SyncMutex: Mutexing {
    /// Executes a closure while holding the lock, providing synchronized access to the protected value.
    ///
    /// - Parameter body: A `@Sendable` closure that receives an inout reference to the protected value.
    /// - Returns: The result of the closure.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let mutex = SyncMutex(initialValue: [Int]())
    /// mutex.sync { $0.append(1) }
    /// ```
    public func sync<R>(_ body: @Sendable (inout Value) throws -> R) rethrows -> R
    where R: Sendable, Value: Sendable {
        return try mutex.withLock { value in
            return try body(&value)
        }
    }

    /// Attempts to execute a closure if the lock is immediately available.
    ///
    /// - Parameter body: A `@Sendable` closure that receives an inout reference to the protected value.
    /// - Returns: The result of the closure, or `nil` if the lock could not be acquired.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let mutex = SyncMutex(initialValue: "Hello")
    /// if let result = mutex.trySync({ $0.append(" World") }) {
    ///     print(result) // "Hello World"
    /// }
    /// ```
    public func trySync<R>(_ body: @Sendable (inout Value) throws -> R) rethrows -> R?
    where R: Sendable, Value: Sendable {
        return try mutex.withLockIfAvailable { value in
            return try body(&value)
        }
    }

    /// Executes a non-Sendable closure while holding the lock, providing synchronized access to the protected value.
    ///
    /// - Parameter body: A closure that receives an inout reference to the protected value.
    /// - Returns: The result of the closure.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let mutex = SyncMutex(initialValue: 10)
    /// mutex.syncUnchecked { $0 += 5 }
    /// ```
    public func syncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R {
        return try mutex.withLock { value in
            return try body(&value)
        }
    }

    /// Attempts to execute a non-Sendable closure if the lock is immediately available.
    ///
    /// - Parameter body: A closure that receives an inout reference to the protected value.
    /// - Returns: The result of the closure, or `nil` if the lock could not be acquired.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let mutex = SyncMutex(initialValue: "abc")
    /// _ = mutex.trySyncUnchecked { $0 += "123" }
    /// ```
    public func trySyncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R? {
        return try mutex.withLockIfAvailable { value in
            return try body(&value)
        }
    }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension QueueBarrier: @unchecked Sendable {}
#endif
