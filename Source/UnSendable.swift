import Foundation

/// Workaround for passing non-dispatched objects to a closure marked as dispatched. Use this only when you are sure the object is not shared between threads
///
/// - Warning: Use at your own risk.
public struct USendable<T> {
    public let value: T

    public init(value: T) {
        self.value = value
    }

    public init(_ value: T) {
        self.value = value
    }
}

#if swift(>=6.0)
extension USendable: @unchecked Sendable {}
#endif
