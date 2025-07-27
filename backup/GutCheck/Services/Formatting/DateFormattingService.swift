import Foundation

/// Centralized date formatting service to ensure consistent date/time presentation
enum DateFormat {
    case date
    case time
    case dateTime
    case dayAndMonth
    case weekday
    case monthAndYear
    case custom(String)
    
    var formatString: String {
        switch self {
        case .date:
            return "MMM d, yyyy"
        case .time:
            return "h:mm a"
        case .dateTime:
            return "MMM d, yyyy h:mm a"
        case .dayAndMonth:
            return "MMM d"
        case .weekday:
            return "EEEE"
        case .monthAndYear:
            return "MMMM yyyy"
        case .custom(let format):
            return format
        }
    }
}

final class DateFormattingService {
    private static let shared = DateFormattingService()
    
    private var formatters: [String: DateFormatter] = [:]
    
    private func formatter(for format: DateFormat) -> DateFormatter {
        let key = format.formatString
        if let existingFormatter = formatters[key] {
            return existingFormatter
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = key
        formatters[key] = formatter
        return formatter
    }
    
    static func string(from date: Date, format: DateFormat) -> String {
        shared.formatter(for: format).string(from: date)
    }
    
    static func date(from string: String, format: DateFormat) -> Date? {
        shared.formatter(for: format).date(from: string)
    }
}

// MARK: - Date Extensions

extension Date {
    var formattedDate: String {
        DateFormattingService.string(from: self, format: .date)
    }
    
    var formattedTime: String {
        DateFormattingService.string(from: self, format: .time)
    }
    
    var formattedDateTime: String {
        DateFormattingService.string(from: self, format: .dateTime)
    }
    
    var monthAndDay: String {
        DateFormattingService.string(from: self, format: .dayAndMonth)
    }
    
    var weekdayName: String {
        DateFormattingService.string(from: self, format: .weekday)
    }
}
