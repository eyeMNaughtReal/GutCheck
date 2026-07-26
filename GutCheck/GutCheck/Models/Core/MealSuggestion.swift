//
//  MealSuggestion.swift
//  GutCheck
//
//  Model for safe meal suggestions based on historical data analysis.
//

import SwiftUI

/// A meal suggestion derived from the user's history with safety scoring.
struct MealSuggestion: Identifiable, Hashable {
    let id: UUID
    let mealName: String
    let mealType: MealType
    let foodItems: [String]
    let safetyScore: Int
    let timesEaten: Int
    let lastEaten: Date
    let reasoning: String

    /// Color representing the safety level of this meal suggestion.
    var safetyColor: Color {
        if safetyScore >= 80 { return ColorTheme.success }
        if safetyScore >= 50 { return .yellow }
        return .orange
    }
}
