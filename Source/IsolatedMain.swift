import Foundation

/// A namespace for main thread isolation utilities.
///
/// `IsolatedMain` provides static methods for executing closures on the main thread
/// while respecting Swift concurrency's actor isolation model. It ensures that
/// code marked with `@MainActor` executes in the correct thread and context.
///
/// ### Features
/// - Guaranteed main thread execution
/// - Actor isolation support (Swift 6.0+)
/// - Synchronous execution with return values
/// - Error propagation
/// - Inline optimization for performance
///
/// ### Example
/// ```swift
/// IsolatedMain.sync {
///     updateUI()
/// }
///
/// let result = IsolatedMain.sync {
///     computeValue()
/// }
///
/// do {
///     try IsolatedMain.sync {
///         try performThrowingOperation()
///     }
/// } catch {
///     handle(error)
/// }
/// ```
public struct IsolatedMain {
    // namespace
}

public extension Queue {
    /// Accessor for the `IsolatedMain` namespace through `Queue`.
    ///
    /// Enables convenient access to main thread isolation utilities via `Queue`.
    ///
    /// ### Example
    /// ```swift
    /// Queue.isolatedMain.sync {
    ///     updateUI()
    /// }
    /// ```
    static var isolatedMain: IsolatedMain.Type {
        return IsolatedMain.self
    }
}

#if swift(>=6.0)
public extension IsolatedMain {
    /// Executes a closure on the main thread with `@MainActor` isolation.
    ///
    /// Ensures the closure runs synchronously on the main thread within the `@MainActor`
    /// context. Blocks the calling thread until execution completes.
    ///
    /// - Parameter closure: A closure isolated to the main actor.
    /// - Note: Available when compiling with Swift 6.0 or later.
    ///
    /// ### Example
    /// ```swift
    /// IsolatedMain.sync {
    ///     updateUI()
    /// }
    /// ```
    @inline(__always)
    static func sync(_ closure: @MainActor () -> Void) {
        return Queue.main.sync {
            return MainActor.assumeIsolated {
                return closure()
            }
        }
    }

    /// Executes a closure on the main thread with `@MainActor` isolation and returns a value.
    ///
    /// Ensures the closure runs synchronously on the main thread within the `@MainActor`
    /// context. Blocks the calling thread until execution completes.
    ///
    /// - Parameter closure: A closure isolated to the main actor that returns a value.
    /// - Returns: The result produced by the closure.
    /// - Note: Available when compiling with Swift 6.0 or later.
    ///
    /// ### Example
    /// ```swift
    /// let result: String = IsolatedMain.sync {
    ///     return "Main thread result"
    /// }
    /// ```
    @inline(__always)
    static func sync<T: Sendable>(_ closure: @MainActor () -> T) -> T {
        return Queue.main.sync {
            return MainActor.assumeIsolated {
                return closure()
            }
        }
    }

    /// Executes a throwing closure on the main thread with `@MainActor` isolation and returns a value.
    ///
    /// Ensures the closure runs synchronously on the main thread within the `@MainActor`
    /// context. Blocks the calling thread until execution completes.
    ///
    /// - Parameter closure: A throwing closure isolated to the main actor that returns a value.
    /// - Returns: The result produced by the closure.
    /// - Throws: An error thrown by the closure.
    /// - Note: Available when compiling with Swift 6.0 or later.
    ///
    /// ### Example
    /// ```swift
    /// let value = try IsolatedMain.sync {
    ///     try loadMainThreadResource()
    /// }
    /// ```
    @inline(__always)
    static func sync<T: Sendable>(_ closure: @MainActor () throws -> T) throws -> T {
        return try Queue.main.sync {
            return try MainActor.assumeIsolated {
                return try closure()
            }
        }
    }
}
#else
public extension IsolatedMain {
    /// Executes a closure synchronously on the main thread.
    ///
    /// Blocks the calling thread until the closure completes.
    ///
    /// - Parameter closure: A closure to execute on the main thread.
    @inline(__always)
    static func sync(_ closure: () -> Void) {
        return Queue.main.sync {
            return closure()
        }
    }

    /// Executes a closure synchronously on the main thread and returns a value.
    ///
    /// Blocks the calling thread until the closure completes.
    ///
    /// - Parameter closure: A closure to execute on the main thread.
    /// - Returns: The result produced by the closure.
    @inline(__always)
    static func sync<T>(_ closure: () -> T) -> T {
        return Queue.main.sync {
            return closure()
        }
    }

    /// Executes a throwing closure synchronously on the main thread and returns a value.
    ///
    /// Blocks the calling thread until the closure completes.
    ///
    /// - Parameter closure: A throwing closure to execute on the main thread.
    /// - Returns: The result produced by the closure.
    /// - Throws: An error thrown by the closure.
    @inline(__always)
    static func sync<T>(_ closure: () throws -> T) throws -> T {
        return try Queue.main.sync {
            return try closure()
        }
    }
}
#endif
