import Foundation

#if canImport(os)
import os

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension OSAllocatedUnfairLock: Locking where State == () {
    public func tryLock() -> Bool {
        return lockIfAvailable()
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension AnyLock {
    static func osAllocatedUnfairLock() -> Self {
        return .init(os.OSAllocatedUnfairLock(uncheckedState: ()))
    }
}
#endif
