import Foundation

public struct AnyLock {
    private let _lock: Locking

    public init(_ lock: Locking) {
        self._lock = lock
    }
}

// MARK: - Mutexing

extension AnyLock: Mutexing {}

// MARK: - Locking

extension AnyLock: Locking {
    public func lock() {
        _lock.lock()
    }

    public func tryLock() -> Bool {
        return _lock.tryLock()
    }

    public func unlock() {
        _lock.unlock()
    }
}

#if swift(>=6.0)
extension NSLock: @unchecked Sendable {}
#endif
