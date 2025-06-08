import Foundation
#if canImport(os)
import os
#endif

/// A type-erased wrapper for any lock that conforms to the `Locking` protocol.
///
/// Use `AnyLock` to abstract over different locking implementations through a unified interface.
/// This is useful when you want to store locks in collections, return them from factory methods,
/// or decouple your code from concrete locking types.
///
/// ### Features
/// - Type erasure for lock implementations
/// - Unified interface for all `Locking`-conforming types
/// - Factory methods for common lock types
/// - Thread-safe synchronization
/// - Optional support for recursive locking (implementation-dependent)
///
/// ### Example
/// ```swift
/// let lock = AnyLock(NSLock())
///
/// // Use default recursive pthread lock
/// let defaultLock = AnyLock.default
///
/// // Use with LockedValue
/// let value = LockedValue(initialValue: 0, lock: lock)
///
/// // Use with AtomicValue
/// @AtomicValue(lock) var counter = 0
///
/// // Direct usage
/// lock.lock()
/// defer { lock.unlock() }
///
/// if lock.tryLock() {
///     defer { lock.unlock() }
///     // Critical section
/// }
/// ```
public struct AnyLock {
    /// The underlying locking implementation.
    ///
    /// All locking operations are forwarded to this instance. Its concrete type is hidden behind
    /// the `Locking` protocol interface.
    public let base: Locking

    /// Wraps a lock that conforms to the `Locking` protocol.
    ///
    /// - Parameter lock: The locking instance to type-erase.
    public init(_ lock: Locking) {
        self.base = lock
    }
}

public extension AnyLock {
    /// Creates an `AnyLock` backed by a POSIX thread mutex.
    ///
    /// This factory method creates a lock using the system's POSIX thread mutex
    /// implementation, which provides a robust and portable locking mechanism.
    ///
    /// The POSIX thread mutex is a low-level synchronization primitive that offers
    /// good performance and reliability. It can be configured to support either
    /// normal or recursive locking behavior.
    ///
    /// - Parameter kind: The type of pthread mutex to use (default is `.normal`).
    /// - Returns: A type-erased lock instance using a POSIX thread mutex.
    static func pthread(_ kind: PThreadKind = .default) -> Self {
        return .init(PThread(kind: kind))
    }

    /// The default `AnyLock` implementation.
    ///
    /// This static property provides a default lock implementation using a recursive
    /// POSIX thread mutex, which allows the same thread to acquire the lock multiple
    /// times without deadlocking. This is a safe default choice for most use cases.
    ///
    /// The recursive mutex is particularly useful when you need to:
    /// - Call methods that require the lock from within a locked section
    /// - Implement recursive algorithms that need locking
    /// - Avoid deadlocks in complex locking scenarios
    static var `default`: Self {
        return pthread(.recursive)
    }

    /// Creates an `AnyLock` using a standard `NSLock` as the underlying implementation.
    ///
    /// This factory method creates a lock using Foundation's `NSLock`, which provides
    /// a simple and efficient locking mechanism suitable for most use cases.
    ///
    /// `NSLock` is a high-level lock implementation that offers:
    /// - Simple and intuitive API
    /// - Good performance for most scenarios
    /// - Integration with Foundation's debugging tools
    /// - Support for try-lock operations
    ///
    /// - Returns: A type-erased lock instance using `NSLock`.
    static func lock() -> Self {
        return .init(Foundation.NSLock())
    }

    /// Creates an `AnyLock` backed by an `UnfairLock`.
    ///
    /// This factory method creates a lock using a low-level unfair lock implementation,
    /// which provides fast locking performance by allowing threads to bypass fairness constraints.
    ///
    /// Use unfair locks when performance is critical and fairness is not required. This
    /// lock may prefer newer threads over older ones in contention scenarios.
    ///
    /// - Warning: Unfair locks are non-recursive and can cause deadlocks if the same thread
    ///   attempts to acquire the lock multiple times without releasing it.
    ///
    /// - Returns: A type-erased lock instance using an unfair lock.
    static func unfair() -> Self {
        return .init(UnfairLock())
    }

