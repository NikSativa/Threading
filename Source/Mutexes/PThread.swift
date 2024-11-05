import Foundation

public enum PThreadKind {
    case normal
    case recursive

    public static let `default`: Self = .normal
}

public final class PThread {
    private var _lock: pthread_mutex_t = .init()

    public init(kind: PThreadKind) {
        var attr = pthread_mutexattr_t()

        guard pthread_mutexattr_init(&attr) == 0 else {
            preconditionFailure()
        }

        switch kind {
        case .normal:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL)
        case .recursive:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        }

        guard pthread_mutex_init(&_lock, &attr) == 0 else {
            preconditionFailure()
        }

        pthread_mutexattr_destroy(&attr)
    }

    deinit {
        pthread_mutex_destroy(&_lock)
    }
}

extension PThread: Mutexing {}

// MARK: - Locking

extension PThread: Locking {
    public func lock() {
        pthread_mutex_lock(&_lock)
    }

    public func tryLock() -> Bool {
        return pthread_mutex_trylock(&_lock) == 0
    }

    public func unlock() {
        pthread_mutex_unlock(&_lock)
    }
}

#if swift(>=6.0)
extension PThread: @unchecked Sendable {}
extension PThreadKind: Sendable {}
#endif
