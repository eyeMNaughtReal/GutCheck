import Foundation

enum NumberFormat {
    case decimal(places: Int)
    case percent
    case calories
    case weight
    case custom(formatter: NumberFormatter)
    
    var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        switch self {
        case .decimal(let places):
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = places
            formatter.maximumFractionDigits = places
        case .percent:
            formatter.numberStyle = .percent
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 1
        case .calories:
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
        case .weight:
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 1
            formatter.maximumFractionDigits = 1
        case .custom(let customFormatter):
            return customFormatter
        }
        return formatter
    }
}

final class NumberFormattingService {
    private static let shared = NumberFormattingService()
    
    private var formatters: [String: NumberFormatter] = [:]
    
    private func formatter(for format: NumberFormat) -> NumberFormatter {
        let key = String(describing: format)
        if let existingFormatter = formatters[key] {
            return existingFormatter
        }
        
        let formatter = format.formatter
        formatters[key] = formatter
        return formatter
    }
    
    static func string(from number: NSNumber, format: NumberFormat) -> String {
        shared.formatter(for: format).string(from: number) ?? "\(number)"
    }
    
    static func string(from double: Double, format: NumberFormat) -> String {
        string(from: NSNumber(value: double), format: format)
    }
    
    static func string(from int: Int, format: NumberFormat) -> String {
        string(from: NSNumber(value: int), format: format)
    }
}

// MARK: - Convenience Extensions

extension Double {
    var formatted: String {
        NumberFormattingService.string(from: self, format: .decimal(places: 2))
    }
    
    var formattedPercent: String {
        NumberFormattingService.string(from: self, format: .percent)
    }
    
    var formattedWeight: String {
        NumberFormattingService.string(from: self, format: .weight)
    }
}

extension Int {
    var formattedCalories: String {
        NumberFormattingService.string(from: self, format: .calories)
    }
}

// MARK: - Usage Example
// let calories = 256
// calories.formattedCalories // "256"
//
// let weight = 75.5
// weight.formattedWeight // "75.5"
//
// let percentage = 0.856
// percentage.formattedPercent // "85.6%"
