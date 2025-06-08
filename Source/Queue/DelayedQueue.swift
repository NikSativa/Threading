import Foundation

/// A wrapper enum that represents various queue execution strategies, including synchronous,
/// asynchronous, and delayed execution on a given queue.
///
/// Use `DelayedQueue` to abstract over different execution modes, especially when queue selection
/// needs to be deferred or passed around.
///
/// ### Example
/// ```swift
/// func performTask(in queue: DelayedQueue) {
///     queue.fire {
///         print("Task executed")
///     }
/// }
///
/// performTask(in: .n.async(.main))
/// ```
public enum DelayedQueue {
    /// Represents the absence of a queue; work is executed immediately on the current thread.
    case absent
    /// Executes work synchronously on the specified queue.
    case sync(Queueable)

    /// Executes work asynchronously on the specified queue.
    case async(Queueable)
    /// Executes work asynchronously on the specified queue after a given deadline.
    case asyncAfter(deadline: DispatchTime, queue: Queueable)
    /// Executes work asynchronously on the specified queue after a given deadline with dispatch flags.
    case asyncAfterWithFlags(deadline: DispatchTime, flags: Queue.Flags, queue: Queueable)
}

#if swift(>=6.0)
extension DelayedQueue: Sendable {
    /// Executes the provided work item based on the current queue strategy.
    ///
    /// - Parameter workItem: A closure to execute. Must be `@Sendable` in Swift 6 or later.
    /// - Note: This method dispatches work using the strategy defined by the case of `DelayedQueue`.
    ///
    /// ### Example
    /// ```swift
    /// DelayedQueue.n.async(.global()).fire {
    ///     print("Running on global queue")
    /// }
    /// ```
    public func fire(_ workItem: @escaping @Sendable () -> Void) {
        switch self {
        case .absent:
            workItem()

        case .sync(let queue):
            queue.sync(execute: workItem)

        case .async(let queue):
            queue.async(execute: workItem)

        case .asyncAfter(let deadline, let queue):
            queue.asyncAfter(deadline: deadline,
                             execute: workItem)

        case .asyncAfterWithFlags(let deadline, let flags, let queue):
            queue.asyncAfter(deadline: deadline,
                             flags: flags,
                             execute: workItem)
        }
    }
}
#else
public extension DelayedQueue {
    /// Executes the provided work item based on the current queue strategy.
    ///
    /// - Parameter workItem: A closure to execute.
    /// - Note: This method dispatches work using the strategy defined by the case of `DelayedQueue`.
    ///
    /// ### Example
    /// ```swift
    /// DelayedQueue.n.async(.global()).fire {
    ///     print("Running on global queue")
    /// }
    /// ```
    func fire(_ workItem: @escaping () -> Void) {
        switch self {
        case .absent:
            workItem()

        case .sync(let queue):
            queue.sync(execute: workItem)

        case .async(let queue):
            queue.async(execute: workItem)

        case .asyncAfter(let deadline, let queue):
            queue.asyncAfter(deadline: deadline,
                             execute: workItem)

        case .asyncAfterWithFlags(let deadline, let flags, let queue):
            queue.asyncAfter(deadline: deadline,
                             flags: flags,
                             execute: workItem)
        }
    }
}
#endif

// MARK: - DelayedQueue.n

/// A namespace for concise construction of `DelayedQueue` cases.
///
/// Use `DelayedQueue.n` to simplify usage when passing queue strategies.
///
/// ### Example
/// ```swift
/// set(.n.sync(.main))
/// ```
public extension DelayedQueue {
    enum n {}
}

public extension DelayedQueue.n {
    /// Constructs a synchronous queue execution strategy.
    ///
    /// - Parameter q: A `Queue` instance.
    /// - Returns: A `DelayedQueue` configured for synchronous execution.
    ///
    /// ### Example
    /// ```swift
    /// let queue = DelayedQueue.n.sync(.main)
    /// ```
    static func sync(_ q: Queue) -> DelayedQueue {
        return .sync(q)
    }

    /// Constructs an asynchronous queue execution strategy.
    ///
    /// - Parameter q: A `Queue` instance.
    /// - Returns: A `DelayedQueue` configured for asynchronous execution.
    ///
    /// ### Example
    /// ```swift
    /// let queue = DelayedQueue.n.async(.global())
    /// ```
    static func async(_ q: Queue) -> DelayedQueue {
        return .async(q)
    }

    /// Constructs a delayed asynchronous execution strategy using a dispatch deadline.
    ///
    /// - Parameters:
    ///   - deadline: The time after which to execute.
    ///   - queue: The queue on which to execute.
    /// - Returns: A `DelayedQueue` configured for delayed asynchronous execution.
    ///
    /// ### Example
    /// ```swift
    /// let queue = DelayedQueue.n.asyncAfter(deadline: .now() + 2, queue: .main)
    /// ```
    static func asyncAfter(deadline: DispatchTime, queue: Queue) -> DelayedQueue {
        return .asyncAfter(deadline: deadline, queue: queue)
    }

    /// Constructs a delayed asynchronous execution strategy using a deadline and dispatch flags.
    ///
    /// - Parameters:
    ///   - deadline: The time after which to execute.
    ///   - flags: Dispatch flags such as `.barrier`.
    ///   - queue: The queue on which to execute.
    /// - Returns: A `DelayedQueue` configured with delay and execution flags.
    ///
    /// ### Example
    /// ```swift
    /// let queue = DelayedQueue.n.asyncAfter(deadline: .now() + 1, flags: .barrier, queue: .global())
    /// ```
    static func asyncAfter(deadline: DispatchTime, flags: Queue.Flags, queue: Queue) -> DelayedQueue {
        return .asyncAfterWithFlags(deadline: deadline, flags: flags, queue: queue)
    }
}
