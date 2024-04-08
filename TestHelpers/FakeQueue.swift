import Foundation
import SpryKit
import Threading

public final class FakeQueueable: Queueable, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case async = "async(execute:)"
        case asyncAfter = "asyncAfter(deadline:execute:)"
        case asyncAfterWithFlags = "asyncAfter(deadline:flags:execute:)"

        case sync = "sync(execute:)"
        case syncWithFlags = "sync(flags:execute:)"
    }

    public init() {}

    public var shouldFireSyncClosures: Bool = false
    public var asyncWorkItem: (() -> Void)?

    public func async(execute workItem: @escaping () -> Void) {
        asyncWorkItem = workItem
        return spryify(arguments: workItem)
    }

    public func asyncAfter(deadline: DispatchTime, flags: Queue.Flags, execute work: @escaping () -> Void) {
        asyncWorkItem = work
        return spryify(arguments: deadline, flags, work)
    }

    public func asyncAfter(deadline: DispatchTime, execute work: @escaping () -> Void) {
        asyncWorkItem = work
        return spryify(arguments: deadline, work)
    }

    public func sync(execute workItem: () -> Void) {
        if shouldFireSyncClosures {
            workItem()
        }

        return spryify()
    }

    public func sync(execute workItem: () throws -> Void) rethrows {
        if shouldFireSyncClosures {
            try workItem()
        }

        return spryify()
    }

    public func sync<T>(flags: Queue.Flags, execute work: () throws -> T) rethrows -> T {
        if shouldFireSyncClosures {
            return try spryify(arguments: flags, fallbackValue: work())
        }

        return spryify(arguments: flags)
    }

    public func sync<T>(execute work: () throws -> T) rethrows -> T {
        if shouldFireSyncClosures {
            return try spryify(fallbackValue: work())
        }

        return spryify()
    }

    public func sync<T>(flags: Queue.Flags, execute work: () -> T) -> T {
        if shouldFireSyncClosures {
            return spryify(arguments: flags, fallbackValue: work())
        }

        return spryify(arguments: flags)
    }

    public func sync<T>(execute work: () -> T) -> T {
        if shouldFireSyncClosures {
            return spryify(fallbackValue: work())
        }

        return spryify()
    }
}
