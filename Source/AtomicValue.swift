import Foundation

@available(*, deprecated, renamed: "AtomicValue", message: "Use AtomicValue instead")
public typealias Atomic<Value> = AtomicValue<Value>

/// A property wrapper that provides thread-safe access to a value.
///
/// Use `AtomicValue` to safely read and modify values across multiple threads without
/// manually managing locks. It synchronizes all access using a lock or mutex,
/// offering both performance and safety.
///
/// ### Features
/// - Thread-safe access using a lock or mutex
/// - Dynamic member lookup for property-level synchronization
/// - Multiple initialization strategies (lock, mutex, or type-erased)
///
/// ### Example
/// ```swift
/// @AtomicValue var counter = 0
/// $counter.sync { $0 += 1 }
///
/// @AtomicValue var user = User(name: "Alice")
/// user.name = "Bob" // Thread-safe access to property
///
/// @AtomicValue(mutex: OSAllocatedUnfairLock.self) var highPerformance = 0
/// ```
@propertyWrapper
@dynamicMemberLookup
public final class AtomicValue<Value> {
    /// The mutex-protected value.
    private let innerValue: any Mutexing<Value>

    /// The current value, accessed in a thread-safe manner.
    ///
    /// Reading or writing this property acquires the underlying lock.
    /// Prefer `sync` or `trySync` when performing multiple operations to avoid
    /// repeated locking overhead.
    ///
    /// ### Example
    /// ```swift
    /// atomicValue.wrappedValue = 42
    /// let value = atomicValue.wrappedValue
    /// ```
    public var wrappedValue: Value {
        get {
            return innerValue.syncUnchecked { value in
                return value
            }
        }
        set {
            innerValue.syncUnchecked { value in
                value = newValue
            }
        }
    }

    /// The atomic wrapper instance used to access thread-safe operations.
    ///
    /// Use this property to call `sync`, `trySync`, or related methods.
    ///
    /// ### Example
    /// ```swift
    /// $counter.sync { $0 += 1 }
    /// ```
    public var projectedValue: AtomicValue<Value> {
        return self
    }

    /// Creates an atomic value using a concrete mutex instance.
    ///
    /// - Parameter mutex: A mutex instance that synchronizes access to the value.
    public required init(mutexing mutex: any Mutexing<Value>) {
        self.innerValue = mutex
    }

    /// Creates an atomic value using a type‑erased mutex.
    ///
    /// - Parameter anyMutex: A type‑erased mutex that protects the value.
    public convenience init(mutex anyMutex: AnyMutex<Value>) {
        self.init(mutexing: anyMutex.base)
    }

    /// Creates an atomic value protected by a specific mutex type.
    ///
    /// - Parameters:
    ///   - wrappedValue: The initial value to protect.
    ///   - mutexing: The concrete mutex type that will synchronize access to the value.
    public convenience init<M>(wrappedValue: Value, mutexing: M.Type)
        where M: MutexInitializable, M.Value == Value {
        self.init(mutexing: M(initialValue: wrappedValue))
    }

    /// Creates an atomic value using a type‑erased lock.
    ///
    /// - Parameters:
    ///   - wrappedValue: The initial value to protect.
    ///   - anyLock: A type‑erased lock used to synchronize access.
    public convenience init(wrappedValue: Value, lock anyLock: AnyLock) {
        self.init(mutexing: LockedValue(initialValue: wrappedValue, lock: anyLock.base))
    }

    /// Creates an atomic value using a specific locking mechanism.
    ///
    /// - Parameters:
    ///   - wrappedValue: The initial value to protect.
    ///   - lock: A lock instance used to synchronize access.
    public convenience init(wrappedValue: Value, lock: any Locking) {
        self.init(mutexing: LockedValue(initialValue: wrappedValue, lock: lock))
    }

    /// Creates an atomic value using the best available synchronization primitive for the platform.
    ///
    /// This initializer automatically selects the most efficient locking strategy
    /// based on the current operating system version.
    ///
    /// - Parameter wrappedValue: The initial value to protect.
    ///
    /// ### Example
    /// ```swift
    /// @AtomicValue var count = 0
    /// ```
    public convenience init(wrappedValue: Value) {
        var defaultMutex: AnyMutex<Value>?

        #if canImport(os)
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            defaultMutex = AnyMutex.osAllocatedUnfair(initialValue: wrappedValue)
        }
        #endif

        let mutex = defaultMutex ?? AnyMutex.lock(initialValue: wrappedValue, .pthread(.recursive))
        self.init(mutex: mutex)
    }
}

public extension AtomicValue where Value: ExpressibleByNilLiteral {
    /// Creates an atomic value initialized to `nil` using a type‑erased lock.
    ///
    /// - Parameter anyLock: A type‑erased lock used to synchronize access.
    convenience init(lock anyLock: AnyLock) {
        self.init(wrappedValue: nil, lock: anyLock)
    }

    /// Creates an atomic value initialized to `nil` using the specified mutex type.
    ///
    /// - Parameter mutexing: The concrete mutex type that will synchronize access to the value.
    convenience init<M>(mutexing: M.Type)
        where M: MutexInitializable, M.Value == Value {
        self.init(wrappedValue: nil, mutexing: mutexing)
    }
}

