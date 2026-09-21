//
//  NumberFormattingService.swift
//  GutCheck
//
//  Centralized number formatting, built on FloatingPointFormatStyle.
//
//  Same two reasons as DateFormattingService: the cached NumberFormatter
//  dictionary was an unsynchronized shared mutable store reachable from any
//  thread (it aborted the parallel test suite inside
//  Dictionary.setValue(_:forKey:)), and format styles are Sendable value types
//  with nothing to cache or guard.
//

import Foundation

enum NumberFormat {
    case decimal(places: Int)
    case percent
    case calories
    case weight
}

enum NumberFormattingService {

    static func string(from double: Double, format: NumberFormat) -> String {
        switch format {
        case .decimal(let places):
            double.formatted(.number.precision(.fractionLength(places)))
        case .percent:
            // The style multiplies by 100, matching NumberFormatter's
            // percent behaviour, so callers keep passing a fraction.
            double.formatted(.percent.precision(.fractionLength(0...1)))
        case .calories:
            double.formatted(.number.precision(.fractionLength(0)))
        case .weight:
            double.formatted(.number.precision(.fractionLength(1)))
        }
    }

    static func string(from int: Int, format: NumberFormat) -> String {
        string(from: Double(int), format: format)
    }

    static func string(from number: NSNumber, format: NumberFormat) -> String {
        string(from: number.doubleValue, format: format)
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
