import Foundation
import SpryKit
import Threading

extension DelayedQueue: Equatable {
    public static func ==(lhs: DelayedQueue, rhs: DelayedQueue) -> Bool {
        switch (lhs, rhs) {
        case (.absent, .absent):
            return true
        case let (.async(a), .async(b)),
             let (.sync(a), .sync(b)):
            return compare(a, b)
        case let (.asyncAfter(a1, a2), .asyncAfter(b1, b2)):
            return a1 == b1 && compare(a2, b2)
        case let (.asyncAfterWithFlags(a1, a2, a3), .asyncAfterWithFlags(b1, b2, b3)):
            return a1 == b1 && a2 == b2 && compare(a3, b3)
        case (.absent, _),
             (.async, _),
             (.asyncAfter, _),
             (.asyncAfterWithFlags, _),
             (.sync, _):
            return false
        }
    }
}

private func compare(_ lhs: Queueable, _ rhs: Queueable) -> Bool {
    if let queueA = lhs as? Queue,
       let queueB = rhs as? Queue {
        return queueA == queueB
    }

    return String(reflecting: lhs) == String(reflecting: rhs)
}
