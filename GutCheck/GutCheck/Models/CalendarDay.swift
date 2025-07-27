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
}
