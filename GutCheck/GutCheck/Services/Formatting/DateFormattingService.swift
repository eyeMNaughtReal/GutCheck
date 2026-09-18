import Foundation
import Synchronization

/// Centralized date formatting service to ensure consistent date/time presentation
enum DateFormat {
    case date           // "MMM d, yyyy"
    case time          // "h:mm a"
    case dateTime      // "MMM d, yyyy h:mm a"
    case dayAndMonth   // "MMM d"
    case weekday       // "EEEE"
    case shortWeekday  // "E"
    case monthAndYear  // "MMMM yyyy"
    case dayOnly       // "d"
    case mediumDate    // Uses system medium date style
    case shortTime     // Uses system short time style
    case mediumDateTime // Medium date + short time
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
        case .shortWeekday:
            return "E"
        case .monthAndYear:
            return "MMMM yyyy"
        case .dayOnly:
            return "d"
        case .mediumDate, .mediumDateTime, .shortTime:
            return "" // These use dateStyle/timeStyle instead of dateFormat
        case .custom(let format):
            return format
        }
    }
    
    func apply(to formatter: DateFormatter) {
        switch self {
        case .mediumDate:
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        case .shortTime:
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        case .mediumDateTime:
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
        default:
            formatter.dateFormat = formatString
        }
    }
}

final class DateFormattingService {

    /// Cache of configured formatters, keyed by format.
    ///
    /// Behind a `Mutex` for the same reason as `NumberFormattingService`: these
    /// statics are nonisolated and callable from any thread, and racing on the
    /// dictionary corrupts its storage rather than merely losing an entry.
    ///
    /// Only the dictionary needs guarding — each `DateFormatter` is configured
    /// once here and afterwards only read.
    private static let formatters = Mutex<[String: DateFormatter]>([:])

    private static func formatter(for format: DateFormat) -> DateFormatter {
        let key = String(describing: format)
        return formatters.withLock { cache in
            if let existingFormatter = cache[key] {
                return existingFormatter
            }
            let formatter = DateFormatter()
            format.apply(to: formatter)
            cache[key] = formatter
            return formatter
        }
    }

    static func string(from date: Date, format: DateFormat) -> String {
        formatter(for: format).string(from: date)
    }

    static func date(from string: String, format: DateFormat) -> Date? {
        formatter(for: format).date(from: string)
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
