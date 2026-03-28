import Foundation
import Threading

final class FakeQueueable: Queueable, @unchecked Sendable {
    var shouldFireSyncClosures: Bool = false
    var asyncWorkItem: WorkItem?

    private(set) var asyncCallCount: Int = 0
    private(set) var syncCallCount: Int = 0
    private(set) var asyncAfterCallCount: Int = 0
    private(set) var lastDeadline: DispatchTime?
    private(set) var lastFlags: Queue.Flags?

    func async(execute workItem: @escaping WorkItem) {
        asyncCallCount += 1
        asyncWorkItem = workItem
    }

    func asyncAfter(deadline: DispatchTime, flags: Queue.Flags, execute work: @escaping WorkItem) {
        asyncAfterCallCount += 1
        lastDeadline = deadline
        lastFlags = flags
        asyncWorkItem = work
    }

    func sync(execute workItem: () -> Void) {
        syncCallCount += 1
        if shouldFireSyncClosures {
            workItem()
        }
    }

    func sync(execute workItem: () throws -> Void) rethrows {
        syncCallCount += 1
        if shouldFireSyncClosures {
            try workItem()
        }
    }

    func sync<T>(flags: Queue.Flags, execute work: () throws -> T) rethrows -> T {
        syncCallCount += 1
        lastFlags = flags
        return try work()
    }

    func sync<T>(execute work: () throws -> T) rethrows -> T {
        syncCallCount += 1
        return try work()
    }

    func sync<T>(flags: Queue.Flags, execute work: () -> T) -> T {
        syncCallCount += 1
        lastFlags = flags
        return work()
    }

    func sync<T>(execute work: () -> T) -> T {
        syncCallCount += 1
        return work()
    }
}
