//
//  NutritionScaling.swift
//  GutCheck
//
//  Scales an already-built food item's nutrition to a different portion.
//
//  `FoodSearchResult` can rescale before it builds anything, because it still
//  holds typed numbers. By the time a `FoodItem` exists the micronutrients are
//  strings in `nutritionDetails`, and the serving picker has to move those too
//  — before this existed, doubling the serving doubled Calories while
//  Saturated Fat and every vitamin stayed put.
//

import Foundation

enum NutritionScaling {

    /// Units whose value scales with the portion.
    ///
    /// Deliberately a *format* rule rather than a list of nutrient labels.
    /// `nutritionDetails` also carries non-nutrient entries — "brand" is written
    /// straight into it — and a second copy of the label vocabulary is exactly
    /// what drifted out of sync in #362. Anything that is not a bare number
    /// followed by one of these units is left alone.
    private static let scalableUnits: Set<String> = ["g", "mg", "mcg", "kcal"]

    static func scaled(_ nutrition: NutritionInfo, by factor: Double) -> NutritionInfo {
        NutritionInfo(
            // Rounded rather than truncated: 261 kcal at 2.05 servings is
            // 535.05, and `Int()` would report that as 535 by luck and 534 the
            // moment the factor moved a hair the other way.
            calories: nutrition.calories.map { Int((Double($0) * factor).rounded()) },
            protein: nutrition.protein.map { $0 * factor },
            carbs: nutrition.carbs.map { $0 * factor },
            fat: nutrition.fat.map { $0 * factor },
            fiber: nutrition.fiber.map { $0 * factor },
            sugar: nutrition.sugar.map { $0 * factor },
            sodium: nutrition.sodium.map { $0 * factor }
        )
    }

    /// Scales every `"<number><unit>"` entry, leaving everything else untouched.
    static func scaled(_ details: [String: String], by factor: Double) -> [String: String] {
        details.mapValues { scaledValue($0, by: factor) }
    }

    private static func scaledValue(_ value: String, by factor: Double) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespaces)

        guard let numberRange = trimmed.range(of: #"^[0-9][0-9.,]*"#, options: .regularExpression) else {
            return value
        }

        let unit = trimmed[numberRange.upperBound...].trimmingCharacters(in: .whitespaces)
        guard scalableUnits.contains(unit.lowercased()) else { return value }
        guard let number = NutrientValueParser.number(from: String(trimmed[numberRange])) else { return value }

        // Written back through the same formatter that produced it, so the
        // fixed `en_US_POSIX` separator convention `NutrientValueParser`
        // depends on survives the round trip.
        return "\(FoodSearchResult.amount(number * factor))\(unit)"
    }
}
