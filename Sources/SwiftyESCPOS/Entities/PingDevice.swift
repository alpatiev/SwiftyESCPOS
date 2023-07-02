import CocoaAsyncSocket

// MARK: - Deivce delegate

protocol PingDelegate: AnyObject {
    func finishedWithResult(device: PingDevice, ableToConnect: Bool, host: String, port: String)
}

// MARK: - Device entity. Manages connection status, socket status

final class PingDevice: NSObject {
    
    weak var delegate: PingDelegate?
    
    private let host: String
    private let port: UInt16
    private let wait: TimeInterval
    
    private lazy var socket: GCDAsyncSocket = {
        let socket = GCDAsyncSocket()
        socket.delegateQueue = .main
        socket.delegate = self
        return socket
    }()
    
    init(host: String, port: UInt16, wait: TimeInterval = 0.2) {
        self.host = host
        self.port = port
        self.wait = wait
    }
    
    func pingOnce() {
        do {
            try socket.connect(toHost: host, onPort: port, withTimeout: wait)
        } catch {
            notifyDelegate(false)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) { [weak self] in
            self?.notifyDelegate(false)
        }
    }
    
    private func notifyDelegate(_ result: Bool) {
        socket.disconnect()
        delegate?.finishedWithResult(device: self, ableToConnect: result, host: host, port: String(port))
    }
}

extension PingDevice: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        if host == self.host, port == self.port {
            notifyDelegate(true)
        }
    }
}
