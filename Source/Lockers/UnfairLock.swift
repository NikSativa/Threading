import Foundation

/// A high-performance mutual exclusion primitive based on `os_unfair_lock`.
///
/// Use `UnfairLock` for fast, low-overhead synchronization in low-contention environments.
/// This lock is suitable for protecting short-lived critical sections and is more efficient
/// than traditional pthread-based locks in most use cases.
///
/// - Important: This lock is non-recursive. Attempting to acquire it multiple times on the same thread will deadlock.
/// - Note: This type conforms to `Locking`, `Mutexing`, and is marked as `@unchecked Sendable`.
///
/// ### Example
/// ```swift
/// let lock = UnfairLock()
/// lock.lock()
/// defer { lock.unlock() }
/// // Critical section
/// ```
public final class UnfairLock {
    private var _lock = os_unfair_lock()

    /// Creates a new `UnfairLock` instance.
    ///
    /// The lock is initialized in an unlocked state.
    public init() {}
}

extension UnfairLock: Locking {
    /// Acquires the lock, blocking the calling thread until it becomes available.
    ///
    /// Use this method to enter a critical section protected by the lock.
    ///
    /// ### Example
    /// ```swift
    /// lock.lock()
    /// defer { lock.unlock() }
    /// sharedCounter += 1
    /// ```
    public func lock() {
        os_unfair_lock_lock(&_lock)
    }

    /// Attempts to acquire the lock without blocking.
    ///
    /// - Returns: `true` if the lock was successfully acquired; otherwise, `false`.
    ///
    /// ### Example
    /// ```swift
    /// if lock.tryLock() {
    ///     sharedCounter += 1
    ///     lock.unlock()
    /// }
    /// ```
    public func tryLock() -> Bool {
        return os_unfair_lock_trylock(&_lock)
    }

    /// Releases the lock, allowing other threads to acquire it.
    ///
    /// Call this after a successful call to `lock()` or `tryLock()` to exit the critical section.
    ///
    /// ### Example
    /// ```swift
    /// lock.lock()
    /// sharedCounter += 1
    /// lock.unlock()
    /// ```
    public func unlock() {
        os_unfair_lock_unlock(&_lock)
    }
}

extension UnfairLock: @unchecked Sendable {}
