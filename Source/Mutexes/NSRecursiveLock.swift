import Foundation

// MARK: - NSRecursiveLock + Locking

extension NSRecursiveLock: Locking {
    public func tryLock() -> Bool {
        return self.try()
    }
}

extension AnyLock {
    static func recursiveLock() -> Self {
        return .init(Foundation.NSRecursiveLock())
    }
}
