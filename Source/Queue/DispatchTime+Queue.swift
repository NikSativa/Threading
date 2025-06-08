import Foundation

public extension DispatchTimeInterval {
    /// Creates a `DispatchTimeInterval` from a fractional number of seconds.
    ///
    /// Use this method when you need to express time intervals with floating-point precision,
    /// such as 1.5 seconds or 0.25 seconds. The interval is converted to nanoseconds internally.
    ///
    /// - Parameter seconds: A fractional duration in seconds.
    /// - Returns: A `DispatchTimeInterval` representing the given duration in nanoseconds.
    ///
    /// ### Example
    /// ```swift
    /// let delay = DispatchTimeInterval.seconds(1.25)
    /// queue.asyncAfter(deadline: .now() + delay) {
    ///     print("Runs after 1.25 seconds")
    /// }
    /// ```
    static func seconds(_ seconds: Double) -> Self {
        let nano = Int(seconds * 1E+9)
        return .nanoseconds(nano)
    }
}

public extension DispatchTime {
    /// Returns a `DispatchTime` that is offset from the current time by a specified duration in seconds.
    ///
    /// This method simplifies scheduling delayed work with floating-point precision,
    /// converting the delay into a `DispatchTimeInterval` internally.
    ///
    /// - Parameter seconds: The number of seconds to delay. Can be fractional.
    /// - Returns: A `DispatchTime` representing the deadline.
    ///
    /// ### Example
    /// ```swift
    /// let deadline = DispatchTime.delayInSeconds(2.0)
    /// queue.asyncAfter(deadline: deadline) {
    ///     print("Executed after 2.0 seconds")
    /// }
    /// ```
    static func delayInSeconds(_ seconds: Double) -> Self {
        return .now() + .seconds(seconds)
    }
}