public extension AtomicValue where Value: ExpressibleByArrayLiteral {
    /// Creates an atomic value initialized to an empty array using a type‑erased lock.
    ///
    /// - Parameter anyLock: A type‑erased lock used to synchronize access.
    convenience init(lock anyLock: AnyLock) {
        self.init(wrappedValue: [], lock: anyLock)
    }

    /// Creates an atomic value initialized to an empty array using the specified mutex type.
    ///
    /// - Parameter mutexing: The concrete mutex type that will synchronize access to the value.
    convenience init<M>(mutexing: M.Type)
        where M: MutexInitializable, M.Value == Value {
        self.init(wrappedValue: [], mutexing: mutexing)
    }
}

public extension AtomicValue where Value: ExpressibleByDictionaryLiteral {
    /// Creates an atomic value initialized to an empty dictionary using a type‑erased lock.
    ///
    /// - Parameter anyLock: A type‑erased lock used to synchronize access.
    convenience init(lock anyLock: AnyLock) {
        self.init(wrappedValue: [:], lock: anyLock)
    }

    /// Creates an atomic value initialized to an empty dictionary using the specified mutex type.
    ///
    /// - Parameter mutexing: The concrete mutex type that will synchronize access to the value.
    convenience init<M>(mutexing: M.Type)
        where M: MutexInitializable, M.Value == Value {
        self.init(wrappedValue: [:], mutexing: mutexing)
    }
}

extension AtomicValue: Mutexing {
    /// Performs a thread-safe, exclusive operation on the value.
    ///
    /// This method acquires the underlying lock, passes an `inout` reference of the value to the closure,
    /// and returns the result. This is the preferred way to perform complex updates on the value.
    ///
    /// - Parameter body: A closure that receives an `inout` reference to the value and returns a result.
    /// - Returns: The result of the closure.
    ///
    /// ### Example
    /// ```swift
    /// let result = atomicValue.sync { value in
    ///     value += 1
    ///     return value
    /// }
    /// ```
    public func sync<R>(_ body: @Sendable (inout Value) throws -> R) rethrows -> R
    where R: Sendable, Value: Sendable {
        return try innerValue.sync(body)
    }

    /// Attempts a thread-safe, exclusive operation on the value without blocking.
    ///
    /// This method is similar to `sync(_:)` but will return `nil` if the lock
    /// could not be immediately acquired.
    ///
    /// - Parameter body: A closure that receives an `inout` reference to the value and returns a result.
    /// - Returns: The result of the closure if the lock was acquired; otherwise, `nil`.
    ///
    /// ### Example
    /// ```swift
    /// if let result = atomicValue.trySync({ $0 += 1 }) {
    ///     print("Updated: \(result)")
    /// }
    /// ```
    public func trySync<R>(_ body: @Sendable (inout Value) throws -> R) rethrows -> R?
    where R: Sendable, Value: Sendable {
        return try innerValue.sync(body)
    }

    /// Performs a thread-safe operation without enforcing `Sendable` constraints.
    ///
    /// Use this method only in performance-critical contexts where `Sendable` conformance cannot be satisfied
    /// and you understand the risks of unchecked thread safety.
    ///
    /// - Parameter body: A closure that receives an `inout` reference to the value.
    /// - Returns: The result of the closure.
    ///
    /// > Important: This method bypasses type safety and should be used with caution.
    public func syncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R {
        return try innerValue.syncUnchecked(body)
    }

    /// Attempts a thread-safe operation without enforcing `Sendable` constraints or blocking.
    ///
    /// Use this method only when non-blocking behavior is required and `Sendable` conformance is unavailable.
    ///
    /// - Parameter body: A closure that receives an `inout` reference to the value.
    /// - Returns: The result of the closure if the lock was acquired; otherwise, `nil`.
    ///
    /// > Important: This method bypasses type safety and should be used with caution.
    public func trySyncUnchecked<R>(_ body: (inout Value) throws -> R) rethrows -> R? {
        return try innerValue.trySyncUnchecked(body)
    }
}

extension AtomicValue: @unchecked Sendable {}

public extension AtomicValue {
    /// Creates an atomic value initialized to `nil` using the best available lock.
    ///
    /// Available when `Value` conforms to `ExpressibleByNilLiteral`.
    ///
    /// ### Example
    /// ```swift
    /// let atomic: AtomicValue<Int?> = .init()
    /// ```
    convenience init() where Value: ExpressibleByNilLiteral {
        self.init(wrappedValue: nil)
    }

    /// Creates an atomic value initialized to an empty array using the best available lock.
    ///
    /// Available when `Value` conforms to `ExpressibleByArrayLiteral`.
    ///
    /// ### Example
    /// ```swift
    /// let atomic: AtomicValue<[Int]> = .init()
    /// ```
    convenience init() where Value: ExpressibleByArrayLiteral {
        self.init(wrappedValue: [])
    }

    /// Creates an atomic value initialized to an empty dictionary using the best available lock.
    ///
    /// Available when `Value` conforms to `ExpressibleByDictionaryLiteral`.
    ///
    /// ### Example
    /// ```swift
    /// let atomic: AtomicValue<[String: Int]> = .init()
    /// ```
    convenience init() where Value: ExpressibleByDictionaryLiteral {
        self.init(wrappedValue: [:])
    }
}
