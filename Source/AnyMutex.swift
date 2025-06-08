import Foundation

/// A type-erased wrapper for any type that conforms to `Mutexing`.
///
/// `AnyMutex` provides a unified interface for working with different mutex implementations.
/// Use this type to abstract away the concrete locking mechanism, enabling flexibility and
/// decoupling from specific synchronization strategies.
///
/// ### Features
/// - Type erasure for heterogeneous mutex types
/// - Thread-safe access and mutation
/// - Factory methods for common locking strategies
/// - Support for synchronous and non-blocking access
///
/// ### Example
/// ```swift
/// let mutex = AnyMutex.lock(initialValue: 0, .default)
/// mutex.sync { $0 += 1 }
/// if let doubled = mutex.trySync({ $0 * 2 }) {
///     print(doubled)
/// }
/// ```
///
/// > Note: The wrapped value must conform to `Sendable`.
public struct AnyMutex<Value> {
    /// The underlying mutex implementation.
    ///
    /// All synchronization operations are forwarded to this instance, which conforms to `Mutexing`.
    public let base: any Mutexing<Value>

    /// Creates a type-erased mutex from a concrete `Mutexing` instance.
    ///
    /// - Parameter lock: A mutex implementation to wrap.
    public init(_ lock: any Mutexing<Value>) {
        self.base = lock
    }
}

public extension AnyMutex {
    /// Creates a mutex that protects a value using a lock-based implementation.
    ///
    /// Use this method when you need fine-grained control over locking behavior, or want to reuse an existing lock.
    ///
    /// - Parameters:
    ///   - value: The initial value to be protected.
    ///   - lock: The lock to use for synchronization. Defaults to `.default`.
    /// - Returns: A type-erased mutex instance using the specified lock.
    static func lock(initialValue value: Value, _ lock: AnyLock = .default) -> Self {
        return .init(LockedValue(initialValue: value, lock: lock))
    }

    /// Creates a mutex that protects a value using a dispatch queue barrier.
    ///
    /// This method ensures exclusive access to the protected value by executing operations as barrier blocks on the given queue.
    ///
    /// - Parameters:
    ///   - value: The initial value to be protected.
    ///   - queue: The queue to use for synchronization.
    /// - Returns: A type-erased mutex instance that synchronizes access on the specified queue.
    static func queueBarrier(initialValue value: Value, queue: Queueable) -> Self {
        return .init(QueueBarrier(initialValue: value, queue: queue))
    }

    /// Creates an `AnyMutex` using a queue barrier with the default queue.
    ///
    /// This factory method creates a mutex that uses a dispatch queue barrier for
    /// synchronization, using the default queue.
    ///
    /// The default queue implementation provides:
    /// - Serial execution of protected operations
    /// - Fair access to the protected value
    /// - Integration with the system's dispatch queue
    ///
    /// - Parameter value: The initial value to be protected by the mutex.
    /// - Returns: A type-erased mutex instance using queue barrier synchronization.
    static func queueBarrier(initialValue value: Value) -> Self {
        return .init(QueueBarrier(initialValue: value))
    }

    #if canImport(Synchronization) && supportsVisionOS && compiler(>=6.0)
    /// Creates an `AnyMutex` using the system's native mutex implementation.
    ///
    /// This factory method creates a mutex using the system's built-in mutex implementation
    /// from the Synchronization framework, which provides high-performance synchronization.
    ///
    /// The system's native mutex implementation offers:
    /// - High performance and low overhead
    /// - Integration with system-level debugging tools
    /// - Optimized for modern hardware
    ///
    /// - Note: Available on macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, and visionOS 2.0
    ///         or later.
    /// - Parameter value: The initial value to be protected by the mutex.
    /// - Returns: A type-erased mutex instance using the system's native mutex.
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    static func syncMutex(initialValue value: Value) -> Self where Value: Sendable {
        return .init(SyncMutex(initialValue: value))
    }
    #endif

    #if canImport(os)
    /// Creates an `AnyMutex` using an OS-allocated unfair lock.
    ///
    /// This factory method creates a mutex using the system's unfair lock implementation,
    /// which provides high-performance synchronization at the cost of fairness guarantees.
    ///
    /// The OS-allocated unfair lock is optimized for:
    /// - Extremely low overhead
    /// - Minimal memory footprint
    /// - High performance in low-contention scenarios
    ///
    /// - Note: Available on macOS 13.0, iOS 16.0, tvOS 16.0, and watchOS 9.0 or later.
    /// - Parameter value: The initial value to be protected by the mutex.
    /// - Returns: A type-erased mutex instance using an OS-allocated unfair lock.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    static func osAllocatedUnfair(initialValue value: Value) -> Self {
        return .init(OSAllocatedUnfairMutex(initialValue: value))
    }
    #endif
}

extension AnyMutex: Mutexing {
    public func sync<R>(_ body: @Sendable (inout Value) throws -> R) rethrows -> R
    where R: Sendable, Value: Sendable {
        return try base.sync(body)
    }

    public func trySync<R>(_ body: @Sendable (inout Value) throws -> R) rethrows -> R?
    where R: Sendable, Value: Sendable {
        return try base.trySync(body)
    }

    public func syncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R {
        return try base.syncUnchecked(body)
    }

    public func trySyncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R? {
        return try base.trySyncUnchecked(body)
    }
}

