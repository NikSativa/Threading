import Foundation

// MARK: - Foundation.NSLock + Locking

extension Foundation.NSLock: Locking {
    public func tryLock() -> Bool {
        return self.try()
    }
}

extension AnyLock {
    static func lock() -> Self {
        return .init(Foundation.NSLock())
    }
}
