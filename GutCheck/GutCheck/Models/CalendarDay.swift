//
//  CalendarDay.swift
//  GutCheck
//
//  Model for calendar day representation
//

import Foundation

struct CalendarDay: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let isCurrentMonth: Bool
    let hasEntries: Bool
    let entryTypes: Set<EntryType>
    var meals: [Meal] = []
    var symptoms: [Symptom] = []
    var correlation: DayCorrelation?
    
    enum EntryType: String, Codable, CaseIterable {
        case meals
        case symptom
        case both
    }
    
    // Computed properties for view compatibility
    var hasMeals: Bool {
        return !meals.isEmpty || entryTypes.contains(.meals) || entryTypes.contains(.both)
    }
    
    var hasSymptoms: Bool {
        return !symptoms.isEmpty || entryTypes.contains(.symptom) || entryTypes.contains(.both)
    }
    
    var hasCorrelation: Bool {
        correlation != nil
    }
}

// MARK: - Day Correlation

/// Lightweight summary of detected food-to-symptom correlations for a calendar day
struct DayCorrelation: Codable {
    /// Food names from meals that preceded symptoms within the correlation window
    let triggerFoodNames: [String]
    /// Number of correlated symptoms
    let symptomCount: Int
    /// Highest severity among correlated symptoms
    let severity: CorrelationSeverity
}

enum CorrelationSeverity: String, Codable, Comparable {
    case low
    case medium
    case high
    
    private var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
    
    static func < (lhs: CorrelationSeverity, rhs: CorrelationSeverity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
    
    /// Determine severity from symptom pain and urgency levels
    static func from(painLevel: PainLevel, urgencyLevel: UrgencyLevel) -> CorrelationSeverity {
        switch (painLevel, urgencyLevel) {
        case (.severe, _), (_, .urgent):
            return .high
        case (.moderate, _), (_, .moderate):
            return .medium
        default:
            return .low
        }
    }
}
