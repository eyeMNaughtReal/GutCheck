//
//  WeeklyTriggerReport.swift
//  GutCheck
//
//  Weekly trigger report model for week-over-week food trigger comparison.
//

import Foundation

// MARK: - Trend Direction

enum TrendDirection: String, Hashable {
    case improving
    case worsening
    case stable

    var icon: String {
        switch self {
        case .improving: return "arrow.down.right"
        case .worsening: return "arrow.up.right"
        case .stable: return "minus"
        }
    }
}

// MARK: - Trigger Entry

struct TriggerEntry: Identifiable, Hashable {
    let id: UUID
    let foodName: String
    let correlationCount: Int
    let confidence: Double
    let averageOnsetHours: Double
    let associatedSymptoms: [String]
    let recommendations: [String]
}

// MARK: - Weekly Trigger Report

struct WeeklyTriggerReport: Identifiable, Hashable {
    let id: UUID
    let generatedDate: Date
    let weekStart: Date
    let weekEnd: Date
    let newTriggers: [TriggerEntry]
    let recurringTriggers: [TriggerEntry]
    let resolvedTriggers: [TriggerEntry]
    let currentWeekSymptomCount: Int
    let previousWeekSymptomCount: Int
    let currentWeekMealCount: Int
    let previousWeekMealCount: Int

    var totalTriggerCount: Int {
        newTriggers.count + recurringTriggers.count
    }

    var symptomTrend: TrendDirection {
        if currentWeekSymptomCount < previousWeekSymptomCount { return .improving }
        if currentWeekSymptomCount > previousWeekSymptomCount { return .worsening }
        return .stable
    }

    var symptomChangePercentage: Int {
        guard previousWeekSymptomCount > 0 else {
            return currentWeekSymptomCount > 0 ? 100 : 0
        }
        let change = Double(currentWeekSymptomCount - previousWeekSymptomCount) / Double(previousWeekSymptomCount) * 100
        return Int(change)
    }
}
