//
//  NutrientValueParser.swift
//  GutCheck
//
//  Reads numbers back out of the `nutritionDetails` string dictionary.
//
//  This lived as a static on `UnifiedFoodDetailView`, which meant the sibling
//  `NutritionDetailsView` could not reach it through `Self`. Parsing a label
//  string is not view behaviour, so it lives here and both views call it.
//

import Foundation

enum NutrientValueParser {

    /// Reads a number out of a label string, tolerating both comma conventions.
    ///
    /// Writers use a fixed `en_US_POSIX` locale with grouping disabled, so new
    /// values always use `.` and carry no separators. Values persisted by an
    /// earlier build were written in the device locale and may use either, so:
    ///
    /// - a comma followed by exactly three trailing digits is thousands
    ///   grouping — `"1,093"` → `1093`
    /// - anything else is a decimal separator — `"460,5"` → `460.5`
    ///
    /// Getting that backwards is a factor-of-1000 error in one direction or a
    /// factor-of-10 in the other.
    static func number(from raw: String) -> Double? {
        let digitsAndSeparators = raw.filter { $0.isNumber || $0 == "." || $0 == "," }

        let normalized: String
        if digitsAndSeparators.contains(","), !digitsAndSeparators.contains(".") {
            let isGrouping = digitsAndSeparators.range(
                of: #"^\d{1,3}(,\d{3})+$"#,
                options: .regularExpression
            ) != nil
            normalized = isGrouping
                ? digitsAndSeparators.replacingOccurrences(of: ",", with: "")
                : digitsAndSeparators.replacingOccurrences(of: ",", with: ".")
        } else {
            // Mixed separators mean the comma is grouping: "1,093.5".
            normalized = digitsAndSeparators.replacingOccurrences(of: ",", with: "")
        }

        return Double(normalized)
    }
}
