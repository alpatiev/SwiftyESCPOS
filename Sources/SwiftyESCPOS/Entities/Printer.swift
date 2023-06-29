import CocoaAsyncSocket

// MARK: - Printer delegate

protocol PrinterDelegate: AnyObject {
    func connecting(from printer: Printer)
    func connected(from printer: Printer)
    func disconnected(from printer: Printer)
}

// MARK: - Printer entity. Manages connection status, socket status

final class Printer: NSObject {
    
    // MARK: - Private properties
    
    weak var delegate: PrinterDelegate?
    var model: PrinterConnectionModel
    private let reciept = Reciept()
    private lazy var socket: GCDAsyncSocket = {
        let socket = GCDAsyncSocket()
        socket.delegateQueue = .main
        socket.delegate = self
        return socket
    }()
    
    // MARK: - Lifecycle
    
    init(with model: PrinterConnectionModel, configuration: PrinterConfiguration, language: PrinterLanguage) {
        self.model = model
        
        switch configuration {
        case .defaultConfiguration:
            reciept.printInitialize()
            reciept.printSetStanderModel()
            reciept.printDotDistance(w: 0.1, h: 0.1)
            reciept.printLeftMargin(nL: 20, nH: 0)
            reciept.printDefaultLineSpace()
            reciept.printAreaWidth(width: 80)
            reciept.printSelectFont(font: UInt8(48))
            reciept.printerSetMaximumWidth(n: 90)
        }
        
        switch language {
        case .russian:
            reciept.printSetupRussianCompatibility()
        }
    }
    
    // MARK: - Socket methods
    
    func connect() {
        guard model.state == .disconnected, let port = UInt16(model.port) else { return }
        
        model.state = .connecting
        
        do {
            try socket.connect(toHost: model.host, onPort: port, withTimeout: -1)
        } catch let error {
            print("* CONNECTION ERROR - \(error.localizedDescription)")
        }
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    func sendToPrinter(_ data: NSMutableData) {
        socket.write(Data(data), withTimeout: -1, tag: 0)
    }
    
    func sendToPrinter(_ model: CheckModel) {
        recieptPrepareHeader(model)
        recieptPrepareBody(model)
        recieptPrepareProducts(model)
        recieptPrepareBottom(model)
        recieptPrepareAdditional(model)
        recieptPrepareCutPaper()
        socket.write(reciept.getLatestData() as Data, withTimeout: -1, tag: 0)
        reciept.refreshReciept()
    }
}

// MARK: - GCDAsyncSocketDelegate methods

extension Printer: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("* CONNECTED TO [\(host) - \(port)]")
        model.state = .connected
        delegate?.connected(from: self)
       
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("* DISCONNECTED TO [\(sock.description) - \(err?.localizedDescription ?? "no error")]")
        model.state = .disconnected
        delegate?.disconnected(from: self)
        connect()
    }
}

// MARK: Check model print implementation

private extension Printer {
    
    // MARK: - Create sequence of bytes which prints check divided by areas
    
    func recieptPrepareHeader(_ model: CheckModel) {
        let cutHeaderName = String(model.data.header.title.prefix(40))
        writeData_Title(title: "", scale: .scale_1, bold: true)
        writeData_Title(title: cutHeaderName, scale: .scale_1, bold: true)
        
        for line in model.data.header.subtitle {
            for subline in splitSubtitleIntoWords(line, limit: 40) {
                writeData_Title(title: subline, scale: .scale_1, bold: true)
            }
        }
        
        writeData_insert(" ", bold: false, nextLine: true)
    }
    
    func recieptPrepareBody(_ model: CheckModel) {
        writeData_item(items: [])
        
        for element in model.data.body {
            let title = element.title.padPrefix(20)
            let value = element.value.stringValue.padPrefix(18)
            
            writeData_insert(title, bold: false, nextLine: false)
            writeData_insert(value, bold: false, nextLine: true)
        }
    }
    
