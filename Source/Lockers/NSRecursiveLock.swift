import Foundation

extension NSRecursiveLock: Locking {
    public func tryLock() -> Bool {
        return self.try()
    }
}
