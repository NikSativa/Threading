import Foundation

#if swift(>=6.0)
/// Workaround for passing non-dispatched objects to a closure marked as dispatched. Use this only when you are sure the object is not shared between threads
/// - Warning: Use at your own risk.
public struct UnSendable<T>: @unchecked Sendable {
    public let value: T

    public init(value: T) {
        self.value = value
    }

    public init(_ value: T) {
        self.value = value
    }
}
#else
/// Workaround for passing non-dispatched objects to a closure marked as dispatched. Use this only when you are sure the object is not shared between threads
/// - Warning: Use at your own risk.
public struct UnSendable<T> {
    public let value: T

    public init(value: T) {
        self.value = value
    }

    public init(_ value: T) {
        self.value = value
    }
}
#endif
