import Foundation

// MARK: - Queue + Queueable

extension Queue: Queueable {
    public func async(execute workItem: @escaping () -> Void) {
        sdk.async(execute: workItem)
    }

    public func asyncAfter(deadline: DispatchTime,
                           flags: Queue.Flags,
                           execute work: @escaping () -> Void) {
        sdk.asyncAfter(deadline: deadline,
                       flags: flags.toSDK(),
                       execute: work)
    }

    public func asyncAfter(deadline: DispatchTime,
                           execute work: @escaping () -> Void) {
        asyncAfter(deadline: deadline,
                   flags: .absent,
                   execute: work)
    }

    public func sync(execute workItem: () -> Void) {
        if isMainThread {
            workItem()
        } else {
            sdk.sync(execute: workItem)
        }
    }

    public func sync(execute workItem: () throws -> Void) rethrows {
        if isMainThread {
            try workItem()
        } else {
            try sdk.sync(execute: workItem)
        }
    }

    public func sync<T>(flags: Queue.Flags,
                        execute work: () throws -> T) rethrows -> T {
        if isMainThread {
            return try work()
        }
        return try sdk.sync(flags: flags.toSDK(),
                            execute: work)
    }

    public func sync<T>(execute work: () throws -> T) rethrows -> T {
        return try sync(flags: .absent, execute: work)
    }

    public func sync<T>(flags: Flags, execute work: () -> T) -> T {
        if isMainThread {
            return work()
        }
        return sdk.sync(flags: flags.toSDK(),
                        execute: work)
    }

    public func sync<T>(execute work: () -> T) -> T {
        return sync(flags: .absent, execute: work)
    }
}

private extension Queue.Flags {
    func toSDK() -> DispatchWorkItemFlags {
        switch self {
        case .absent:
            return []
        case .barrier:
            return .barrier
        }
    }
}

private extension Queue {
    var isMainThread: Bool {
        return isMain && Thread.isMainThread
    }
}
