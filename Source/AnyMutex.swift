import Foundation

public struct AnyMutex {
    private let base: Mutexing

    public init(_ base: Mutexing) {
        self.base = base
    }

    public static var unfair: AnyMutex {
        return .init(Unfair())
    }

    public static func lock() -> AnyMutex {
        return .init(AnyLock.lock())
    }

    public static func recursiveLock() -> AnyMutex {
        return .init(AnyLock.recursiveLock())
    }

    #if canImport(os)
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public static func osAllocatedUnfairLock() -> AnyMutex {
        return .init(AnyLock.osAllocatedUnfairLock())
    }
    #endif

    public static func pthread(_ kind: PThreadKind = .normal) -> AnyMutex {
        return .init(PThread(kind: kind))
    }

    public static var semaphore: AnyMutex {
        return .init(Semaphore())
    }

    public static func barrier(_ queue: Queueable = Queue.utility) -> AnyMutex {
        return .init(Barrier(queue))
    }

    public static var `default`: AnyMutex {
        return pthread(.recursive)
    }
}

// MARK: - Mutexing

extension AnyMutex: Mutexing {
    public func sync<R>(execute work: () throws -> R) rethrows -> R {
        return try base.sync(execute: work)
    }

    public func trySync<R>(execute work: () throws -> R) rethrows -> R {
        return try base.trySync(execute: work)
    }
}

#if swift(>=6.0)
extension AnyMutex: Sendable {}
#endif
