//
//  TriggerPattern.swift
//  GutCheck
//
//  Rich trigger pattern model for symptom-food correlation analysis.
//

import Foundation

// MARK: - Trigger Score

/// Composite 0-100 score combining multiple signal dimensions.
struct TriggerScore: Hashable {
    let overall: Int
    let correlationComponent: Double
    let severityComponent: Double
    let recurrenceComponent: Double
    let compoundRiskComponent: Double
}

// MARK: - Severity Prediction

/// Predicts likely symptom severity if a food is eaten again.
struct SeverityPrediction: Hashable {
    let mostLikelyPainLevel: PainLevel
    let mostLikelyUrgencyLevel: UrgencyLevel
    let painDistribution: [PainLevel: Double]
    let urgencyDistribution: [UrgencyLevel: Double]
    let stoolRisk: StoolRiskLevel
    let confidence: Double
}

enum StoolRiskLevel: String, Hashable {
    case normal
    case constipation
    case loose
    case mixed
}

// MARK: - Ingredient Trigger Breakdown

/// Shows how a food breaks down into ingredients and their individual correlation.
struct IngredientTriggerBreakdown: Identifiable, Hashable {
    let id: UUID
    let ingredientName: String
    let compoundName: String?
    let compoundCategory: String?
    let correlationScore: Double
    let severity: HealthSeverity
    let occurrenceCount: Int
}

// MARK: - Timing Profile

struct TimingProfile: Hashable {
    let averageOnsetHours: Double
    let medianOnsetHours: Double
    let minOnsetHours: Double
    let maxOnsetHours: Double
}

// MARK: - Trigger Summary Insight

/// Natural language insight (e.g. "Dairy frequently leads to moderate-severe pain").
struct TriggerSummaryInsight: Identifiable, Hashable {
    let id: UUID
    let headline: String
    let detail: String
    let dataPoints: Int
    let confidence: Double
}

// MARK: - Trigger Pattern

/// Complete trigger profile for a single food.
struct TriggerPattern: Identifiable, Hashable {
    let id: UUID
    let foodName: String
    let triggerScore: TriggerScore
    let severityPrediction: SeverityPrediction
    let ingredientBreakdown: [IngredientTriggerBreakdown]
    let timingProfile: TimingProfile
    let summaryInsights: [TriggerSummaryInsight]
    let associatedSymptomLabels: [String]
    let totalObservations: Int
    let triggeringObservations: Int
    let recommendations: [String]
    let lastOccurrence: Date
    let firstOccurrence: Date
    let trendDirection: TrendDirection
}
