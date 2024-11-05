import Foundation

#if swift(>=6.0)
public protocol Queueable: Sendable {
    typealias WorkItem = @Sendable () -> Void

    func async(execute workItem: @escaping WorkItem)

    func asyncAfter(deadline: DispatchTime, flags: Queue.Flags, execute work: @escaping WorkItem)

    func sync(execute workItem: () -> Void)
    func sync(execute workItem: () throws -> Void) rethrows

    func sync<T>(flags: Queue.Flags, execute work: () throws -> T) rethrows -> T
    func sync<T>(execute work: () throws -> T) rethrows -> T

    func sync<T>(flags: Queue.Flags, execute work: () -> T) -> T
    func sync<T>(execute work: () -> T) -> T
}
#else
public protocol Queueable {
    typealias WorkItem = () -> Void

    func async(execute workItem: @escaping WorkItem)

    func asyncAfter(deadline: DispatchTime, flags: Queue.Flags, execute work: @escaping WorkItem)

    func sync(execute workItem: () -> Void)
    func sync(execute workItem: () throws -> Void) rethrows

    func sync<T>(flags: Queue.Flags, execute work: () throws -> T) rethrows -> T
    func sync<T>(execute work: () throws -> T) rethrows -> T

    func sync<T>(flags: Queue.Flags, execute work: () -> T) -> T
    func sync<T>(execute work: () -> T) -> T
}
#endif

public extension Queueable {
    func asyncAfter(deadline: DispatchTime, execute work: @escaping WorkItem) {
        asyncAfter(deadline: deadline, flags: .absent, execute: work)
    }
}
