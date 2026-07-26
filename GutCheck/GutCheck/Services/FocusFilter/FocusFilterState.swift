//
//  FocusFilterState.swift
//  GutCheck
//
//  Tracks which notification categories are suppressed by an active iOS Focus Filter.
//

import Foundation

struct FocusFilterState {

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let mealRemindersSuppressed = "focusFilter.mealRemindersSuppressed"
        static let symptomRemindersSuppressed = "focusFilter.symptomRemindersSuppressed"
        static let medicationRemindersSuppressed = "focusFilter.medicationRemindersSuppressed"
        static let weeklyInsightsSuppressed = "focusFilter.weeklyInsightsSuppressed"
    }

    // MARK: - Read

    static var mealRemindersSuppressed: Bool {
        UserDefaults.standard.bool(forKey: Keys.mealRemindersSuppressed)
    }

    static var symptomRemindersSuppressed: Bool {
        UserDefaults.standard.bool(forKey: Keys.symptomRemindersSuppressed)
    }

    static var medicationRemindersSuppressed: Bool {
        UserDefaults.standard.bool(forKey: Keys.medicationRemindersSuppressed)
    }

    static var weeklyInsightsSuppressed: Bool {
        UserDefaults.standard.bool(forKey: Keys.weeklyInsightsSuppressed)
    }

    // MARK: - Write

    static func update(
        mealRemindersSuppressed: Bool,
        symptomRemindersSuppressed: Bool,
        medicationRemindersSuppressed: Bool,
        weeklyInsightsSuppressed: Bool
    ) {
        let defaults = UserDefaults.standard
        defaults.set(mealRemindersSuppressed, forKey: Keys.mealRemindersSuppressed)
        defaults.set(symptomRemindersSuppressed, forKey: Keys.symptomRemindersSuppressed)
        defaults.set(medicationRemindersSuppressed, forKey: Keys.medicationRemindersSuppressed)
        defaults.set(weeklyInsightsSuppressed, forKey: Keys.weeklyInsightsSuppressed)
    }

    static func clearAll() {
        update(
            mealRemindersSuppressed: false,
            symptomRemindersSuppressed: false,
            medicationRemindersSuppressed: false,
            weeklyInsightsSuppressed: false
        )
    }
}
