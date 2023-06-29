import Foundation

// MARK: - Reciept for printing

final class Reciept: NSObject {
    
    private let bytes = NSMutableData()
    
    // MARK: - Add bytes using UnsafeRawPointer
    
    private func addBytesCommand(command: UnsafeRawPointer, length: Int) {
        self.bytes.append(command, length: length)
    }
    
    // MARK: - Get data and refresh
    
    func getLatestData() -> NSMutableData { bytes }
    
    func refreshReciept() {
        bytes.setData(Data())
    }
    
    // MARK: - Creating a bytes sequence
    
    func printAddTextRU(text: String) {
        let cp866 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.dosRussian.rawValue)))
        
        if let data = text.data(using: cp866) {
            let size = data.count
            var textData = [UInt8](repeating:0, count:size)
            
            data.copyBytes(to: &textData, count: data.count)
            addBytesCommand(command: textData, length: size)
            
            if let decodedText = String(data: data, encoding: cp866) {
                print(decodedText)
            }
        }
    }
    
    func printSetupRussianCompatibility() {
        let char: [Int8] = [0x1B, 0x74, 0x11]
        addBytesCommand(command: char, length: char.count)
    }
    
    func printAndGotoNextLine() {
        let char: [Int8] = [0x0A]
        addBytesCommand(command: char, length: char.count)
    }
    
    func printStatus() {
        let char: [UInt8] = [0x10, 0x04, 0x01]
        addBytesCommand(command: char, length: char.count)
    }
    
    func printAbsolutePosition(location: Int) {
        var char: [UInt8] = [0x1B, 0x24]
        char.append(UInt8(location % 256))
        char.append(UInt8(location / 256))
        addBytesCommand(command: char, length: char.count)
    }
    
    func printDefaultLineSpace() {
        let char: [Int8] = [0x1B, 0x32]
        addBytesCommand(command: char, length: char.count)
    }
    
    func printInitialize() {
        let char: [Int8] = [0x1B, 0x40]
        addBytesCommand(command: char, length: char.count)
    }
    
    func printBoldCharModel(model: Int8) {
        var char: [Int8] = [0x1B, 0x45]
        char.append(model)
        addBytesCommand(command: char, length: char.count)
    }
    
    func printSelectFont(font: UInt8) {
        var char: [UInt8] = [0x1B, 0x4D]
        char.append(font)
        addBytesCommand(command: char, length: char.count)
    }
    
    func printSetStanderModel() {
        let char: [Int8] = [0x1B, 0x53]
        addBytesCommand(command: char, length: char.count)
    }
    
    func printAlignmentType(type: kAlignmentType){
        var char: [UInt8] = [0x1B, 0x61]
        char.append(type.rawValue)
        addBytesCommand(command: char, length: char.count)
    }
    
    func printShortOfPaper() {
        let char: [Int8] = [0x1B, 0x63, 0x33, 0x00]
        addBytesCommand(command: char, length: char.count)
    }
    
    func printOpenCashDrawer() {
        let char: [UInt8] = [0x1B, 0x70, 0x00, 0x80, 0xFF]
        addBytesCommand(command: char, length: char.count)
    }
    
    func printCharSize(scale: kCharScale) {
        var char: [UInt8] = [0x1D,0x21]
        char.append(scale.rawValue)
        addBytesCommand(command: char, length: char.count)
    }
    
    func printLeftMargin(nL: UInt8, nH: UInt8) {
        var char: [UInt8] = [0x1D,0x4C]
        char.append(nL)
        char.append(nH)
        addBytesCommand(command: char, length: char.count)
    }
    
    func printDotDistance(w: Float, h: Float) {
        var char: [UInt8] = [0x1D, 0x50]
        char.append(UInt8(25.4 / w))
        char.append(UInt8(25.4 / h))
        addBytesCommand(command: char, length: char.count)
    }
    
    func printCutPaper(model: kCutPaperModel, n: UInt8?) {
        var char: [UInt8] = [0x1D, 0x56]
        char.append(model.rawValue)
        if model.rawValue == kCutPaperModel.feedPaperHalfCut.rawValue {
            if let temp = n {
                char.append(temp)
            } else {
                char.append(0)
            }
        }
        addBytesCommand(command: char, length: char.count)
    }
    
    func printAreaWidth(width: Float) {
        var char: [UInt8] = [0x1D,0x57]
        let nL = UInt8((width / 0.1).truncatingRemainder(dividingBy: 256))
        let nH = UInt8(width / 0.1 / 256)
        char.append(nL)
        char.append(nH)
        addBytesCommand(command: char, length: char.count)
    }
    
    func printerSetMaximumWidth(n: Int) {
        let widthCommand: [UInt8] = [0x1B, 0x57, UInt8(n)]
        addBytesCommand(command: widthCommand, length: widthCommand.count)
    }
}
