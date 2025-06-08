import Foundation

extension Foundation.NSLock: Locking {
    public func tryLock() -> Bool {
        return self.try()
    }
}
