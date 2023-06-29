import Foundation

// MARK: - CheckModel

struct CheckModel: Decodable {
    let success: Bool
    let data: DataClass
    let checkoutShift: CheckoutShift
}

// MARK: - CheckoutShift

struct CheckoutShift: Decodable {
    let status: Int
    let statusBool: Bool
    let idcheckoutshift, checkoutShiftNumber: Int
    let checkoutShiftOpen: String
    let subdivisionsWithScheme: Int
    let subdivisionsWithSchemeBool: Bool
}

// MARK: - DataClass

struct DataClass: Decodable {
    let header: Header
    let body: [Body]
    let tableBody: [TableBody]
    let tableFooter: TableFooter
    let footer: [String]
}

// MARK: - Body

struct Body: Decodable {
    let title: String
    let value: Value
}

enum Value: Decodable {
    case integer(Int)
    case string(String)

    init(from decoder: Decoder) throws {
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
    
    var stringValue: String {
        switch self {
        case .integer(let intValue):
            return String(intValue)
        case .string(let strValue):
            return strValue
        }
    }
}

// MARK: - Decodable

struct Header: Codable {
    let logo: String
    let title: String
    let subtitle: [String]
}

// MARK: - TableBody

struct TableBody: Decodable {
    let name: String
    let count: Int
    let price: Double
    let sum: Double
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

// MARK: - TableFooter

struct TableFooter: Decodable {
    let total, topayment: String
    let payment: [Payment]
}

// MARK: - Payment

struct Payment: Decodable {
    let title, value: String
}