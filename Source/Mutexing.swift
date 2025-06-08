import Foundation

/// A protocol that provides synchronized, thread-safe access to a mutable value.
///
/// Types conforming to `Mutexing` protect an underlying value using mutual-exclusion
/// mechanisms, enabling safe concurrent access. This includes support for both
/// blocking and non-blocking mutations, error propagation, and property access via key paths.
///
/// Use `sync(_:)` to execute a closure with exclusive access to the protected value. Use
/// `trySync(_:)` for non-blocking access attempts.
///
/// The `Mutexing` protocol also supports dynamic member lookup and dynamic callable behavior.
/// This allows for convenient dot-syntax access to properties and the ability to invoke the mutex instance
/// like a function, passing closures that operate on the protected value.
///
/// ## Example
/// ```swift
/// let counter = LockedValue(initialValue: 0)
///
/// counter.sync { $0 += 1 }
/// let value = counter.sync { $0 }
///
/// if let doubled = counter.trySync({ $0 * 2 }) {
///     print("Doubled:", doubled)
/// }
/// ```
@dynamicMemberLookup
@dynamicCallable
public protocol Mutexing<Value> {
    /// The type of value protected by the mutex.
    ///
    /// This associated type defines the type of value that is protected by the mutex.
    /// The value type must conform to `Sendable` to ensure thread safety.
    associatedtype Value

    /// Executes a closure with exclusive access to the protected value.
    ///
    /// This method blocks the calling thread until the lock is acquired, then passes
    /// the value to the closure for safe mutation or inspection.
    ///
    /// - Parameter body: A closure that receives `inout` access to the protected value.
    /// - Returns: The value returned by the closure.
    /// - Throws: Any error thrown by the closure.
    @discardableResult
    func sync<R, V>(_ body: @Sendable (inout V) throws -> R) rethrows -> R
        where R: Sendable, V: Sendable, V == Value

    /// Attempts to execute a closure with exclusive access to the protected value without blocking.
    ///
    /// This method tries to acquire the lock. If successful, the closure is executed with
    /// mutable access to the value. If the lock cannot be immediately acquired, `nil` is returned.
    ///
    /// - Parameter body: A closure that receives `inout` access to the protected value.
    /// - Returns: The result from the closure, or `nil` if the lock was not available.
    /// - Throws: Any error thrown by the closure.
    @discardableResult
    func trySync<R, V>(_ body: @Sendable (inout V) throws -> R) rethrows -> R?
        where R: Sendable, V: Sendable, V == Value

    /// Executes a closure with exclusive access to the protected value.
    ///
    /// This method blocks the calling thread until the lock is acquired, then passes
    /// the value to the closure for safe mutation or inspection.
    ///
    /// - Parameter body: A closure that receives `inout` access to the protected value.
    /// - Returns: The value returned by the closure.
    /// - Throws: Any error thrown by the closure.
    @discardableResult
    func syncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R

    /// Attempts to execute a closure with exclusive access to the protected value without blocking.
    ///
    /// This method tries to acquire the lock. If successful, the closure is executed with
    /// mutable access to the value. If the lock cannot be immediately acquired, `nil` is returned.
    ///
    /// - Parameter body: A closure that receives `inout` access to the protected value.
    /// - Returns: The result from the closure, or `nil` if the lock was not available.
    /// - Throws: Any error thrown by the closure.
    @discardableResult
    func trySyncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R?
}

public extension Mutexing where Value: Sendable {
    /// Executes a closure while holding the lock, without accessing the protected value.
    ///
    /// This is a convenience method when mutation or reading of the value is not needed,
    /// but mutual exclusion is still required to perform some side-effect.
    ///
    /// - Parameter work: A closure to execute within the lock.
    /// - Returns: The result of the closure.
    /// - Throws: Any error thrown by the closure.
    @discardableResult
    func sync<R: Sendable>(_ work: @Sendable () throws -> R) rethrows -> R {
        return try sync { _ in
            return try work()
        }
    }

    /// Attempts to execute a closure while holding the lock, without accessing the protected value.
    ///
    /// If the lock can be acquired immediately, the closure is executed. Otherwise, returns `nil`.
    ///
    /// - Parameter work: A closure to execute.
    /// - Returns: The result of the closure, or `nil` if the lock could not be acquired.
    /// - Throws: Any error thrown by the closure.
    @discardableResult
    func trySync<R: Sendable>(_ work: @Sendable () throws -> R) rethrows -> R? {
        return try trySync { _ in
            return try work()
        }
    }
}

public extension Mutexing {
    /// Executes a closure while holding the lock, without accessing the protected value.
    ///
    /// This is a convenience method when mutation or reading of the value is not needed,
    /// but mutual exclusion is still required to perform some side-effect.
    ///
    /// - Parameter work: A closure to execute within the lock.
    /// - Returns: The result of the closure.
    /// - Throws: Any error thrown by the closure.
    @discardableResult
    func syncUnchecked<R>(_ work: () throws -> R) rethrows -> R {
        return try syncUnchecked { _ in
            return try work()
        }
    }

    /// Attempts to execute a closure while holding the lock, without accessing the protected value.
    ///
    /// If the lock can be acquired immediately, the closure is executed. Otherwise, returns `nil`.
    ///
    /// - Parameter work: A closure to execute.
    /// - Returns: The result of the closure, or `nil` if the lock could not be acquired.
    /// - Throws: Any error thrown by the closure.
    @discardableResult
    func trySyncUnchecked<R>(_ work: () throws -> R) rethrows -> R? {
        return try trySyncUnchecked { _ in
            return try work()
        }
    }
}

// MARK: - @dynamicMemberLookup