    #if canImport(os)
    /// Creates an `AnyLock` backed by an OS-allocated unfair lock.
    ///
    /// This factory method creates a lock using the system's unfair lock implementation,
    /// which provides high-performance locking at the cost of fairness guarantees.
    ///
    /// The OS-allocated unfair lock is optimized for:
    /// - Extremely low overhead
    /// - Minimal memory footprint
    /// - High performance in low-contention scenarios
    ///
    /// - Note: Available on Apple platforms starting from macOS 13.0, iOS 16.0,
    ///         tvOS 16.0, and watchOS 9.0.
    /// - Returns: A type-erased lock instance using an OS-allocated unfair lock.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    static func osAllocatedUnfair() -> Self {
        return .init(OSAllocatedUnfairLock())
    }
    #endif

    /// Creates an `AnyLock` using a recursive lock as the underlying implementation.
    ///
    /// This factory method creates a lock using Foundation's `NSRecursiveLock`,
    /// which allows the same thread to acquire the lock multiple times without
    /// causing a deadlock.
    ///
    /// `NSRecursiveLock` is particularly useful when:
    /// - You need to call methods that require the lock from within a locked section
    /// - Implementing recursive algorithms that need locking
    /// - Working with code that may acquire the lock multiple times
    ///
    /// - Returns: A type-erased lock instance using `NSRecursiveLock`.
    static func recursiveLock() -> Self {
        return .init(Foundation.NSRecursiveLock())
    }

    /// Creates an `AnyLock` backed by a semaphore.
    ///
    /// This factory method creates a lock using a semaphore, which can be useful
    /// for more complex synchronization scenarios or when you need to limit
    /// concurrent access to a resource.
    ///
    /// Semaphores are particularly useful when:
    /// - You need to limit the number of concurrent accesses to a resource
    /// - Implementing producer-consumer patterns
    /// - Coordinating access between multiple threads
    ///
    /// - Parameter value: The initial value for the semaphore (default is 1).
    /// - Returns: A type-erased lock instance using a semaphore.
    static func semaphore(value: Int = 1) -> Self {
        return .init(Semaphore(value: value))
    }
}

/// Conformance to the ``Locking`` protocol.
///
/// Forwards all locking operations to the underlying ``base`` lock instance.
/// This enables ``AnyLock`` to be used interchangeably with other ``Locking``-conforming types.
///
/// ### Example
/// ```swift
/// let lock = AnyLock.default
/// lock.lock()
/// defer { lock.unlock() }
/// // Perform thread-safe operations
/// ```
extension AnyLock: Locking {
    /// Acquires the underlying lock, blocking the calling thread until the lock becomes available.
    ///
    /// This method delegates the operation to the wrapped ``Locking`` implementation.
    ///
    /// ### Example
    /// ```swift
    /// lock.lock()
    /// defer { lock.unlock() }
    /// sharedResource.modify()
    /// ```
    public func lock() {
        base.lock()
    }

    /// Attempts to acquire the underlying lock without blocking.
    ///
    /// - Returns: `true` if the lock was successfully acquired; otherwise, `false`.
    ///
    /// ### Example
    /// ```swift
    /// if lock.tryLock() {
    ///     defer { lock.unlock() }
    ///     sharedResource.modify()
    /// }
    /// ```
    public func tryLock() -> Bool {
        return base.tryLock()
    }

    /// Releases the underlying lock, allowing other threads to acquire it.
    ///
    /// This method must be called after a successful ``lock()`` or ``tryLock()`` call to avoid deadlocks.
    ///
    /// ### Example
    /// ```swift
    /// lock.unlock()
    /// ```
    public func unlock() {
        base.unlock()
    }
}

extension AnyLock: @unchecked Sendable {}
