import Foundation
import NQueue
import NSpry

final class FakeMutexing: Mutexing, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case async = "sync(execute:)"
        case trySync = "trySync(execute:)"
    }

    var shouldFireClosures: Bool = false

    func sync<R>(execute work: () throws -> R) rethrows -> R {
        if shouldFireClosures {
            return try spryify(fallbackValue: work())
        }
        return spryify()
    }

    func trySync<R>(execute work: () throws -> R) rethrows -> R {
        if shouldFireClosures {
            return try spryify(fallbackValue: work())
        }
        return spryify()
    }
}
