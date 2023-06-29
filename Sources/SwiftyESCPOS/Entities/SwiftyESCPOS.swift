import CocoaAsyncSocket

// MARK: - Printer delegate

public protocol BasePrinterDelegate: AnyObject {
    func connecting()
    func connected()
    func disconnected()
}

// MARK: - Main printer manager

public final class SwiftyESCPOS: NSObject {
    
    public weak var delegate: BasePrinterDelegate?
    private let reciept = RecieptManager()
    private var buffer: [UUID: ConnectionModel] = [:]
    private var model = ConnectionModel(host: "", port: 9100)

    public override init() {}
    
    public func defaultSetups() {
        reciept.printInitialize()
        reciept.printSetStanderModel()
        reciept.printDotDistance(w: 0.1, h: 0.1)
        reciept.printLeftMargin(nL: 20, nH: 0)
        reciept.printDefaultLineSpace()
        reciept.printAreaWidth(width: 80)
        reciept.printSelectFont(font: UInt8(48))
        reciept.printerSetMaximumWidth(n: 90)
    }
    
    public func refresh() {
        reciept.refreshReciept()
    }
    
    public func setupRussianCompatibility() {
        reciept.printSetupRussianCompatibility()
    }
    
    public func writeBoldModeManual(_ value: Bool) {
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
   
    public func writeData_item(items: [String]) {
        reciept.printCharSize(scale: kCharScale.scale_1)
        reciept.printAlignmentType(type: .LeftAlignment)
       
        for item in items {
            reciept.printAddTextRU(text: item)
            reciept.printAndGotoNextLine()
        }
    }
    
    public func writeData_bold_item(_ item: String) {
        reciept.printCharSize(scale: kCharScale.scale_1)
        reciept.printAlignmentType(type: .LeftAlignment)
        reciept.printBoldCharModel(model: 1)
        reciept.printAddTextRU(text: item)
        reciept.printAndGotoNextLine()
        reciept.printBoldCharModel(model: 0)
    }
    
    public func printReceipt() -> NSData {
        reciept.printCutPaper(model: kCutPaperModel.feedPaperHalfCut, n: 10)
        return reciept.getLatestData()
    }
    
    public func checkPaper() {
        reciept.printShortOfPaper()
    }
    
    public func openCashDrawer() {
        reciept.printOpenCashDrawer()
    }
    
    public func writeData_line() {
        reciept.printAddTextRU(text: "-----------------------------------------")
        reciept.printAndGotoNextLine()
    }
    
    public func writeCenterLine() {
        writeData_Title(title: "----------------------------------------", scale: .scale_1)
    }
    
    public func writeData_insert(_ text: String, bold: Bool, nextLine: Bool) {
        reciept.printBoldCharModel(model: bold ? 1 : 0)
        reciept.printCharSize(scale: kCharScale.scale_1)
        reciept.printAddTextRU(text: text)
        reciept.printBoldCharModel(model: 0)
        
        if nextLine {
            reciept.printAndGotoNextLine()
        }
    }
    
    // MARK: - - - - - - - - - -
    
    
    // MARK: - Private properties
    
    private lazy var printerSocket: GCDAsyncSocket = {
        let socket = GCDAsyncSocket()
        socket.delegateQueue = .main
        socket.delegate = self
        return socket
    }()
    
  
    
    // TODO: - Add protocols
    
    public func configureHost(_ string: String) {
        model.host = string
    }
    
    public func configurePort(_ string: String) {
        if let port = UInt16(string) {
            model.port = port
        }
    }
    
    public func estabilishConnection() {
        delegate?.connecting()
        connectToSocket()
    }
    
    public func interruptAnyConnections() {
        disconnectSocket()
    }
    
    public func writeString(_ string: String) {
        writeData_line()
        writeData_item(items: [string])
        writeData_line()
    }
    
    public func sendDataToPrinter() {
        sendToSocket(printReceipt())
    }
    
    public func printCheckFromData(_ data: Data) -> Bool {
        guard let checkModel = decodeFromData(data: data) else { return false }
        printCheck(checkModel)
        return true
    }
    
    // MARK: - Main print methods - config
    
    private func printCheck(_ model: CheckModel) {
        printHeader(model)
        printBody(model)
        printProducts(model)
        printBottom(model)
        printAdditional(model)
        sendDataToPrinter()
    }
    
    private func printHeader(_ model: CheckModel) {
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
    
    private func printBody(_ model: CheckModel) {
        writeData_item(items: [])
        
        for element in model.data.body {
            let title = element.title.padPrefix(20)
            let value = element.value.stringValue.padPrefix(18)
            
            writeData_insert(title, bold: false, nextLine: false)
            writeData_insert(value, bold: false, nextLine: true)
        }
    }
    
    private func printProducts(_ model: CheckModel) {
        writeData_insert(" ", bold: false, nextLine: true)
        writeCenterLine()
        writeData_insert(" ", bold: false, nextLine: true)
        printTable(model.data.tableBody)
        writeData_insert(" ", bold: false, nextLine: true)
        writeCenterLine()
        writeData_insert(" ", bold: false, nextLine: true)
        writeData_item(items: [""])

    }
    
    private func printBottom(_ model: CheckModel) {
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
    
    private func printAdditional(_ model: CheckModel) {
        writeData_item(items: [""])
        
        for footerItem in model.data.footer {
            writeData_Title(title: footerItem, scale: .scale_1, bold: true)
        }
        
    }
    
    private func splitSubtitleIntoWords(_ subtitles: String, limit: Int) -> [String] {
        let words = subtitles.components(separatedBy: " ")
        var result: [String] = []
        var currentLine = ""
        
        for word in words {
            if currentLine.isEmpty {
                currentLine = word
            } else if currentLine.count + word.count + 1 <= limit {
                currentLine += " \(word)"
            } else {
                result.append(currentLine)
                currentLine = word
            }
        }
        
        if !currentLine.isEmpty {
            result.append(currentLine)
        }
        
        return result
    }
    
    
    // MARK: - Sockets methods
        
    private func connectToSocket() {
        guard printerSocket.isDisconnected else {
            print("* ALREADY CONNECTED - STOP CONNECTING")
            delegate?.disconnected()
            return
        }
        
        do {
            try printerSocket.connect(toHost: model.host, onPort: model.port)
        } catch let error {
            print("* CONNECTION ERROR - \(error.localizedDescription)")
        }
    }
    
    private func disconnectSocket() {
        printerSocket.disconnect()
    }
    
    private func sendToSocket(_ data: NSData) {
        printerSocket.write(Data(data), withTimeout: -1, tag: 0)
        print("* WRITE TO SOCKET NEW DATA [\(data.debugDescription)]")
    }
}



extension SwiftyESCPOS {
    func printTable(_ tableBody: [TableBody]) {
        let title = "Наименование".pad(.name) + " " + "Кол-во".pad(.count) + " " + "Сумма".pad(.sum)
        var lines = [String]()
        
        for element in tableBody {
            let name = element.limitedString(.name)
            let count = String(centered(element.count).prefix(6))
            let sum = element.limitedString(.sum)
            
            lines.append("\(name) \(count) \(sum)")
        }
        print(title.count)
        print(lines.first!.count)
        writeData_bold_item(title)
        writeData_item(items: lines)
    }
 
}

enum TableBodyLimits: Int {
    case name = 24
    case count = 6
    case sum = 9
}

extension TableBody {
    func limitedString(_ property: TableBodyLimits) -> String {
        switch property {
        case .name:
            let cut = name.prefix(property.rawValue)
            return paddedWithLimit(cut, property.rawValue)
        case .count:
            let cut = String(count).prefix(property.rawValue)
            return paddedWithLimit(cut, property.rawValue)
        case .sum:
            let formattedString = String(format: "%.2f", sum)
            let finalString = formattedString.hasSuffix(".00") ? formattedString : formattedString + ".00"
            let cut = finalString.prefix(property.rawValue)
            return paddedWithLimit(cut, property.rawValue)
        }
    }
    
    private func paddedWithLimit(_ string: String.SubSequence, _ limit: Int) -> String {
        let tailCount = limit - string.count
        let paddedString = string + String(repeating: " ", count: max(0, tailCount))
        return String(paddedString)
    }
}

extension String {
    func pad( _ limit: TableBodyLimits) -> String {
        pad(limit.rawValue)
    }

    func pad(_ limit: Int) -> String {
        let tailCount = limit - self.count
        return self + String(repeating: " ", count: max(0, tailCount))
    }
    func padPrefix(_ limit: Int) -> String {
        let cut = self.prefix(limit)
        let tailCount = limit - cut.count
        return self + String(repeating: " ", count: max(0, tailCount))
    }
}

extension SwiftyESCPOS {
    func centered(_ number: Int) -> String {
        var str = String(number)
        let length = str.count
        
        if length % 2 == 1 {
           str = str.padding(toLength: length + 2, withPad: " ", startingAt: 0)
        }
        
        let xCount = (length % 2 == 0) ? max(0, 4 - length) : max(0, 3 - length)
        let xString = String(repeating: " ", count: xCount)
        
        return "\(xString)\(str)\(xString)"
    }
}

// MARK: - GCDAsyncSocketDelegate implementation

extension SwiftyESCPOS: GCDAsyncSocketDelegate {
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("* CONNECTED TO [\(host) - \(port)]")
        defaultSetups()
        setupRussianCompatibility()
        delegate?.connected()
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("* DISCONNECTED TO [\(sock.description) - \(err?.localizedDescription ?? "no error")]")
        delegate?.disconnected()
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("* SUCCESSFULLY SENDED DATA")
        refresh()
    }
}

// MARK: - Example of decoding check data

extension SwiftyESCPOS {
    private func decodeFromData(data: Data) -> CheckModel? {
        do {
            let model = try JSONDecoder().decode(CheckModel.self, from: data)
            return model
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
}
