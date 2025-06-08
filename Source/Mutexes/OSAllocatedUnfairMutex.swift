#if canImport(os)
import Foundation
import os

/// A thread-safe container that synchronizes access to a value using the system's unfair lock.
///
/// `OSAllocatedUnfairMutex` wraps a mutable value in an `os.OSAllocatedUnfairLock`, providing
/// fast, low-overhead synchronization without fairness or recursion guarantees. It is suitable
/// for performance-critical use cases with low contention and no need for recursive locking.
///
/// > Important: This lock is non-recursive. Attempting to acquire it recursively will result in a deadlock.
///
/// ### Example
/// ```swift
/// let mutex = OSAllocatedUnfairMutex(initialValue: 0)
/// mutex.sync { $0 += 1 }
/// let value = mutex.sync { $0 }
/// print(value) // 1
/// ```
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public struct OSAllocatedUnfairMutex<Value> {
    /// The system-provided unfair lock that guards the underlying value.
    ///
    /// Use `mutex` directly if you need low-level access to locking functionality.
    public let mutex: os.OSAllocatedUnfairLock<Value>
}

/// Conforms to `MutexInitializable`, enabling creation of a mutex-backed container with an initial value.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension OSAllocatedUnfairMutex: MutexInitializable {
    /// Creates a new mutex-protected container with the specified initial value.
    ///
    /// - Parameter initialValue: The value to protect with the system-managed unfair lock.
    ///
    /// ### Example
    /// ```swift
    /// let mutex = OSAllocatedUnfairMutex(initialValue: "Initial")
    /// ```
    public init(initialValue value: Value) {
        self.mutex = .init(uncheckedState: value)
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension OSAllocatedUnfairMutex: Mutexing {
    /// Executes a closure while holding the lock, blocking the thread until access is granted.
    ///
    /// - Parameter body: A closure that receives a mutable reference to the protected value.
    /// - Returns: The result produced by the closure.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let mutex = OSAllocatedUnfairMutex(initialValue: [1, 2, 3])
    /// mutex.sync { $0.append(4) }
    /// ```
    public func sync<R>(_ body: @Sendable (inout Value) throws -> R) rethrows -> R
    where R: Sendable, Value: Sendable {
        return try mutex.withLock { value in
            return try body(&value)
        }
    }

    /// Attempts to execute a closure while holding the lock, only if the lock can be immediately acquired.
    ///
    /// - Parameter body: A closure that receives a mutable reference to the protected value.
    /// - Returns: The result from the closure if the lock was acquired; otherwise, `nil`.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let result = mutex.trySync { value in
    ///     value += 1
    ///     return value
    /// }
    /// ```
    public func trySync<R>(_ body: @Sendable (inout Value) throws -> R) rethrows -> R?
    where R: Sendable, Value: Sendable {
        return try mutex.withLockIfAvailable { value in
            return try body(&value)
        }
    }

    /// Executes a closure while holding the lock without requiring the closure to be `Sendable`.
    ///
    /// - Parameter body: A non-Sendable closure that receives a mutable reference to the protected value.
    /// - Returns: The result from the closure.
    /// - Throws: Any error thrown by the closure.
    public func syncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R {
        return try mutex.withLockUnchecked { value in
            return try body(&value)
        }
    }

    /// Attempts to execute a non-Sendable closure while holding the lock, if the lock is available.
    ///
    /// - Parameter body: A non-Sendable closure that receives a mutable reference to the protected value.
    /// - Returns: The result from the closure if the lock was acquired; otherwise, `nil`.
    /// - Throws: Any error thrown by the closure.
    public func trySyncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R? {
        return try mutex.withLockIfAvailableUnchecked { value in
            return try body(&value)
        }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension OSAllocatedUnfairMutex: @unchecked Sendable {}
#endif
