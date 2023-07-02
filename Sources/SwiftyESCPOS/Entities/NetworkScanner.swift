import Foundation

// MARK: - Port scanner delegate

public protocol NetworkScannerDelegate: AnyObject {
    func devices(didFindOpenPorts model: PrinterConnectionModel)
}

// TODO: Add finding host, not only checking open ports

final class NetworkScanner: NSObject {
    
    weak var delegate: NetworkScannerDelegate?
    private var buffer = Set<PingDevice>()
    private let expectedPorts: [UInt16] = [9100, 8100, 6100]
    
    func pingHost(_ host: String) {
        for port in expectedPorts {
            let device = PingDevice(host: host, port: port)
            device.delegate = self
            buffer.insert(device)
            device.pingOnce()
        }
    }
}

// MARK: - Notify when find open ports

extension NetworkScanner: PingDelegate {
    func finishedWithResult(device: PingDevice, ableToConnect: Bool, host: String, port: String) {
        if ableToConnect {
            delegate?.devices(didFindOpenPorts: PrinterConnectionModel(host: host, port: port))
        }
        
        buffer.remove(device)
    }
}
