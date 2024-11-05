import Foundation

#if swift(>=6.0)
public protocol Mutexing: Sendable {
    @discardableResult
    func sync<R>(execute work: () throws -> R) rethrows -> R

    @discardableResult
    func trySync<R>(execute work: () throws -> R) rethrows -> R
}
#else
public protocol Mutexing {
    @discardableResult
    func sync<R>(execute work: () throws -> R) rethrows -> R

    @discardableResult
    func trySync<R>(execute work: () throws -> R) rethrows -> R
}
#endif

public extension Mutexing where Self: Locking {
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
