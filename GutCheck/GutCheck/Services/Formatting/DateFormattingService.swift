//
//  DateFormattingService.swift
//  GutCheck
//
//  Centralized date formatting, built on Date.FormatStyle.
//
//  Two reasons this moved off DateFormatter:
//
//  Correctness. The old implementation formatted with fixed patterns like
//  "h:mm a" and "MMM d, yyyy". Those are not translations — they force
//  US conventions everywhere, so a reader whose region uses a 24-hour clock
//  still saw "2:30 PM", and day/month order never changed. FormatStyle asks
//  for *fields* and lets the region decide how to render them.
//
//  Safety. The old version cached DateFormatter instances in a dictionary
//  behind nonisolated statics callable from any thread. Racing on that
//  dictionary corrupts its storage rather than merely losing an entry: the
//  parallel test suite reproduced an abort inside Dictionary.setValue(_:forKey:).
//  It was patched with a Mutex; FormatStyle removes the need for either, since
//  the styles are Sendable value types with nothing to share.
//

import Foundation

/// Centralized date formatting service to ensure consistent date/time presentation
enum DateFormat {
    case date           // localized: abbreviated month, day, year
    case time          // localized: hour and minute
    case dateTime      // localized: date plus hour and minute
    case dayAndMonth   // localized: abbreviated month and day
    case weekday       // localized: full weekday name
    case shortWeekday  // localized: abbreviated weekday name
    case monthAndYear  // localized: full month and year
    case dayOnly       // day of month
    case mediumDate    // system medium date style
    case shortTime     // system short time style
    case mediumDateTime // medium date + short time

    /// An explicit pattern, for the rare case where a fixed machine-readable
    /// shape is genuinely wanted rather than a localized one.
    ///
    /// This is the one case still backed by `DateFormatter`: a pattern only
    /// known at runtime cannot be expressed as a `Date.FormatStyle`. Prefer
    /// any of the cases above for anything a person reads.
    case custom(String)

    /// The style used to render this format, or nil for `.custom`.
    var formatStyle: Date.FormatStyle? {
        switch self {
        case .date:
            .dateTime.year().month(.abbreviated).day()
        case .time:
            .dateTime.hour().minute()
        case .dateTime:
            .dateTime.year().month(.abbreviated).day().hour().minute()
        case .dayAndMonth:
            .dateTime.month(.abbreviated).day()
        case .weekday:
            .dateTime.weekday(.wide)
        case .shortWeekday:
            .dateTime.weekday(.abbreviated)
        case .monthAndYear:
            .dateTime.year().month(.wide)
        case .dayOnly:
            .dateTime.day()
        case .mediumDate:
            Date.FormatStyle(date: .abbreviated, time: .omitted)
        case .shortTime:
            Date.FormatStyle(date: .omitted, time: .shortened)
        case .mediumDateTime:
            Date.FormatStyle(date: .abbreviated, time: .shortened)
        case .custom:
            nil
        }
    }
}

enum DateFormattingService {

    static func string(from date: Date, format: DateFormat) -> String {
        if let style = format.formatStyle {
            return date.formatted(style)
        }
        guard case .custom(let pattern) = format else { return date.formatted() }
        return customFormatter(pattern: pattern).string(from: date)
    }

    static func date(from string: String, format: DateFormat) -> Date? {
        if let style = format.formatStyle {
            return try? Date(string, strategy: style.parseStrategy)
        }
        guard case .custom(let pattern) = format else { return nil }
        return customFormatter(pattern: pattern).date(from: string)
    }

    /// Built per call rather than cached.
    ///
    /// Caching is what made the old service unsafe, and `.custom` is rare
    /// enough that constructing a formatter costs less than the shared state
    /// would.
    private static func customFormatter(pattern: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = pattern
        return formatter
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
