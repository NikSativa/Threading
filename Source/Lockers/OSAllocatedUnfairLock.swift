#if canImport(os)
import Foundation
import os

/// A high-performance, low-level mutual exclusion primitive based on the system’s unfair lock.
///
/// Use `OSAllocatedUnfairLock` when you need fast, low-level synchronization in performance-critical,
/// low-contention scenarios. This lock is non-recursive and does not guarantee fairness or reentrancy.
///
/// The system manages the allocation and lifecycle of the underlying unfair lock.
///
/// > Important: Do not use in recursive or high-contention locking scenarios.
///
/// ### Characteristics
/// - Minimal overhead and memory usage
/// - Non-recursive (reentrant locking causes deadlock)
/// - No fairness guarantees
/// - System-managed memory lifecycle
///
/// ### Example
/// ```swift
/// let lock = OSAllocatedUnfairLock()
/// lock.lock()
/// defer { lock.unlock() }
/// // Critical section
/// ```
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public struct OSAllocatedUnfairLock {
    /// The system-managed unfair lock used for thread synchronization.
    ///
    /// Use this property only if you need to access the underlying `os.OSAllocatedUnfairLock` directly.
    ///
    /// The lock is optimized for low-overhead performance and automatically managed by the system.
    public let mutex: os.OSAllocatedUnfairLock<Void>

    /// Creates a new unfair lock instance.
    ///
    /// The system automatically initializes the underlying unfair lock and manages its memory lifecycle.
    ///
    /// ### Example
    /// ```swift
    /// let lock = OSAllocatedUnfairLock()
    /// ```
    public init() {
        self.mutex = .init()
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension OSAllocatedUnfairLock: Locking {
    /// Acquires the lock, blocking the calling thread until it becomes available.
    ///
    /// Use this method to enter a critical section protected by the lock. Always ensure that
    /// a matching call to `unlock()` is made to release the lock.
    ///
    /// ### Example
    /// ```swift
    /// lock.lock()
    /// defer { lock.unlock() }
    /// // Perform thread-safe work here
    /// ```
    public func lock() {
        mutex.lock()
    }

    /// Attempts to acquire the lock without blocking.
    ///
    /// - Returns: `true` if the lock was successfully acquired; otherwise, `false`.
    ///
    /// ### Example
    /// ```swift
    /// if lock.tryLock() {
    ///     defer { lock.unlock() }
    ///     // Perform non-blocking thread-safe work
    /// }
    /// ```
    public func tryLock() -> Bool {
        return mutex.lockIfAvailable()
    }

    /// Releases the lock, allowing other threads to acquire it.
    ///
    /// This method must be called after a successful call to `lock()` or `tryLock()`.
    ///
    /// ### Example
    /// ```swift
    /// lock.unlock()
    /// ```
    public func unlock() {
        mutex.unlock()
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension OSAllocatedUnfairLock: @unchecked Sendable {}
#endif
