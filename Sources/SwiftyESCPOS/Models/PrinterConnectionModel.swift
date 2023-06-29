import Foundation

// MARK: - Connection model, reusable struct

public struct PrinterConnectionModel: Hashable {
    public let id = UUID()
    public let host: String
    public let port: String 
    public var state: ConnectionState = .disconnected
}

// MARK: - Connection state

public enum ConnectionState {
    case connecting
    case connected
    case disconnected
}
