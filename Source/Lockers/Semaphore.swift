import Foundation

/// A thread synchronization primitive built on `DispatchSemaphore`.
///
/// Use a `Semaphore` instance to control access to a shared resource across multiple threads.
/// It supports mutual exclusion as a binary semaphore or limited concurrent access as a counting semaphore.
///
/// - Note: This type wraps `DispatchSemaphore` and is suitable for low-level synchronization needs.
///
/// ### Features
/// - Thread-safe
/// - Supports mutual exclusion (binary semaphore)
/// - Supports resource pooling (counting semaphore)
/// - Provides both blocking and non-blocking locking
///
/// ### Example
/// ```swift
/// let semaphore = Semaphore() // Binary semaphore
/// semaphore.lock()
/// defer { semaphore.unlock() }
/// // Critical section
/// ```
///
/// ### Example with AtomicValue
/// ```swift
/// @AtomicValue(lock: .semaphore())
/// var counter = 0
///
/// lock.sync {
///     // Critical section
/// }
/// ```
public struct Semaphore {
    private let _lock: DispatchSemaphore

    /// Creates a semaphore with the specified initial value.
    ///
    /// - Parameter value: The initial semaphore count.
    ///   Pass `1` to create a binary semaphore for mutual exclusion,
    ///   or a value greater than `1` for a counting semaphore to control access to a resource pool.
    ///
    /// ### Example
    /// ```swift
    /// let binarySemaphore = Semaphore(value: 1)
    /// let countingSemaphore = Semaphore(value: 3)
    /// ```
    public init(value: Int = 1) {
        self._lock = DispatchSemaphore(value: value)
    }
}

extension Semaphore: Locking {
    /// Acquires the semaphore, blocking the current thread until access is granted.
    ///
    /// Use this method to enter a critical section.
    ///
    /// ### Example
    /// ```swift
    /// semaphore.lock()
    /// defer { semaphore.unlock() }
    /// // Access shared resource
    /// ```
    public func lock() {
        _lock.wait()
    }

    /// Attempts to acquire the semaphore without blocking.
    ///
    /// - Returns: `true` if the semaphore was successfully acquired; otherwise, `false`.
    ///
    /// ### Example
    /// ```swift
    /// if semaphore.tryLock() {
    ///     defer { semaphore.unlock() }
    ///     // Access shared resource
    /// }
    /// ```
    public func tryLock() -> Bool {
        return _lock.wait(timeout: .now()) == .success
    }

    /// Releases the semaphore, allowing other threads to acquire it.
    ///
    /// Call this method after completing the critical section.
    ///
    /// ### Example
    /// ```swift
    /// semaphore.unlock()
    /// ```
    public func unlock() {
        _lock.signal()
    }
}

extension Semaphore: @unchecked Sendable {}
