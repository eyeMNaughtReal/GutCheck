//
//  ReminderSettings.swift
//  GutCheck
//

import Foundation

struct ReminderSettings: Identifiable, Codable, Hashable, Equatable, LocalRecord {
    var id: String = UUID().uuidString
    /// The local profile these settings belong to.
    var createdBy: String = ""

    // Meal Reminders — fires 15 min after each typical meal time
    var breakfastReminderEnabled: Bool = false
    var breakfastReminderTime: Date = ReminderSettings.defaultTime(hour: 7)
    var lunchReminderEnabled: Bool = false
    var lunchReminderTime: Date = ReminderSettings.defaultTime(hour: 12)
    var dinnerReminderEnabled: Bool = false
    var dinnerReminderTime: Date = ReminderSettings.defaultTime(hour: 18)

    // Other Daily Reminders
    var symptomReminderEnabled: Bool = false
    var symptomReminderTime: Date = Date.now
    var medicationReminderEnabled: Bool = false
    var medicationReminderTime: Date = Date.now
    var remindMeLaterInterval: Int = 15 // minutes

    // Weekly Reports
    var weeklyInsightEnabled: Bool = false
    var weeklyInsightTime: Date = Date.now

    // Insight Notifications — scheduled on-device once analysis finishes
    var newInsightsEnabled: Bool = true
    var patternAlertEnabled: Bool = true

    // Metadata
    var lastUpdated: Date = Date.now

    // MARK: - Helpers

    /// Returns a Date set to today at the given hour (minute 0) in the current calendar.
    static func defaultTime(hour: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date.now)
        components.hour = hour
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? Date.now
    }

    // MARK: - DataClassifiable Conformance

    var privacyLevel: DataPrivacyLevel { .public }

    // MARK: - Memberwise Initializer

    init(id: String = UUID().uuidString,
         createdBy: String = "",
         breakfastReminderEnabled: Bool = false,
         breakfastReminderTime: Date = ReminderSettings.defaultTime(hour: 7),
         lunchReminderEnabled: Bool = false,
         lunchReminderTime: Date = ReminderSettings.defaultTime(hour: 12),
         dinnerReminderEnabled: Bool = false,
         dinnerReminderTime: Date = ReminderSettings.defaultTime(hour: 18),
         symptomReminderEnabled: Bool = false,
         symptomReminderTime: Date = Date.now,
         medicationReminderEnabled: Bool = false,
         medicationReminderTime: Date = Date.now,
         remindMeLaterInterval: Int = 15,
         weeklyInsightEnabled: Bool = false,
         weeklyInsightTime: Date = Date.now,
         newInsightsEnabled: Bool = true,
         patternAlertEnabled: Bool = true) {
        self.id = id
        self.createdBy = createdBy
        self.breakfastReminderEnabled = breakfastReminderEnabled
        self.breakfastReminderTime = breakfastReminderTime
        self.lunchReminderEnabled = lunchReminderEnabled
        self.lunchReminderTime = lunchReminderTime
        self.dinnerReminderEnabled = dinnerReminderEnabled
        self.dinnerReminderTime = dinnerReminderTime
        self.symptomReminderEnabled = symptomReminderEnabled
        self.symptomReminderTime = symptomReminderTime
        self.medicationReminderEnabled = medicationReminderEnabled
        self.medicationReminderTime = medicationReminderTime
        self.remindMeLaterInterval = remindMeLaterInterval
        self.weeklyInsightEnabled = weeklyInsightEnabled
        self.weeklyInsightTime = weeklyInsightTime
        self.newInsightsEnabled = newInsightsEnabled
        self.patternAlertEnabled = patternAlertEnabled
        self.lastUpdated = Date.now
    }
}
