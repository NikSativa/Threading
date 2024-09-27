import Dispatch
import Foundation

public struct Queue: Equatable {
    public enum Attributes: Equatable {
        case concurrent
        case serial
    }

    public enum Flags: Equatable {
        case absent
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
    static var main: Self {
        return Queue(kind: .main,
                     sdk: .main)
    }

    static var background: Self {
        return Queue(kind: .background,
                     sdk: .global(qos: .background))
    }

    static var utility: Self {
        return Queue(kind: .utility,
                     sdk: .global(qos: .utility))
    }

    static var `default`: Self {
        return Queue(kind: .default,
                     sdk: .global(qos: .default))
    }

    static var userInitiated: Self {
        return Queue(kind: .userInitiated,
                     sdk: .global(qos: .userInitiated))
    }

    static var userInteractive: Self {
        return Queue(kind: .userInteractive,
                     sdk: .global(qos: .userInteractive))
    }

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
extension Queue.Kind: Sendable {}
#endif
