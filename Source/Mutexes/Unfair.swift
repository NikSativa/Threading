import Foundation

public final class Unfair {
    private var _lock = os_unfair_lock()

    public init() {}
}

extension Unfair: Mutexing {}

// MARK: - Locking

extension Unfair: Locking {
    public func lock() {
        os_unfair_lock_lock(&_lock)
    }

    public func tryLock() -> Bool {
        return os_unfair_lock_trylock(&_lock)
    }

    public func unlock() {
        os_unfair_lock_unlock(&_lock)
    }
}

#if swift(>=6.0)
extension Unfair: @unchecked Sendable {}
#endif