public extension AnyMutex where Value: ExpressibleByNilLiteral {
    #if canImport(os)
    /// Creates a mutex that protects a `nil` value using an OS-allocated unfair lock.
    ///
    /// Use this lock for minimal overhead when contention is expected to be low.
    ///
    /// - Returns: A type-erased mutex instance.
    /// - Note: Available on macOS 13.0, iOS 16.0, tvOS 16.0, and watchOS 9.0 or later.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    static func osAllocatedUnfair() -> Self {
        return .init(OSAllocatedUnfairMutex())
    }
    #endif

    #if canImport(Synchronization) && supportsVisionOS && compiler(>=6.0)
    /// Creates a mutex that protects a `nil` value using the system’s native mutex.
    ///
    /// This lock provides high-performance synchronization optimized for modern hardware.
    ///
    /// - Returns: A type-erased mutex instance protecting an empty dictionary.
    /// - Note: Available on macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, and visionOS 2.0 or later.
    ///
    /// ### Example
    /// ```swift
    /// let mutex = AnyMutex<[String: Int]>.syncMutex()
    /// mutex.sync { $0["key"] = 42 }
    /// ```
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    static func syncMutex() -> Self where Value: Sendable {
        return .init(SyncMutex())
    }
    #endif

    /// Creates a mutex that protects a `nil` value using a default queue-barrier strategy.
    ///
    /// This method uses a serial dispatch queue to ensure thread-safe access.
    ///
    /// - Returns: A type-erased mutex instance.
    static func queueBarrier() -> Self {
        return .init(QueueBarrier())
    }

    /// Creates a mutex that protects a `nil` value using the specified lock.
    ///
    /// - Parameter lock: The lock to use. Defaults to `.default`.
    /// - Returns: A type-erased mutex instance.
    static func lock(_ lock: AnyLock = .default) -> Self {
        return .init(LockedValue(lock: lock))
    }
}

public extension AnyMutex where Value: ExpressibleByArrayLiteral {
    #if canImport(os)
    /// Creates a mutex that protects an empty array using an OS-allocated unfair lock.
    ///
    /// Use this lock for minimal overhead when contention is expected to be low.
    ///
    /// - Returns: A type-erased mutex instance.
    /// - Note: Available on macOS 13.0, iOS 16.0, tvOS 16.0, and watchOS 9.0 or later.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    static func osAllocatedUnfair() -> Self {
        return .init(OSAllocatedUnfairMutex())
    }
    #endif

    #if canImport(Synchronization) && supportsVisionOS && compiler(>=6.0)
    /// Creates a mutex that protects an empty array using the system’s native mutex.
    ///
    /// This lock provides high-performance synchronization optimized for modern hardware.
    ///
    /// - Returns: A type-erased mutex instance.
    /// - Note: Available on macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, and visionOS 2.0 or later.
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    static func syncMutex() -> Self where Value: Sendable {
        return .init(SyncMutex())
    }
    #endif

    /// Creates a mutex that protects an empty array using a default queue-barrier strategy.
    ///
    /// This method uses a serial dispatch queue to ensure thread-safe access.
    ///
    /// - Returns: A type-erased mutex instance.
    static func queueBarrier() -> Self {
        return .init(QueueBarrier())
    }

    /// Creates a mutex that protects an empty array using the specified lock.
    ///
    /// - Parameter lock: The lock to use. Defaults to `.default`.
    /// - Returns: A type-erased mutex instance.
    static func lock(_ lock: AnyLock = .default) -> Self {
        return .init(LockedValue(lock: lock))
    }
}

public extension AnyMutex where Value: ExpressibleByDictionaryLiteral {
    #if canImport(os)
    /// Creates a mutex that protects an empty dictionary using an OS-allocated unfair lock.
    ///
    /// Use this lock for minimal overhead when contention is expected to be low.
    ///
    /// - Returns: A type-erased mutex instance.
    /// - Note: Available on macOS 13.0, iOS 16.0, tvOS 16.0, and watchOS 9.0 or later.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    static func osAllocatedUnfair() -> Self {
        return .init(OSAllocatedUnfairMutex())
    }
    #endif

    #if canImport(Synchronization) && supportsVisionOS && compiler(>=6.0)
    /// Creates a mutex that protects an empty dictionary using the system’s native mutex.
    ///
    /// This lock provides high-performance synchronization optimized for modern hardware.
    ///
    /// - Returns: A type-erased mutex instance.
    /// - Note: Available on macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, and visionOS 2.0 or later.
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    static func syncMutex() -> Self where Value: Sendable {
        return .init(SyncMutex())
    }
    #endif

    /// Creates a mutex that protects an empty dictionary using a default queue-barrier strategy.
    ///
    /// This method uses a serial dispatch queue to ensure thread-safe access to the dictionary.
    ///
    /// - Returns: A type-erased mutex instance.
    ///
    /// ### Example
    /// ```swift
    /// let mutex = AnyMutex<[String: Int]>.queueBarrier()
    /// mutex.sync { $0["value"] = 10 }
    /// ```
    static func queueBarrier() -> Self {
        return .init(QueueBarrier())
    }

    /// Creates a mutex that protects an empty dictionary using the specified lock.
    ///
    /// Use this when you want to supply a custom locking strategy.
    ///
    /// - Parameter lock: The lock to use for synchronization. Defaults to `.default`.
    /// - Returns: A type-erased mutex instance.
    ///
    /// ### Example
    /// ```swift
    /// let customLock = AnyLock.default
    /// let mutex = AnyMutex<[String: Int]>.lock(customLock)
    /// mutex.sync { $0["key"] = 1 }
    /// ```
    static func lock(_ lock: AnyLock = .default) -> Self {
        return .init(LockedValue(lock: lock))
    }
}

extension AnyMutex: @unchecked Sendable {}
