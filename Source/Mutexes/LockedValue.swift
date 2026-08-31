import Foundation

/// A thread-safe container that protects access to a value using a locking mechanism.
///
/// `LockedValue` provides synchronized access to a mutable value through a lock conforming to `Locking`.
/// It supports both blocking and non-blocking synchronization strategies and is useful when low-level
/// control over concurrency is required.
///
/// This type is ideal for use cases involving shared mutable state accessed from multiple threads.
///
/// - Note: The generic `Value` must conform to `Sendable` to safely use this type in concurrent contexts.
///
/// ## Example
/// ```swift
/// let locked = LockedValue(initialValue: 0)
/// locked.sync { $0 += 1 }
/// let value = locked.sync { $0 }
/// print(value) // 1
/// ```
public final class LockedValue<Value> {
    private let locker: Locking

    private var value: Value

    /// Creates a locked value using the specified initial value and locking mechanism.
    ///
    /// - Parameters:
    ///   - value: The initial value to protect.
    ///   - lock: An instance conforming to `Locking`, used to coordinate access.
    public required init(initialValue value: Value, lock: Locking) {
        self.locker = lock
        self.value = value
    }

    /// Creates a locked value initialized to `nil`.
    ///
    /// - Parameter lock: The lock used to synchronize access to the value.
    public convenience init(lock: Locking) where Value: ExpressibleByNilLiteral {
        self.init(initialValue: nil, lock: lock)
    }

    /// Creates a locked value initialized to an empty array.
    ///
    /// - Parameter lock: The lock used to synchronize access to the value.
    public convenience init(lock: Locking) where Value: ExpressibleByArrayLiteral {
        self.init(initialValue: [], lock: lock)
    }

    /// Creates a locked value initialized to an empty dictionary.
    ///
    /// - Parameter lock: The lock used to synchronize access to the value.
    public convenience init(lock: Locking) where Value: ExpressibleByDictionaryLiteral {
        self.init(initialValue: [:], lock: lock)
    }
}

extension LockedValue: MutexInitializable {
    /// Creates a locked value with a default recursive pthread lock.
    ///
    /// - Parameter initialValue: The initial value to protect.
    public convenience init(initialValue value: Value) {
        self.init(initialValue: value, lock: AnyLock.pthread(.recursive))
    }
}

extension LockedValue: Mutexing {
    /// Performs a thread-safe, blocking mutation without requiring the closure to be `Sendable`.
    ///
    /// - Parameter body: A non-Sendable closure that receives an `inout` reference to the value.
    /// - Returns: The result of the closure.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ## Example
    /// ```swift
    /// let locked = LockedValue(initialValue: "abc")
    /// locked.syncUnchecked { $0 += "def" }
    /// ```
    public func syncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R {
        return try locker.syncUnchecked {
            return try body(&value)
        }
    }

    /// Attempts a non-blocking mutation without requiring the closure to be `Sendable`.
    ///
    /// - Parameter body: A non-Sendable closure that receives an `inout` reference to the value.
    /// - Returns: The result of the closure if the lock was acquired; otherwise, `nil`.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ## Example
    /// ```swift
    /// let locked = LockedValue(initialValue: "value")
    /// let result = locked.trySyncUnchecked { $0 += " updated"; return $0 }
    /// ```
    public func trySyncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R? {
        return try locker.trySyncUnchecked {
            return try body(&value)
        }
    }
}

extension LockedValue: @unchecked Sendable {}