public extension Mutexing where Value: Sendable {
    subscript<T: Sendable>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
        let usendable = USendable(keyPath)
        return sync { [usendable] in
            return $0[keyPath: usendable.value]
        }
    }
}

public extension Mutexing {
    subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
        return syncUnchecked {
            return $0[keyPath: keyPath]
        }
    }
}

// MARK: - @dynamicCallable

public extension Mutexing where Value: Sendable {
    /// Dynamically calls the mutex with a throwing closure that receives `inout` access to the protected value.
    ///
    /// Enables functional-style access to the protected value. Only the first closure is executed.
    ///
    /// - Parameter args: An array of throwing closures.
    /// - Returns: The result of the first closure if available; otherwise, `nil`.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let result = try mutex { value in
    ///     value += 1
    ///     return value
    /// }
    /// ```
    @discardableResult
    func dynamicallyCall(withArguments args: [@Sendable (inout Value) throws -> Sendable]) throws -> Sendable? {
        guard let body = args.first else {
            return nil
        }

        return try sync(body)
    }

    /// Dynamically calls the mutex with a throwing closure that does not access the protected value.
    ///
    /// Enables simplified functional-style syntax when the protected value is not required.
    ///
    /// - Parameter args: An array of throwing closures.
    /// - Returns: The result of the first closure if available; otherwise, `nil`.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let result = try mutex {
    ///     print("Safe execution")
    ///     return "done"
    /// }
    /// ```
    @discardableResult
    func dynamicallyCall(withArguments args: [@Sendable () throws -> Sendable]) throws -> Sendable? {
        guard let body = args.first else {
            return nil
        }

        return try sync(body)
    }

    /// Dynamically calls the mutex with a non-throwing closure that receives `inout` access to the protected value.
    ///
    /// Only the first closure is executed, providing thread-safe mutation or reading of the value.
    ///
    /// - Parameter args: An array of closures.
    /// - Returns: The result of the first closure if available; otherwise, `nil`.
    ///
    /// ### Example
    /// ```swift
    /// let result = mutex { value in
    ///     value *= 2
    ///     return value
    /// }
    /// ```
    @discardableResult
    func dynamicallyCall(withArguments args: [@Sendable (inout Value) -> Sendable]) -> Sendable? {
        guard let body = args.first else {
            return nil
        }

        return sync(body)
    }

    /// Dynamically calls the mutex with a non-throwing closure that does not access the protected value.
    ///
    /// Useful for scoped, thread-safe operations that do not involve the value.
    ///
    /// - Parameter args: An array of closures.
    /// - Returns: The result of the first closure if available; otherwise, `nil`.
    ///
    /// ### Example
    /// ```swift
    /// let result = mutex {
    ///     print("Critical section")
    ///     return "ok"
    /// }
    /// ```
    @discardableResult
    func dynamicallyCall(withArguments args: [@Sendable () -> Sendable]) -> Sendable? {
        guard let body = args.first else {
            return nil
        }

        return sync(body)
    }
}

public extension Mutexing {
    /// Dynamically calls the mutex with a throwing closure that receives `inout` access to the protected value (unchecked).
    ///
    /// Bypasses `Sendable` checking. Use only when `Value` does not conform to `Sendable`.
    ///
    /// - Parameter args: An array of throwing closures.
    /// - Returns: The result of the first closure if available; otherwise, `nil`.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let result = try mutex { value in
    ///     value.append("item")
    ///     return value
    /// }
    /// ```
    @discardableResult
    func dynamicallyCall<R>(withArguments args: [(inout Value) throws -> R]) throws -> R? {
        guard let body = args.first else {
            return nil
        }

        return try syncUnchecked(body)
    }

    /// Dynamically calls the mutex with a throwing closure that does not access the protected value (unchecked).
    ///
    /// Bypasses `Sendable` checking. Use for non-thread-affecting critical sections.
    ///
    /// - Parameter args: An array of throwing closures.
    /// - Returns: The result of the first closure if available; otherwise, `nil`.
    /// - Throws: Any error thrown by the closure.
    ///
    /// ### Example
    /// ```swift
    /// let result = try mutex {
    ///     log("Running critical section")
    ///     return 42
    /// }
    /// ```
    @discardableResult
    func dynamicallyCall<R>(withArguments args: [() throws -> R]) throws -> R? {
        guard let body = args.first else {
            return nil
        }

        return try trySyncUnchecked(body)
    }

    /// Dynamically calls the mutex with a non-throwing closure that receives `inout` access to the protected value (unchecked).
    ///
    /// Only the first closure is executed. Use this overload when `Value` does not conform to `Sendable`.
    ///
    /// - Parameter args: An array of closures.
    /// - Returns: The result of the first closure if available; otherwise, `nil`.
    ///
    /// ### Example
    /// ```swift
    /// let result = mutex { value in
    ///     value += 10
    ///     return value
    /// }
    /// ```
    @discardableResult
    func dynamicallyCall<R>(withArguments args: [(inout Value) -> R]) -> R? {
        guard let body = args.first else {
            return nil
        }

        return trySyncUnchecked(body)
    }

    /// Dynamically calls the mutex with a non-throwing, sendable closure.
    ///
    /// This enables use of dynamic call syntax with `@Sendable` closures that do not capture the protected value directly.
    /// Only the first closure in the array is executed.
    ///
    /// - Parameter args: An array of `@Sendable` closures.
    /// - Returns: The result of the first closure if available, otherwise `nil`.
    ///
    /// ### Example
    /// ```swift
    /// let value = mutex {
    ///     return computeSomething()
    /// }
    /// ```
    @discardableResult
    func dynamicallyCall<R>(withArguments args: [@Sendable () -> R]) -> R? {
        guard let body = args.first else {
            return nil
        }

        return syncUnchecked(body)
    }
}
