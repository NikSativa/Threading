import Foundation

#if swift(>=6.0)
public protocol Locking: Sendable {
    func lock()
    func tryLock() -> Bool
    func unlock()
}
#else
public protocol Locking {
    func lock()
    func tryLock() -> Bool
    func unlock()
}
#endif
