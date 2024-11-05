import Foundation

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
                mutex: AnyMutex = .default,
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
    convenience init(mutex: AnyMutex = .default,
                     read: AtomicOption = .sync,
                     write: AtomicOption = .sync) {
        self.init(wrappedValue: nil,
                  mutex: mutex,
                  read: read,
                  write: write)
    }
}

#if swift(>=6.0)
extension Atomic: @unchecked Sendable {}
extension AtomicOption: Sendable {}
#endif
