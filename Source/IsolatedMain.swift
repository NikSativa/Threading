import Foundation

public extension Queue {
    static var isolatedMain: IsolatedMain.Type {
        return IsolatedMain.self
    }
}

public struct IsolatedMain {
    // namespace
}

#if swift(>=6.0)
public extension IsolatedMain {
    @inline(__always)
    static func sync(_ closure: @MainActor () -> Void) {
        return Queue.main.sync {
            return MainActor.assumeIsolated {
                return closure()
            }
        }
    }

    @inline(__always)
    static func sync<T: Sendable>(_ closure: @MainActor () -> T) -> T {
        return Queue.main.sync {
            return MainActor.assumeIsolated {
                return closure()
            }
        }
    }

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
    @inline(__always)
    static func sync(_ closure: () -> Void) {
        return Queue.main.sync {
            return closure()
        }
    }

    @inline(__always)
    static func sync<T>(_ closure: () -> T) -> T {
        return Queue.main.sync {
            return closure()
        }
    }

    @inline(__always)
    static func sync<T>(_ closure: () throws -> T) throws -> T {
        return try Queue.main.sync {
            return try closure()
        }
    }
}
#endif
