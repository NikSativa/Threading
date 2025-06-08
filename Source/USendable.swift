import Foundation

/// A wrapper that marks a non-`Sendable` value as `@unchecked Sendable`.
///
/// Use `USendable` when you are confident that a value is safe to transfer across
/// concurrency domains, even though its type does not conform to `Sendable`.
///
/// This is useful in advanced scenarios where manual auditing guarantees thread-safety
/// or immutability, and compiler enforcement of `Sendable` is undesired or impossible.
///
/// > Important: This wrapper does not enforce thread safety. You are responsible for ensuring
/// the value is accessed safely across threads.
///
/// ### Topics
///
/// #### Thread Safety
/// Accessing the wrapped value from multiple threads requires external synchronization.
///
/// #### Use Cases
/// - Wrapping legacy types that do not conform to `Sendable`
/// - Working with types that are logically immutable but not marked as `Sendable`
///
/// ### Example
/// ```swift
/// final class NotSendable { var value = 0 }
///
/// let instance = NotSendable()
/// let sendable = USendable(instance)
///
/// Task.detached {
///     print(sendable.value) // ⚠️ Ensure thread-safety yourself
/// }
/// ```
public final class USendable<T> {
    /// The wrapped non-`Sendable` value.
    ///
    /// Accessing this value from a concurrent context must be done with extreme caution.
    /// This wrapper does not provide synchronization or enforce immutability.
    ///
    /// ### Example
    /// ```swift
    /// let container = USendable(SomeNonSendable())
    /// _ = container.value // unsafe unless externally synchronized
    /// ```
    public var value: T

    /// Creates a `USendable` wrapper around a given value.
    ///
    /// - Parameter value: The non-`Sendable` value to wrap. You are responsible for ensuring thread safety.
    public required init(value: T) {
        self.value = value
    }

    /// Creates a `USendable` wrapper using shorthand syntax.
    ///
    /// This is a convenience initializer for succinct initialization.
    ///
    /// - Parameter value: The non-`Sendable` value to wrap.
    public init(_ value: T) {
        self.value = value
    }
}

public extension USendable where T: ExpressibleByNilLiteral {
    /// Creates a `USendable` wrapper with a `nil` value.
    ///
    /// Available when `T` conforms to `ExpressibleByNilLiteral`. This is useful
    /// for initializing optional types or containers with a default `nil` state.
    ///
    /// ### Example
    /// ```swift
    /// let optionalValue = USendable<SomeOptionalType?>()
    /// ```
    convenience init() {
        self.init(nil)
    }
}

extension USendable: @unchecked Sendable {}
