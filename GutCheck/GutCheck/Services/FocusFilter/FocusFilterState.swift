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

    /// Serializes access to the four keys.
    ///
    /// UserDefaults is already thread-safe for an individual key, so the risk
    /// isn't a corrupt read — it's a torn one. iOS can invoke
    /// `GutCheckFocusFilter.perform()` on a background thread while
    /// ReminderSettingsService reads these on the main thread, and because
    /// `update` writes four keys in sequence a reader could otherwise observe a
    /// half-applied filter (meals suppressed, symptoms not yet written) and
    /// schedule notifications the Focus was meant to silence.
    private static let lock = NSLock()

    // MARK: - Snapshot

    /// All four flags read together under one lock.
    /// Prefer this when acting on more than one flag, so the values are
    /// guaranteed to come from the same update.
    struct Snapshot {
        let mealRemindersSuppressed: Bool
        let symptomRemindersSuppressed: Bool
        let medicationRemindersSuppressed: Bool
        let weeklyInsightsSuppressed: Bool
    }

    static var current: Snapshot {
        lock.lock()
        defer { lock.unlock() }
        let defaults = UserDefaults.standard
        return Snapshot(
            mealRemindersSuppressed: defaults.bool(forKey: Keys.mealRemindersSuppressed),
            symptomRemindersSuppressed: defaults.bool(forKey: Keys.symptomRemindersSuppressed),
            medicationRemindersSuppressed: defaults.bool(forKey: Keys.medicationRemindersSuppressed),
            weeklyInsightsSuppressed: defaults.bool(forKey: Keys.weeklyInsightsSuppressed)
        )
    }

    // MARK: - Read

    static var mealRemindersSuppressed: Bool { current.mealRemindersSuppressed }

    static var symptomRemindersSuppressed: Bool { current.symptomRemindersSuppressed }

    static var medicationRemindersSuppressed: Bool { current.medicationRemindersSuppressed }

    static var weeklyInsightsSuppressed: Bool { current.weeklyInsightsSuppressed }

    // MARK: - Write

    static func update(
        mealRemindersSuppressed: Bool,
        symptomRemindersSuppressed: Bool,
        medicationRemindersSuppressed: Bool,
        weeklyInsightsSuppressed: Bool
    ) {
        lock.lock()
        defer { lock.unlock() }
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
