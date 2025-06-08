import Foundation

/// A protocol that defines mutual exclusion behavior using locking primitives.
///
/// Types conforming to `Locking` provide thread-safe synchronization mechanisms, allowing exclusive access
/// to critical sections of code. The protocol includes basic locking operations as well as utility methods
/// for safely executing closures within a locked context.
///
/// Conforming types may support recursive locking or other custom behaviors.
///
/// > Note: On Swift 6 and later, `Locking` conforms to `Sendable`.
///
/// ### Example
/// ```swift
/// final class Counter {
///     private var value = 0
///     private let lock: Locking = AnyLock.default
///
///     func increment() {
///         lock.sync { value += 1 }
///     }
/// }
/// ```
@dynamicCallable
public protocol Locking: Sendable {
    /// Acquires the lock, blocking the calling thread until it becomes available.
    ///
    /// This method will block the calling thread if the lock is currently held by another thread.
    /// The thread will remain blocked until the lock becomes available and is acquired.
    ///
    /// - Note: The behavior when attempting to acquire a lock that is already held by the
    ///         current thread depends on the specific implementation. Some implementations
    ///         support recursive locking, while others may deadlock.
    func lock()

    /// Attempts to acquire the lock without blocking.
    ///
    /// This method provides a non-blocking way to acquire the lock. It returns immediately
    /// with a boolean value indicating whether the lock was successfully acquired.
    ///
    /// - Returns: `true` if the lock was successfully acquired, `false` if the lock
    ///            is currently held by another thread.
    /// - Note: The behavior when attempting to acquire a lock that is already held by the
    ///         current thread depends on the specific implementation. Some implementations
    ///         may return `true` for recursive locking, while others may return `false`.
    func tryLock() -> Bool

    /// Releases the lock, allowing other threads to acquire it.
    ///
    /// This method should only be called by the thread that currently holds the lock.
    /// Calling this method when the lock is not held may result in undefined behavior.
    ///
    /// - Note: For recursive locks, each `lock()` call must be matched with an `unlock()`
    ///         call. The lock is only released when the number of unlocks matches the
    ///         number of locks.
    func unlock()
}

public extension Locking {
    /// Executes a closure while holding the lock.
    ///
    /// Acquires the lock, executes the closure, and then releases the lock. This method ensures
    /// that the lock is always released, even if an error is thrown.
    ///
    /// - Parameter work: A `Sendable` closure to execute.
    /// - Returns: The value returned by the closure.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let value = lock.sync {
    ///     return computeValue()
    /// }
    /// ```
    @discardableResult
    func sync<R: Sendable>(_ work: @Sendable () throws -> R) rethrows -> R {
        lock()
        defer {
            unlock()
        }

        return try work()
    }

    /// Attempts to execute a closure while holding the lock.
    ///
    /// Tries to acquire the lock without blocking. If successful, the closure is executed and
    /// its result returned. Otherwise, `nil` is returned.
    ///
    /// - Parameter work: A `Sendable` closure to execute.
    /// - Returns: The result of the closure if the lock was acquired; otherwise, `nil`.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// if let value = lock.trySync({ computeValue() }) {
    ///     print("Result:", value)
    /// }
    /// ```
    @discardableResult
    func trySync<R: Sendable>(_ work: @Sendable () throws -> R) rethrows -> R? {
        guard tryLock() else {
            return nil
        }

        defer {
            unlock()
        }

        return try work()
    }

    /// Executes a non-Sendable closure while holding the lock.
    ///
    /// Acquires the lock, executes the closure, and releases the lock afterward.
    ///
    /// - Parameter work: A non-`Sendable` closure to execute.
    /// - Returns: The result of the closure.
    /// - Throws: Any error thrown by the closure.
    ///
    /// > Important: This method bypasses `Sendable` checking and should be used with caution.
    ///
    /// ### Example
    /// ```swift
    /// let result = lock.syncUnchecked {
    ///     complexNonSendableOperation()
    /// }
    /// ```
    @discardableResult
    func syncUnchecked<R>(_ work: () throws -> R) rethrows -> R {
        lock()
        defer {
            unlock()
        }

        return try work()
    }

    /// Attempts to execute a non-Sendable closure while holding the lock.
    ///
    /// Tries to acquire the lock without blocking. If successful, the closure is executed
    /// and its result returned. Otherwise, `nil` is returned.
    ///
    /// - Parameter work: A non-`Sendable` closure to execute.
    /// - Returns: The result of the closure if the lock was acquired; otherwise, `nil`.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let result = lock.trySyncUnchecked {
    ///     nonSendableComputation()
    /// }
    /// ```
    @discardableResult
    func trySyncUnchecked<R>(_ work: () throws -> R) rethrows -> R? {
        guard tryLock() else {
            return nil
        }

        defer {
            unlock()
        }

        return try work()
    }
}

// MARK: - @dynamicCallable

public extension Locking {
    /// Dynamically calls the lock with a `Sendable` throwing closure.
    ///
    /// Allows use of dynamic call syntax for locking. Only the first closure is executed.
    ///
    /// - Parameter args: An array of `Sendable` throwing closures.
    /// - Returns: The result of the closure, or `nil` if the array is empty.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let result = try lock {
    ///     return "locked value"
    /// }
    /// ```
    func dynamicallyCall(withArguments args: [@Sendable () throws -> Sendable]) throws -> Sendable? {
        guard let body = args.first else {
            return nil
        }

        return try sync(body)
    }

    /// Dynamically calls the lock with a `Sendable` non-throwing closure.
    ///
    /// Allows use of dynamic call syntax for locking. Only the first closure is executed.
    ///
    /// - Parameter args: An array of `Sendable` closures.
    /// - Returns: The result of the closure, or `nil` if the array is empty.
    ///
    /// ### Example
    /// ```swift
    /// let result = lock {
    ///     return "safe access"
    /// }
    /// ```
    func dynamicallyCall(withArguments args: [@Sendable () -> Sendable]) -> Sendable? {
        guard let body = args.first else {
            return nil
        }

        return sync(body)
    }
}
