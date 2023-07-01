import CocoaAsyncSocket

// MARK: - Printer delegate

public protocol SwiftyESCPOSDelegate: AnyObject {
    func devices(didUpdatePrinters models: [PrinterConnectionModel])
}

// MARK: - Main printer manager

public final class SwiftyESCPOS: NSObject {
    
    // MARK: - Properties
    
    public weak var delegate: SwiftyESCPOSDelegate?
    private let reciept = Reciept()
    private var printersModels = [PrinterConnectionModel]()
    private var printerManagedObjects = Set<Printer>()
    
    // MARK: - Lifecycle
    
    public override init() {}
    
    // MARK: - Public methods
    
    public func create(new printer: PrinterConnectionModel) {
        uniqueConnection(printer) { [weak self] isUnique in
            if isUnique {
                let printerObject = Printer(with: printer, configuration: .defaultConfiguration, language: .russian)
                printerObject.delegate = self
                self?.printersModels.append(printer)
                self?.printerManagedObjects.insert(printerObject)
                self?.updateListAndNotifyDelegate()
            }
        }
    }
    
    public func create(new printers: [PrinterConnectionModel]) {
        for printer in printers {
            let printerObject = Printer(with: printer, configuration: .defaultConfiguration, language: .russian)
            printerObject.delegate = self
            printersModels.append(printer)
            printerManagedObjects.insert(printerObject)
        }
        
        updateListAndNotifyDelegate()
    }
    
    public func delete(with selection: PrinterSelection) {
        switch selection {
        case .all:
            printersModels.removeAll()
            printerManagedObjects.removeAll()
            updateListAndNotifyDelegate()
        case .selected(let printerConnectionModel):
            selectPrinter(printerConnectionModel) { [weak self] printer in
                DispatchQueue.main.async {
                    if let printerObject = printer {
                        self?.printerManagedObjects.remove(printerObject)
                    }
                    
                    if let index = self?.printersModels.firstIndex(where: { $0.id == printerConnectionModel.id }) {
                        self?.printersModels.remove(at: index)
                    }
                    
                    self?.updateListAndNotifyDelegate()
                }
            }
        }
    }
    
    public func connect(with selection: PrinterSelection) {
        switch selection {
        case .all:
            selectAllPrinters { $0?.connect() }
        case .selected(let printerConnectionModel):
            selectPrinter(printerConnectionModel) { $0?.connect() }
        }
    }
    
    public func disconnect(with selection: PrinterSelection) {
        switch selection {
        case .all:
            selectAllPrinters { $0?.disconnect() }
        case .selected(let printerConnectionModel):
            selectPrinter(printerConnectionModel) { $0?.disconnect() }
        }
    }
    
    public func printData(with selection: PrinterSelection, from data: Data) {
        switch selection {
        case .all:
            selectAllPrinters { printer in
                printer?.sendToPrinter(NSMutableData(data: data))
            }
        case .selected(let printerConnectionModel):
            selectPrinter(printerConnectionModel) { printer in
                printer?.sendToPrinter(NSMutableData(data: data))
            }
        }
    }
    
    public func printCheck(with selection: PrinterSelection, from data: Data) {
        do {
            let model = try JSONDecoder().decode(CheckModel.self, from: data)
            switch selection {
            case .all:
                selectAllPrinters { printer in
                    printer?.sendToPrinter(model)
                }
            case .selected(let printerConnectionModel):
                selectPrinter(printerConnectionModel) { printer in
                    printer?.sendToPrinter(model)
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    public func printCheck(with selection: PrinterSelection, from model: CheckModel) {
        switch selection {
        case .all:
            selectAllPrinters { printer in
                printer?.sendToPrinter(model)
            }
        case .selected(let printerConnectionModel):
            selectPrinter(printerConnectionModel) { printer in
                printer?.sendToPrinter(model)
            }
        }
    }
    
    // MARK: - Check if the same connection already exist
    
    private func uniqueConnection(_ connectionModel: PrinterConnectionModel, _ completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let pointer = self else { completion(false); return }
            let flag = pointer.printersModels.contains(where: { SwiftyESCPOS.equal(lhs: $0, rhs: connectionModel) })
            completion(!flag)
        }
    }
    
    // MARK: - Connect socket to printer
    
    private func selectAllPrinters(_ completion: @escaping (Printer?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.printerManagedObjects.forEach { completion($0) }
        }
    }
    
    private func selectPrinter(_ connectionModel: PrinterConnectionModel, _ completion: @escaping (Printer?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            let result = self?.printerManagedObjects.first(where: { SwiftyESCPOS.equal(lhs: $0.model, rhs: connectionModel) })
            completion(result)
        }
    }
    
    
    // MARK: - Update and sync connection models to delegate
    
    private func updateConnectionModels(with printer: Printer) {
        guard let index = printersModels.firstIndex(where: { SwiftyESCPOS.equal(lhs: $0, rhs: printer.model) }) else { return }
        printersModels[index] = printer.model
        updateListAndNotifyDelegate()
    }
    
    private func updateListAndNotifyDelegate() {
        delegate?.devices(didUpdatePrinters: printersModels)
    }
}

// MARK: - PrinterDelegate implementation, where each one printer send its own socket updates

extension SwiftyESCPOS: PrinterDelegate {
    func connecting(from printer: Printer) {
        updateConnectionModels(with: printer)
    }
    
    func connected(from printer: Printer) {
        updateConnectionModels(with: printer)
    }
    
    func disconnected(from printer: Printer) {
        updateConnectionModels(with: printer)
    }
}

extension SwiftyESCPOS {
    static func equal(lhs: PrinterConnectionModel, rhs: PrinterConnectionModel) -> Bool {
        (lhs.host == rhs.host) && (lhs.port == rhs.port)
    }
}
