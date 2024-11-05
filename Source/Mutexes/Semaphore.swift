import Foundation

public struct Semaphore {
    private var _lock = DispatchSemaphore(value: 1)

    public init() {}
}

// MARK: - Mutexing

extension Semaphore: Mutexing {
    public func sync<R>(execute work: () throws -> R) rethrows -> R {
        _lock.wait()
        defer {
            _lock.signal()
        }
        return try work()
    }

    public func trySync<R>(execute work: () throws -> R) rethrows -> R {
        _lock.wait()
        defer {
            _lock.signal()
        }
        return try work()
    }
}

#if swift(>=6.0)
extension Semaphore: @unchecked Sendable {}
#endif
