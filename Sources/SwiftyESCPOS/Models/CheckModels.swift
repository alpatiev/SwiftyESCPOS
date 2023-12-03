import Foundation

// MARK: - CheckModel

public struct CheckModel: Decodable {
    public let success: Bool?
    public var data: DataClass?
    public let checkoutShift: CheckoutShift?
    
    public init(success: Bool?,
                data: DataClass?,
                checkoutShift: CheckoutShift?) {
        self.success = success
        self.data = data
        self.checkoutShift = checkoutShift
    }
}

// MARK: - CheckoutShift

public struct CheckoutShift: Decodable {
    public let status: Int?
    public let statusBool: Bool?
    public let idcheckoutshift: Int?
    public let checkoutShiftNumber: Int?
    public let checkoutShiftOpen: String?
    public let subdivisionsWithScheme: Int?
    public let subdivisionsWithSchemeBool: Bool?
    
    public init(status: Int?, statusBool: Bool?,
                idcheckoutshift: Int?,
                checkoutShiftNumber: Int?,
                checkoutShiftOpen: String?,
                subdivisionsWithScheme: Int?,
                subdivisionsWithSchemeBool: Bool?) {
        self.status = status
        self.statusBool = statusBool
        self.idcheckoutshift = idcheckoutshift
        self.checkoutShiftNumber = checkoutShiftNumber
        self.checkoutShiftOpen = checkoutShiftOpen
        self.subdivisionsWithScheme = subdivisionsWithScheme
        self.subdivisionsWithSchemeBool = subdivisionsWithSchemeBool
    }
}

// MARK: - DataClass

public struct DataClass: Decodable {
    public let header: Header?
    public let body: [Body]?
    public let tableBody: [TableBody]?
    public var tableFooter: TableFooter?
    public let footer: [String]?
    
    public init(header: Header?,
                body: [Body]?,
                tableBody: [TableBody]?,
                tableFooter: TableFooter?,
                footer: [String]?) {
        self.header = header
        self.body = body
        self.tableBody = tableBody
        self.tableFooter = tableFooter
        self.footer = footer
    }
}

// MARK: - Decodable

public struct Header: Decodable {
    public let logo: String?
    public let title: String?
    public let subtitle: [String]?
    
    public init(logo: String?,
                title: String?,
                subtitle: [String]?) {
        self.logo = logo
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: - Body

public struct Body: Decodable {
    public let title: String?
    public let value: Value?
    
    public init(title: String?,
                value: Value?) {
        self.title = title
        self.value = value
    }
}

public enum Value: Decodable {
    case integer(Int)
    case string(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(Value.self,
                                         DecodingError.Context(codingPath: decoder.codingPath,
                                                                           debugDescription: "Wrong type for Value"))
    }
    
    public var stringValue: String {
        switch self {
        case .integer(let intValue):
            return String(intValue)
        case .string(let strValue):
            return strValue
        }
    }
}

// MARK: - TableBody

public struct TableBody: Decodable {
    public let name: String?
    public let count: Int?
    public let sum: Double?
    public var opaque: Bool? = false
    
    public init(name: String?,
                count: Int?,
                sum: Double?,
                opaque: Bool?) {
        self.name = name
        self.count = count
        self.sum = sum
        self.opaque = opaque
    }
}

// MARK: - Check boody (products) aligment

enum TableBodyLimits: Int {
    case name = 24
    case count = 6
    case sum = 9
}

// MARK: -

extension TableBody {
    func limitedString(_ property: TableBodyLimits) -> String {
        switch property {
        case .name:
            if let existedName = name {
                let cut = existedName.prefix(property.rawValue)
                return paddedWithLimit(cut, property.rawValue)
            }
        case .count:
            if let existedCount = count {
                let cut = String(existedCount).prefix(property.rawValue)
                return paddedWithLimit(cut, property.rawValue)
            }
        case .sum:
            if let existedSum = sum {
                let formattedString = String(format: "%.2f", existedSum)
                let finalString = formattedString.hasSuffix(".00") ? formattedString : formattedString + ".00"
                let cut = finalString.prefix(property.rawValue)
                return paddedWithLimit(cut, property.rawValue)
            }
        }
        return ""
    }
    
    private func paddedWithLimit(_ string: String.SubSequence, _ limit: Int) -> String {
        let tailCount = limit - string.count
        let paddedString = string + String(repeating: " ", count: max(0, tailCount))
        return String(paddedString)
    }
}

// MARK: - TableFooter

public struct TableFooter: Decodable {
    public var discount: String?
    public var topayment: String?
    
    public init(discount: String? = nil, topayment: String? = nil) {
        self.discount = discount
        self.topayment = topayment
    }
}
