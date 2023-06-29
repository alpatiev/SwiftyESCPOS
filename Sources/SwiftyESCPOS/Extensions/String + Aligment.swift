
// MARK: - Text aligment methods

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

extension Printer {
    static func centeredSixDigitsFrom(_ number: Int) -> String {
        var str = String(number)
        let length = str.count
        
        if length % 2 == 1 {
           str = str.padding(toLength: length + 2, withPad: " ", startingAt: 0)
        }
        
        let xCount = (length % 2 == 0) ? max(0, 4 - length) : max(0, 3 - length)
        let xString = String(repeating: " ", count: xCount)
        
        return String("\(xString)\(str)\(xString)".prefix(6))
    }
    
    func splitSubtitleIntoWords(_ subtitles: String, limit: Int) -> [String] {
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
}
