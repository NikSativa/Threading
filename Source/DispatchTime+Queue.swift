import Dispatch
import Foundation

public extension DispatchTimeInterval {
    static func seconds(_ seconds: Double) -> Self {
        let nano = Int(seconds * 1E+9)
        return .nanoseconds(nano)
    }
}

public extension DispatchTime {
    static func delayInSeconds(_ seconds: Double) -> Self {
        return .now() + .seconds(seconds)
    }
}
