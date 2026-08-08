//
//  MealRiskModels.swift
//  GutCheck
//
//  Data models for meal risk prediction and severity assessment.
//

import Foundation
import SwiftUI

// MARK: - Risk Level

enum MealRiskLevel: String, Hashable, CaseIterable {
    /// Nothing to analyse — no ingredients, no compounds, no history.
    ///
    /// Distinct from `.low`, which means the food *was* analysed and came back
    /// clean. Collapsing the two is how a Big Mac scored a green 0 and read as
    /// "No known risk factors": the app had no idea what was in it.
    case unknown
    case low
    case moderate
    case high

    var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        default: return rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .unknown: return "questionmark.circle.fill"
        case .low: return "checkmark.shield.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high: return "xmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        // Deliberately not green. Unknown is not reassurance.
        case .unknown: return ColorTheme.secondaryText
        case .low: return ColorTheme.success
        case .moderate: return ColorTheme.warning
        case .high: return ColorTheme.error
        }
    }

}

// MARK: - Risk Data Source

enum RiskDataSource: String, Hashable {
    case historicalCorrelation
    case compoundAnalysis
    case combined
}

// MARK: - Food Item Risk Detail

struct FoodItemRiskDetail: Identifiable, Hashable {
    let id: UUID
    let foodName: String
    let riskScore: Int
    let riskLevel: MealRiskLevel
    let explanation: String
    let matchedTriggerPattern: TriggerPattern?
    let flaggedCompounds: [FoodCompound]
    let dataSource: RiskDataSource
}

// MARK: - Meal Risk Assessment

struct MealRiskAssessment: Hashable {
    let overallRiskScore: Int
    let overallRiskLevel: MealRiskLevel
    let foodItemRisks: [FoodItemRiskDetail]
    let overallExplanation: String
    let assessedAt: Date
    let hasHistoricalData: Bool

    var highRiskItems: [FoodItemRiskDetail] {
        foodItemRisks.filter { $0.riskLevel == .high }
    }

    var moderateRiskItems: [FoodItemRiskDetail] {
        foodItemRisks.filter { $0.riskLevel == .moderate }
    }
}
