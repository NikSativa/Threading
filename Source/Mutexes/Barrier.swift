import Foundation

public struct Barrier {
    private let queue: Queueable

    public init(_ queue: Queueable) {
        self.queue = queue
    }
}

// MARK: - Mutexing

extension Barrier: Mutexing {
    public func sync<R>(execute work: () throws -> R) rethrows -> R {
        return try queue.sync(flags: .barrier, execute: work)
    }

    public func trySync<R>(execute work: () throws -> R) rethrows -> R {
        return try queue.sync(flags: .barrier, execute: work)
    }
}

#if swift(>=6.0)
extension Barrier: @unchecked Sendable {}
#endif
