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
    private var configuration: PrinterConfiguration
    private var language: PrinterLanguage
    private var isPreviousWorkfinished = true
    private var shouldEstabilishConnection = false
    private lazy var socket: GCDAsyncSocket = {
        let socket = GCDAsyncSocket()
        socket.delegateQueue = .main
        socket.delegate = self
        return socket
    }()
    
    // MARK: - Lifecycle
    
    init(with model: PrinterConnectionModel, configuration: PrinterConfiguration, language: PrinterLanguage) {
        self.model = model
        self.configuration = configuration
        self.language = language
    }
    
    // MARK: - Socket methods
    
    func connect() {
        guard model.state == .disconnected, let port = UInt16(model.port) else { return }
        
        model.state = .connecting
        
        do {
            shouldEstabilishConnection = true
            try socket.connect(toHost: model.host, onPort: port, withTimeout: -1)
        } catch let error {
            print("* CONNECTION ERROR - \(error.localizedDescription)")
        }
    }
    
    func disconnect() {
        shouldEstabilishConnection = false
        socket.disconnect()
    }
    
    func sendToPrinter(_ data: NSMutableData) {
        socket.write(Data(data), withTimeout: -1, tag: 0)
    }
    
    func sendToPrinter(_ model: CheckModel) {
        guard self.model.state == .connected, isPreviousWorkfinished else { return }
        recieptInitializePrinting()
        recieptSetRussainCompatibility()
        let config = reciept.getLatestData() as Data
        writeReciept(with: 0, data: config, tag: 1)
                
        recieptPrepareHeader(model)
        let header = reciept.getLatestData() as Data
        reciept.refreshReciept()
        writeReciept(with: 0.1, data: header, tag: 2)
        
        recieptPrepareBody(model)
        let body = reciept.getLatestData() as Data
        reciept.refreshReciept()
        writeReciept(with: 0.2, data: body, tag: 3)
        
        recieptPrepareProducts(model)
        let products = reciept.getLatestData() as Data
        reciept.refreshReciept()
        writeReciept(with: 0.3, data: products, tag: 4)
        
        recieptPrepareBottom(model)
        let bottom = reciept.getLatestData() as Data
        reciept.refreshReciept()
        writeReciept(with: 0.4, data: bottom, tag: 5)
        
        recieptPrepareAdditional(model)
        let additional = reciept.getLatestData() as Data
        reciept.refreshReciept()
        writeReciept(with: 0.5, data: additional, tag: 6)
        
        recieptPrepareCutPaper()
        let cutPaper = reciept.getLatestData() as Data
        reciept.refreshReciept()
        writeReciept(with: 0.6, data: cutPaper, tag: 7, isPreviousWorkFinished: true)
    }
    
    // MARK: - Initialize and configure
    
    private func recieptInitializePrinting() {
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
    }
    
    private func recieptSetRussainCompatibility() {
        switch language {
        case .russian:
            reciept.printSetupRussianCompatibility()
        }
    }
    
    private func writeReciept(with timeout: Double, data: Data, tag: Int, isPreviousWorkFinished: Bool = false) {
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            self?.socket.write(data, withTimeout: -1, tag: tag)
            self?.isPreviousWorkfinished = isPreviousWorkFinished
        }
    }
}

// MARK: - GCDAsyncSocketDelegate methods

extension Printer: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("* SEND DATA TO \(model.host) : \(model.host) WITH TAG: \(tag)")
    }
     
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("* CONNECTED TO [\(host) - \(port)]")
        model.state = .connected
        delegate?.connected(from: self)
       
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("* DISCONNECTED TO [\(sock.description) - \(err?.localizedDescription ?? "no error")]")
        model.state = .disconnected
        delegate?.disconnected(from: self)
        
        if shouldEstabilishConnection {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                if self?.shouldEstabilishConnection == true {
                    self?.connect()
                }
            }
        }
    }
}

// MARK: Check model print implementation

private extension Printer {
    
    // MARK: - Create sequence of bytes which prints check divided by areas
    
