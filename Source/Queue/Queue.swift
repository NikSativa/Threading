import Foundation

/// A type-safe wrapper around `DispatchQueue` with a focus on clear and consistent usage.
///
/// The `Queue` struct provides factory properties for accessing common system queues
/// as well as custom queue creation. This abstraction enables concise code while retaining
/// the performance and semantics of `DispatchQueue`.
///
/// ### Example
/// ```swift
/// let customQueue = Queue.custom(label: "com.example.myqueue")
/// customQueue.sdk.async {
///     print("Running in custom queue")
/// }
/// ```
public struct Queue: Equatable {
    /// Represents the execution behavior of a dispatch queue.
    ///
    /// Used when creating custom queues to specify whether they should run tasks
    /// serially or concurrently.
    ///
    /// ### Example
    /// ```swift
    /// let queue = Queue.custom(label: "com.example.serial", attributes: .serial)
    /// ```
    public enum Attributes: Equatable {
        /// Tasks are executed concurrently on the queue.
        case concurrent
        /// Tasks are executed serially, one at a time, on the queue.
        case serial
    }

    /// Additional execution flags that may be used with queue operations.
    ///
    /// Useful when dispatching work with barriers or other attributes.
    ///
    /// ### Example
    /// ```swift
    /// let flags: Queue.Flags = .barrier
    /// ```
    public enum Flags: Equatable {
        /// No additional flags.
        case absent
        /// Specifies that the operation acts as a barrier, blocking other tasks until completion.
        case barrier
    }

    fileprivate enum Kind: Equatable {
        case main
        case custom(label: String,
                    qos: DispatchQoS = .default,
                    attributes: Attributes = .concurrent)

        case background
        case utility
        case `default`
        case userInitiated
        case userInteractive
    }

    let sdk: DispatchQueue
    private let kind: Kind
}

public extension Queue {
    /// The main queue, typically used for UI updates or tasks that must run on the main thread.
    ///
    /// ### Example
    /// ```swift
    /// Queue.main.sdk.async {
    ///     updateUI()
    /// }
    /// ```
    static var main: Self {
        return Queue(kind: .main,
                     sdk: .main)
    }

    /// A background global queue with low priority, suitable for non-urgent tasks.
    ///
    /// ### Example
    /// ```swift
    /// Queue.background.sdk.async {
    ///     performCleanup()
    /// }
    /// ```
    static var background: Self {
        return Queue(kind: .background,
                     sdk: .global(qos: .background))
    }

    /// A global queue with utility quality of service, ideal for long-running tasks with user-visible results.
    ///
    /// ### Example
    /// ```swift
    /// Queue.utility.sdk.async {
    ///     loadData()
    /// }
    /// ```
    static var utility: Self {
        return Queue(kind: .utility,
                     sdk: .global(qos: .utility))
    }

    /// The default global queue, used for standard-priority tasks.
    ///
    /// ### Example
    /// ```swift
    /// Queue.default.sdk.async {
    ///     performStandardWork()
    /// }
    /// ```
    static var `default`: Self {
        return Queue(kind: .default,
                     sdk: .global(qos: .default))
    }

    /// A high-priority global queue for tasks initiated by the user and requiring immediate results.
    ///
    /// ### Example
    /// ```swift
    /// Queue.userInitiated.sdk.async {
    ///     processImage()
    /// }
    /// ```
    static var userInitiated: Self {
        return Queue(kind: .userInitiated,
                     sdk: .global(qos: .userInitiated))
    }

    /// The highest-priority global queue for UI-interactive tasks.
    ///
    /// ### Example
    /// ```swift
    /// Queue.userInteractive.sdk.async {
    ///     animateUI()
    /// }
    /// ```
    static var userInteractive: Self {
        return Queue(kind: .userInteractive,
                     sdk: .global(qos: .userInteractive))
    }

    /// Creates a custom dispatch queue with the given label, QoS, and attributes.
    ///
    /// - Parameters:
    ///   - label: A string to uniquely identify the queue.
    ///   - qos: The quality of service level to associate with the queue. Default is `.default`.
    ///   - attributes: Whether the queue is serial or concurrent. Default is `.concurrent`.
    /// - Returns: A `Queue` wrapping the created `DispatchQueue`.
    ///
    /// ### Example
    /// ```swift
    /// let myQueue = Queue.custom(label: "com.example.concurrent", qos: .userInitiated, attributes: .concurrent)
    /// myQueue.sdk.async {
    ///     doWork()
    /// }
    /// ```
    static func custom(label: String,
                       qos: DispatchQoS = .default,
                       attributes: Attributes = .concurrent) -> Self {
        return Queue(kind: .custom(label: label,
                                   qos: qos,
                                   attributes: attributes),
                     sdk: .init(label: label,
                                qos: qos,
                                attributes: attributes.toSDK()))
    }

    /// Indicates whether the queue represents the main thread.
    ///
    /// Primarily used internally for optimizations and thread assertions.
    internal var isMain: Bool {
        return kind == .main
    }

    private init(kind: Kind,
                 sdk: DispatchQueue) {
        self.kind = kind
        self.sdk = sdk
    }
}

private extension Queue.Attributes {
    func toSDK() -> DispatchQueue.Attributes {
        switch self {
        case .concurrent:
            return .concurrent
        case .serial:
            return []
        }
    }
}

#if swift(>=6.0)
extension Queue: @unchecked Sendable {}
extension Queue.Attributes: Sendable {}
extension Queue.Flags: Sendable {}
extension Queue.Kind: @unchecked Sendable {}
#endif
