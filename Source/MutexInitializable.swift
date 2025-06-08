import Foundation

/// A protocol for types that provide a mutex-protected value initializer.
///
/// Types conforming to `MutexInitializable` define how to wrap an initial value with mutual exclusion.
/// This enables concise, consistent initialization of thread-safe value containers.
///
/// When the associated `Value` type conforms to a literal protocol, conforming types gain default
/// initializers for `nil`, empty arrays, and empty dictionaries.
///
/// ### Example
/// ```swift
/// let mutex = SyncMutex(initialValue: 0)
///
/// @AtomicValue(mutex: SyncMutex.self) var count = 0
/// ```
public protocol MutexInitializable: Mutexing {
    /// Creates a mutex that protects the specified initial value.
    ///
    /// Use this initializer to wrap any value in a thread-safe container using mutual exclusion.
    ///
    /// - Parameter initialValue: The value to protect.
    ///
    /// ### Example
    /// ```swift
    /// let mutex = SyncMutex(initialValue: [1, 2, 3])
    /// ```
    init(initialValue: Value)
}

public extension MutexInitializable {
    /// Creates a mutex protecting a `nil` value.
    ///
    /// Available when `Value` conforms to `ExpressibleByNilLiteral`.
    ///
    /// ### Example
    /// ```swift
    /// let mutex = OptionalMutex<Int>()
    /// ```
    init() where Value: ExpressibleByNilLiteral {
        self = .init(initialValue: nil)
    }

    /// Creates a mutex protecting an empty array.
    ///
    /// Available when `Value` conforms to `ExpressibleByArrayLiteral`.
    ///
    /// ### Example
    /// ```swift
    /// let mutex = SyncMutex<[String]>()
    /// ```
    init() where Value: ExpressibleByArrayLiteral {
        self = .init(initialValue: [])
    }

    /// Creates a mutex protecting an empty dictionary.
    ///
    /// Available when `Value` conforms to `ExpressibleByDictionaryLiteral`.
    ///
    /// ### Example
    /// ```swift
    /// let mutex = SyncMutex<[String: Int]>()
    /// ```
    init() where Value: ExpressibleByDictionaryLiteral {
        self = .init(initialValue: [:])
    }
}
