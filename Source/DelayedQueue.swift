import Foundation

public enum DelayedQueue {
    case absent
    case sync(Queueable)

    case async(Queueable)
    case asyncAfter(deadline: DispatchTime, queue: Queueable)
    case asyncAfterWithFlags(deadline: DispatchTime, flags: Queue.Flags, queue: Queueable)
}

public extension DelayedQueue {
    func fire(_ workItem: @escaping () -> Void) {
        switch self {
        case .absent:
            workItem()
        case .sync(let queue):
            queue.sync(execute: workItem)
        case .async(let queue):
            queue.async(execute: workItem)
        case .asyncAfter(let deadline, let queue):
            queue.asyncAfter(deadline: deadline,
                             execute: workItem)
        case .asyncAfterWithFlags(let deadline, let flags, let queue):
            queue.asyncAfter(deadline: deadline,
                             flags: flags,
                             execute: workItem)
        }
    }

    /// namespace for shortcut
    ///
    /// interface:
    /// ```swift
    /// func set(_ queue: DelayedQueue)
    /// ```
    /// call will be:
    /// ```swift
    /// set(.n.sync(.main))
    /// ```
    /// instead of
    /// ```swift
    /// set(.sync(Queue.main))
    /// ```
    enum n {}
}

public extension DelayedQueue.n {
    static func sync(_ q: Queue) -> DelayedQueue {
        return .sync(q)
    }

    static func async(_ q: Queue) -> DelayedQueue {
        return .async(q)
    }

    static func asyncAfter(deadline: DispatchTime, queue: Queue) -> DelayedQueue {
        return .asyncAfter(deadline: deadline, queue: queue)
    }

    static func asyncAfter(deadline: DispatchTime, flags: Queue.Flags, queue: Queue) -> DelayedQueue {
        return .asyncAfterWithFlags(deadline: deadline, flags: flags, queue: queue)
    }
}
