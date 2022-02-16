import Foundation

public protocol Mutexing {
    @discardableResult
    func sync<R>(execute work: () throws -> R) rethrows -> R

    @discardableResult
    func trySync<R>(execute work: () throws -> R) rethrows -> R
}

public enum Mutex {
    public enum Kind {
        case normal
        case recursive

        public static let `default`: Self = .normal
    }

    public static var unfair: Mutexing {
        return Impl.Unfair()
    }

    public static func nslock(_ kind: Kind = .normal) -> Mutexing {
        return Impl.NSLock(kind: kind)
    }

    public static func pthread(_ kind: Kind = .normal) -> Mutexing {
        return Impl.PThread(kind: kind)
    }

    public static var semaphore: Mutexing {
        return Impl.Semaphore()
    }

    public static func barrier(_ queue: Queueable = Queue.utility) -> Mutexing {
        return Impl.Barrier(queue)
    }

    public static var `default`: Mutexing {
        return Self.pthread(.recursive)
    }
}

public enum AtomicOption: Equatable {
    case async
    case sync
    case trySync
}

@propertyWrapper
public final class Atomic<Value> {
    private let mutex: Mutexing
    private var value: Value
    private let read: AtomicOption
    private let write: AtomicOption

    public var projectedValue: Atomic<Value> {
        return self
    }

    public var wrappedValue: Value {
        get {
            switch read {
            case .sync:
                return mutex.sync {
                    return value
                }
            case .trySync:
                return mutex.trySync {
                    return value
                }
            case .async:
                return value
            }
        }

        set {
            switch write {
            case .sync:
                mutex.sync {
                    value = newValue
                }
            case .trySync:
                mutex.trySync {
                    value = newValue
                }
            case .async:
                value = newValue
            }
        }
    }

    public init(wrappedValue initialValue: Value,
                mutex: Mutexing = Mutex.default,
                read: AtomicOption = .sync,
                write: AtomicOption = .sync) {
        self.value = initialValue
        self.mutex = mutex
        self.read = read
        self.write = write
    }

    public func mutate(_ mutation: (inout Value) -> Void) {
        mutex.sync {
            mutation(&value)
        }
    }

    public func tryMutate(_ mutation: (inout Value) -> Void) {
        mutex.trySync {
            mutation(&value)
        }
    }

    public func mutate<T>(_ mutation: (inout Value) -> T) -> T {
        return mutex.sync {
            return mutation(&value)
        }
    }

    public func tryMutate<T>(_ mutation: (inout Value) -> T) -> T {
        return mutex.trySync {
            return mutation(&value)
        }
    }
}

public extension Atomic where Value: ExpressibleByNilLiteral {
    convenience init(mutex: Mutexing = Mutex.default,
                     read: AtomicOption = .sync,
                     write: AtomicOption = .sync) {
        self.init(wrappedValue: nil,
                  mutex: mutex,
                  read: read,
                  write: write)
    }
}

private protocol Locking {
    func lock()
    func tryLock() -> Bool
    func unlock()
}

private protocol SimpleMutexing: Mutexing, Locking {
}

private extension SimpleMutexing {
    @discardableResult
    func sync<R>(execute work: () throws -> R) rethrows -> R {
        lock()
        defer {
            unlock()
        }
        return try work()
    }

    @discardableResult
    func trySync<R>(execute work: () throws -> R) rethrows -> R {
        let locked = tryLock()
        defer {
            if locked {
                unlock()
            }
        }
        return try work()
    }
}

extension NSLock: Locking {
    func tryLock() -> Bool {
        return self.try()
    }
}

extension NSRecursiveLock: Locking {
    func tryLock() -> Bool {
        return self.try()
    }
}

private enum Impl {
    final class Unfair: SimpleMutexing {
        private var _lock = os_unfair_lock()

        func lock() {
            os_unfair_lock_lock(&_lock)
        }

        func tryLock() -> Bool {
            return os_unfair_lock_trylock(&_lock)
        }

        func unlock() {
            os_unfair_lock_unlock(&_lock)
        }
    }

    struct NSLock: SimpleMutexing {
        private let _lock: Locking

        public init(kind: Mutex.Kind) {
            switch kind {
            case .normal:
                self._lock = Foundation.NSLock()
            case .recursive:
                self._lock = Foundation.NSRecursiveLock()
            }
        }

        func lock() {
            _lock.lock()
        }

        func tryLock() -> Bool {
            return _lock.tryLock()
        }

        func unlock() {
            _lock.unlock()
        }
    }

    final class PThread: SimpleMutexing {
        private var _lock: pthread_mutex_t = .init()

        public init(kind: Mutex.Kind) {
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

    struct Semaphore: Mutexing {
        private var _lock = DispatchSemaphore(value: 1)

        func sync<R>(execute work: () throws -> R) rethrows -> R {
            _lock.wait()
            defer {
                _lock.signal()
            }
            return try work()
        }

        func trySync<R>(execute work: () throws -> R) rethrows -> R {
            _lock.wait()
            defer {
                _lock.signal()
            }
            return try work()
        }
    }

    struct Barrier: Mutexing {
        private let queue: Queueable

        init(_ queue: Queueable) {
            self.queue = queue
        }

        func sync<R>(execute work: () throws -> R) rethrows -> R {
            return try queue.sync(flags: .barrier, execute: work)
        }

        func trySync<R>(execute work: () throws -> R) rethrows -> R {
            return try queue.sync(flags: .barrier, execute: work)
        }
    }
}
