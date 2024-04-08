import Foundation
import SpryKit
import Threading

public final class FakeMutexing: Mutexing, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case async = "sync(execute:)"
        case trySync = "trySync(execute:)"
    }

    public var shouldFireClosures: Bool = false

    public func sync<R>(execute work: () throws -> R) rethrows -> R {
        if shouldFireClosures {
            return try spryify(fallbackValue: work())
        }
        return spryify()
    }

    public func trySync<R>(execute work: () throws -> R) rethrows -> R {
        if shouldFireClosures {
            return try spryify(fallbackValue: work())
        }
        return spryify()
    }
}