    func recieptPrepareHeader(_ model: CheckModel) {
        reciept.printInitialize()
        writeData_item(items: [""])
        
        if let existedTitle = model.data?.header?.title {
            let cutHeaderName = String(existedTitle.prefix(40))
            writeData_Title(title: "", scale: .scale_1, bold: true)
            writeData_Title(title: cutHeaderName, scale: .scale_1, bold: true)
        }
      
        if let existedSubtitles = model.data?.header?.subtitle {
            for line in existedSubtitles {
                for subline in splitSubtitleIntoWords(line, limit: 40) {
                    writeData_Title(title: subline, scale: .scale_1, bold: true)
                }
            }
        }
       
        writeData_insert(" ", bold: false, nextLine: true)
    }
    
    func recieptPrepareBody(_ model: CheckModel) {
        writeData_item(items: [])
        
        if let existedBody = model.data?.body {
            for element in existedBody {
                if let existedTitle = element.title, let existedValue = element.value?.stringValue {
                    let title = existedTitle.padPrefix(20)
                    let value = existedValue.padPrefix(18)
                    
                    writeData_insert(title, bold: false, nextLine: false)
                    writeData_insert(value, bold: false, nextLine: true)
                }
            }
        }
    }
    
    private func recieptPrepareProducts(_ model: CheckModel) {
        writeData_insert(" ", bold: false, nextLine: true)
        writeCenterLine()
        writeData_insert(" ", bold: false, nextLine: true)
        
        let title = "Наименование".pad(.name) + " " + "Кол-во".pad(.count) + " " + "Сумма".pad(.sum)
        writeData_bold_item(title)
        
        if let existedTableBody = model.data?.tableBody {
            for element in existedTableBody {
                //let opaque = element.opaque ?? false
                let name = element.limitedString(.name)
                let count = Printer.centeredSixDigitsFrom(element.count ?? 0)
                let sum = element.limitedString(.sum)
                let line = "\(name) \(count) \(sum)"
                
                writeData_insert(line, bold: false, nextLine: true)
            }
        }
       
        writeData_insert(" ", bold: false, nextLine: true)
        writeCenterLine()
        writeData_insert(" ", bold: false, nextLine: true)
        writeData_item(items: [""])
    }
    
    func recieptPrepareBottom(_ model: CheckModel) {
        let shift: Int = 20
        
        guard let toPayValue = model.data?.tableFooter?.topayment else { return }
        
        if let discountValueRaw = model.data?.tableFooter?.discount {
            let discountValueWrapped: String
            if discountValueRaw.last == "%" {
                let removedPercentBuffer = discountValueRaw.replacingOccurrences(of: "%", with: " ")
                let removedSpacesBuffer = removedPercentBuffer.replacingOccurrences(of: " ", with: "")
                if let discountDouble = Double(removedSpacesBuffer) {
                    discountValueWrapped = String(Int(discountDouble)) + " %"
                } else {
                    discountValueWrapped = discountValueRaw
                }
            } else {
                discountValueWrapped = discountValueRaw
            }
            let discountNameString = "Скидка".padPrefix(shift)
            let discountValueString = discountValueWrapped.padPrefix(shift)
            let discountResultString = discountNameString + discountValueString
            writeData_insert(discountResultString, bold: true, nextLine: true, charSize: .scale_2)
            writeSetCharSize(.scale_1)
        }
        
        let toPayNameString = "К оплате".padPrefix(shift)
        let toPayValueString = toPayValue.padPrefix(shift)
        let toPayResultString = toPayNameString + toPayValueString
        writeData_insert(toPayResultString, bold: true, nextLine: true, charSize: .scale_2)
        writeSetCharSize(.scale_1)
    }
    
    func recieptPrepareAdditional(_ model: CheckModel) {
        writeData_item(items: [""])
        
        if let existedFooter = model.data?.footer {
            for footerItem in existedFooter {
                writeData_Title(title: footerItem, scale: .scale_1, bold: true)
            }
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
    
    func writeData_insert(_ text: String, bold: Bool, nextLine: Bool, charSize: kCharScale = .scale_1) {
        reciept.printBoldCharModel(model: bold ? 1 : 0)
        reciept.printCharSize(scale: charSize)
        reciept.printAlignmentType(type: .LeftAlignment) // ?? added after success reciepts. Maybe wrong command
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
    
    func writeSetCharSize(_ size: kCharScale) {
        reciept.printCharSize(scale: size)
    }
}
