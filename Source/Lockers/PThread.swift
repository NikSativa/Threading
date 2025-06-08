import Foundation

/// Defines the kind of POSIX mutex to use with a `PThread` instance.
///
/// Use `PThreadKind` to specify whether the mutex should allow recursive locking.
///
/// - `normal`: A standard mutex that does not support recursive locking. Locking it
///   multiple times from the same thread results in a deadlock.
/// - `recursive`: A mutex that supports recursive locking by the same thread. Each
///   call to `lock()` must be balanced with a corresponding call to `unlock()`.
///
/// ### Example
/// ```swift
/// let lock = PThread(kind: .normal)
/// ```
public enum PThreadKind {
    case normal
    case recursive

    /// The default mutex type used when no specific type is specified.
    ///
    /// Defaults to `.recursive` for safer behavior in common use cases.
    ///
    /// ### Example
    /// ```swift
    /// let lock = PThread(kind: .default)
    /// ```
    public static let `default`: Self = .recursive
}

/// A lightweight wrapper around `pthread_mutex_t` for low-level mutual exclusion.
///
/// `PThread` provides direct access to POSIX thread mutex functionality,
/// supporting both normal and recursive locking behavior. This type is
/// suitable for advanced use cases where precise control over thread
/// synchronization is required.
///
/// ### Characteristics
/// - Supports normal and recursive mutex types
/// - Uses manual resource management (mutex is destroyed on deinitialization)
/// - Enables integration with other locking abstractions
///
/// ### Example
/// ```swift
/// let mutex = PThread(kind: .recursive)
/// mutex.lock()
/// defer { mutex.unlock() }
/// // Critical section
/// ```
///
/// ### Example with AtomicValue
/// ```swift
/// @AtomicValue(lock: .pthread(.recursive))
/// var counter = 0
///
/// lock.sync {
///     // Critical section
/// }
/// ```
public final class PThread {
    private var _lock: pthread_mutex_t = .init()

    /// Creates a `PThread` instance with the specified mutex behavior.
    ///
    /// - Parameter kind: The mutex behavior to use (`.normal` or `.recursive`).
    ///
    /// - Precondition: Initialization must succeed. Crashes if the mutex cannot be created.
    ///
    /// ### Example
    /// ```swift
    /// let lock = PThread(kind: .recursive)
    /// ```
    public init(kind: PThreadKind) {
        var attr = pthread_mutexattr_t()

        guard pthread_mutexattr_init(&attr) == 0 else {
            preconditionFailure()
        }

        switch kind {
        case .normal:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL)
        case .recursive:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        }

        guard pthread_mutex_init(&_lock, &attr) == 0 else {
            preconditionFailure()
        }

        pthread_mutexattr_destroy(&attr)
    }

    deinit {
        pthread_mutex_destroy(&_lock)
    }
}

extension PThread: Locking {
    /// Acquires the mutex, blocking the calling thread until it becomes available.
    ///
    /// Use this method to enter a critical section protected by the mutex.
    public func lock() {
        pthread_mutex_lock(&_lock)
    }

    /// Attempts to acquire the mutex without blocking.
    ///
    /// - Returns: `true` if the lock was successfully acquired; otherwise, `false`.
    public func tryLock() -> Bool {
        return pthread_mutex_trylock(&_lock) == 0
    }

    /// Releases the mutex, allowing other threads to acquire it.
    ///
    /// Call this after a successful `lock()` or `tryLock()` to exit the critical section.
    public func unlock() {
        pthread_mutex_unlock(&_lock)
    }
}

extension PThread: @unchecked Sendable {}
extension PThreadKind: Sendable {}