    private func recieptPrepareProducts(_ model: CheckModel) {
        writeData_insert(" ", bold: false, nextLine: true)
        writeCenterLine()
        writeData_insert(" ", bold: false, nextLine: true)
        
        let title = "Наименование".pad(.name) + " " + "Кол-во".pad(.count) + " " + "Сумма".pad(.sum)
        var lines = [String]()
        
        for element in model.data.tableBody {
            let name = element.limitedString(.name)
            let count = Printer.centeredSixDigitsFrom(element.count)
            let sum = element.limitedString(.sum)
            lines.append("\(name) \(count) \(sum)")
        }
        
        writeData_bold_item(title)
        writeData_item(items: lines)
        writeData_insert(" ", bold: false, nextLine: true)
        writeCenterLine()
        writeData_insert(" ", bold: false, nextLine: true)
        writeData_item(items: [""])
    }
    
    func recieptPrepareBottom(_ model: CheckModel) {
        let shift: Int = 20
        
        let toPayName = "К оплате".padPrefix(shift)
        let toPayValue =  model.data.tableFooter.topayment.padPrefix(shift).replacingOccurrences(of: "₽", with: "Р")
        let toPay = toPayName + toPayValue
        writeData_insert(toPay, bold: true, nextLine: true)
        for paymentItem in model.data.tableFooter.payment {
            let title = paymentItem.title.padPrefix(shift)
            let value = paymentItem.value.padPrefix(shift).replacingOccurrences(of: "₽", with: "Р")
            print(value)
            writeData_insert(title, bold: false, nextLine: false)
            writeData_insert(value, bold: true, nextLine: true)
        }
    }
    
    func recieptPrepareAdditional(_ model: CheckModel) {
        writeData_item(items: [""])
        
        for footerItem in model.data.footer {
            writeData_Title(title: footerItem, scale: .scale_1, bold: true)
        }
    }
    
    func recieptPrepareCutPaper() {
        reciept.printCutPaper(model: kCutPaperModel.feedPaperHalfCut, n: 10)
    }
    
    // MARK: - Write to reciept directly
    
    func writeBoldModeManual(_ value: Bool) {
        reciept.printBoldCharModel(model: value ? 1 : 0)
    }
    
    func writeData_Title(title: String, scale: kCharScale?, bold: Bool = false) {
        reciept.printAlignmentType(type: .MiddleAlignment)
        reciept.printBoldCharModel(model: bold ? 1 : 0)
        
        if let charScale: kCharScale = scale {
            reciept.printCharSize(scale: charScale)
        }
        
        reciept.printAddTextRU(text: title)
        reciept.printAndGotoNextLine()
        reciept.printBoldCharModel(model: 0)
    }
    
    func writeData_item(items: [String]) {
        reciept.printCharSize(scale: kCharScale.scale_1)
        reciept.printAlignmentType(type: .LeftAlignment)
        
        for item in items {
            reciept.printAddTextRU(text: item)
            reciept.printAndGotoNextLine()
        }
    }
    
    func writeData_bold_item(_ item: String) {
        reciept.printCharSize(scale: kCharScale.scale_1)
        reciept.printAlignmentType(type: .LeftAlignment)
        reciept.printBoldCharModel(model: 1)
        reciept.printAddTextRU(text: item)
        reciept.printAndGotoNextLine()
        reciept.printBoldCharModel(model: 0)
    }
    
    func writeData_line() {
        reciept.printAddTextRU(text: "-----------------------------------------")
        reciept.printAndGotoNextLine()
    }
    
    func writeCenterLine() {
        writeData_Title(title: "----------------------------------------", scale: .scale_1)
    }
    
    func writeData_insert(_ text: String, bold: Bool, nextLine: Bool) {
        reciept.printBoldCharModel(model: bold ? 1 : 0)
        reciept.printCharSize(scale: kCharScale.scale_1)
        reciept.printAddTextRU(text: text)
        reciept.printBoldCharModel(model: 0)
        
        if nextLine {
            reciept.printAndGotoNextLine()
        }
    }
    
    func writeString(_ string: String) {
        writeData_line()
        writeData_item(items: [string])
        writeData_line()
    }
}
