import Foundation

#if swift(>=6.0)
/// A protocol representing an abstract dispatch queue interface.
///
/// Types that conform to `Queueable` provide methods to execute synchronous and asynchronous
/// work items, as well as delayed execution, similar to `DispatchQueue`.
///
/// This abstraction enables testability and platform-agnostic concurrency control.
///
/// ### Example
/// ```swift
/// struct MyQueue: Queueable {
///     func async(execute workItem: @escaping WorkItem) { ... }
///     func asyncAfter(deadline: DispatchTime, flags: Queue.Flags, execute work: @escaping WorkItem) { ... }
///     func sync(execute workItem: () -> Void) { ... }
///     // Implement other methods...
/// }
/// ```
public protocol Queueable: Sendable {
    /// A unit of work to be executed on the queue.
    ///
    /// On Swift 6 and newer, this is a `@Sendable` closure.
    /// On earlier versions, it is a regular closure.
    typealias WorkItem = @Sendable () -> Void

    /// Schedules a work item for asynchronous execution on the queue.
    ///
    /// - Parameter workItem: A closure representing the work to perform.
    ///
    /// ### Example
    /// ```swift
    /// queue.async {
    ///     print("Async execution")
    /// }
    /// ```
    func async(execute workItem: @escaping WorkItem)

    /// Schedules a work item for asynchronous execution after a specified deadline.
    ///
    /// - Parameters:
    ///   - deadline: The time after which the work item should be executed.
    ///   - flags: Optional dispatch flags, such as `.barrier`.
    ///   - work: The closure to execute.
    ///
    /// ### Example
    /// ```swift
    /// queue.asyncAfter(deadline: .now() + 1, flags: []) {
    ///     print("Executed after 1 second")
    /// }
    /// ```
    func asyncAfter(deadline: DispatchTime, flags: Queue.Flags, execute work: @escaping WorkItem)

    /// Executes a closure synchronously on the queue.
    ///
    /// - Parameter workItem: A closure to execute.
    func sync(execute workItem: () -> Void)

    /// Executes a throwing closure synchronously on the queue.
    ///
    /// - Parameter workItem: A closure that may throw an error.
    /// - Throws: An error thrown by the closure.
    /// - Returns: The result of the closure.
    func sync(execute workItem: () throws -> Void) rethrows

    /// Executes a throwing closure with flags synchronously on the queue.
    ///
    /// - Parameters:
    ///   - flags: Dispatch flags to control execution semantics.
    ///   - work: A throwing closure.
    /// - Throws: An error thrown by the closure.
    /// - Returns: The result of the closure.
    func sync<T>(flags: Queue.Flags, execute work: () throws -> T) rethrows -> T

    /// Executes a closure synchronously on the queue and returns a result.
    ///
    /// - Parameter work: The closure to execute.
    /// - Returns: The result of the closure.
    func sync<T>(execute work: () throws -> T) rethrows -> T

    /// Executes a closure synchronously on the queue and returns a result.
    ///
    /// - Parameter work: The closure to execute.
    /// - Returns: The result of the closure.
    func sync<T>(flags: Queue.Flags, execute work: () -> T) -> T

    /// Executes a closure synchronously on the queue and returns a result.
    ///
    /// - Parameter work: The closure to execute.
    /// - Returns: The result of the closure.
    func sync<T>(execute work: () -> T) -> T
}
#else
/// A protocol representing an abstract dispatch queue interface.
///
/// Types that conform to `Queueable` provide methods to execute synchronous and asynchronous
/// work items, as well as delayed execution, similar to `DispatchQueue`.
///
/// This abstraction enables testability and platform-agnostic concurrency control.
///
/// ### Example
/// ```swift
/// struct MyQueue: Queueable {
///     func async(execute workItem: @escaping WorkItem) { ... }
///     func asyncAfter(deadline: DispatchTime, flags: Queue.Flags, execute work: @escaping WorkItem) { ... }
///     func sync(execute workItem: () -> Void) { ... }
///     // Implement other methods...
/// }
/// ```
public protocol Queueable {
    /// A unit of work to be executed on the queue.
    ///
    /// On Swift 6 and newer, this is a `@Sendable` closure.
    /// On earlier versions, it is a regular closure.
    typealias WorkItem = () -> Void

    /// Schedules a work item for asynchronous execution on the queue.
    ///
    /// - Parameter workItem: A closure representing the work to perform.
    ///
    /// ### Example
    /// ```swift
    /// queue.async {
    ///     print("Async execution")
    /// }
    /// ```
    func async(execute workItem: @escaping WorkItem)

    /// Schedules a work item for asynchronous execution after a specified deadline.
    ///
    /// - Parameters:
    ///   - deadline: The time after which the work item should be executed.
    ///   - flags: Optional dispatch flags, such as `.barrier`.
    ///   - work: The closure to execute.
    ///
    /// ### Example
    /// ```swift
    /// queue.asyncAfter(deadline: .now() + 1, flags: []) {
    ///     print("Executed after 1 second")
    /// }
    /// ```
    func asyncAfter(deadline: DispatchTime, flags: Queue.Flags, execute work: @escaping WorkItem)

    /// Executes a closure synchronously on the queue.
    ///
    /// - Parameter workItem: A closure to execute.
    func sync(execute workItem: () -> Void)

    /// Executes a throwing closure synchronously on the queue.
    ///
    /// - Parameter workItem: A closure that may throw an error.
    /// - Throws: An error thrown by the closure.
    /// - Returns: The result of the closure.
    func sync(execute workItem: () throws -> Void) rethrows

    /// Executes a throwing closure with flags synchronously on the queue.
    ///
    /// - Parameters:
    ///   - flags: Dispatch flags to control execution semantics.
    ///   - work: A throwing closure.
    /// - Throws: An error thrown by the closure.
    /// - Returns: The result of the closure.
    func sync<T>(flags: Queue.Flags, execute work: () throws -> T) rethrows -> T

    /// Executes a closure synchronously on the queue and returns a result.
    ///
    /// - Parameter work: The closure to execute.
    /// - Returns: The result of the closure.
    func sync<T>(execute work: () throws -> T) rethrows -> T

    /// Executes a closure synchronously on the queue and returns a result.
    ///
    /// - Parameter work: The closure to execute.
    /// - Returns: The result of the closure.
    func sync<T>(flags: Queue.Flags, execute work: () -> T) -> T

    /// Executes a closure synchronously on the queue and returns a result.
    ///
    /// - Parameter work: The closure to execute.
    /// - Returns: The result of the closure.
    func sync<T>(execute work: () -> T) -> T
}
#endif

public extension Queueable {
    /// Schedules a work item for asynchronous execution after a delay, using default flags.
    ///
    /// - Parameters:
    ///   - deadline: The time after which to execute the work.
    ///   - work: The closure to execute.
    ///
    /// ### Example
    /// ```swift
    /// queue.asyncAfter(deadline: .now() + 2) {
    ///     print("Delayed execution")
    /// }
    /// ```
    func asyncAfter(deadline: DispatchTime, execute work: @escaping WorkItem) {
        asyncAfter(deadline: deadline, flags: .absent, execute: work)
    }
}
