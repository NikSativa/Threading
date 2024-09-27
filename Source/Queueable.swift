import Foundation

#if swift(>=6.0)
public protocol Queueable: Sendable {
    func async(execute workItem: @escaping @Sendable () -> Void)

    func asyncAfter(deadline: DispatchTime,
                    flags: Queue.Flags,
                    execute work: @escaping @Sendable () -> Void)
    func asyncAfter(deadline: DispatchTime,
                    execute work: @escaping @Sendable () -> Void)

    func sync(execute workItem: () -> Void)
    func sync(execute workItem: () throws -> Void) rethrows

    func sync<T>(flags: Queue.Flags, execute work: () throws -> T) rethrows -> T
    func sync<T>(execute work: () throws -> T) rethrows -> T

    func sync<T>(flags: Queue.Flags, execute work: () -> T) -> T
    func sync<T>(execute work: () -> T) -> T
}
#else
public protocol Queueable {
    func async(execute workItem: @escaping () -> Void)

    func asyncAfter(deadline: DispatchTime,
                    flags: Queue.Flags,
                    execute work: @escaping () -> Void)
    func asyncAfter(deadline: DispatchTime,
                    execute work: @escaping () -> Void)

    func sync(execute workItem: () -> Void)
    func sync(execute workItem: () throws -> Void) rethrows

    func sync<T>(flags: Queue.Flags, execute work: () throws -> T) rethrows -> T
    func sync<T>(execute work: () throws -> T) rethrows -> T

    func sync<T>(flags: Queue.Flags, execute work: () -> T) -> T
    func sync<T>(execute work: () -> T) -> T
}
#endif
