//
//  StoredReminderSettings.swift
//  GutCheck
//
//  SwiftData entity backing the `ReminderSettings` domain struct.
//

import Foundation
import SwiftData

@Model
final class StoredReminderSettings {
    @Attribute(.unique) var id: String

    /// The owning local profile id. Kept so settings survive a profile reset in
    /// the same shape the rest of the app expects.
    var createdBy: String

    var breakfastReminderEnabled: Bool
    var breakfastReminderTime: Date
    var lunchReminderEnabled: Bool
    var lunchReminderTime: Date
    var dinnerReminderEnabled: Bool
    var dinnerReminderTime: Date

    var symptomReminderEnabled: Bool
    var symptomReminderTime: Date
    var medicationReminderEnabled: Bool
    var medicationReminderTime: Date
    var remindMeLaterInterval: Int

    var weeklyInsightEnabled: Bool
    var weeklyInsightTime: Date

    var newInsightsEnabled: Bool
    var patternAlertEnabled: Bool

    var lastUpdated: Date

    init(
        id: String,
        createdBy: String,
        breakfastReminderEnabled: Bool,
        breakfastReminderTime: Date,
        lunchReminderEnabled: Bool,
        lunchReminderTime: Date,
        dinnerReminderEnabled: Bool,
        dinnerReminderTime: Date,
        symptomReminderEnabled: Bool,
        symptomReminderTime: Date,
        medicationReminderEnabled: Bool,
        medicationReminderTime: Date,
        remindMeLaterInterval: Int,
        weeklyInsightEnabled: Bool,
        weeklyInsightTime: Date,
        newInsightsEnabled: Bool,
        patternAlertEnabled: Bool,
        lastUpdated: Date
    ) {
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
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Domain mapping

extension StoredReminderSettings {
    convenience init(_ settings: ReminderSettings) {
        self.init(
            id: settings.id,
            createdBy: settings.createdBy,
            breakfastReminderEnabled: settings.breakfastReminderEnabled,
            breakfastReminderTime: settings.breakfastReminderTime,
            lunchReminderEnabled: settings.lunchReminderEnabled,
            lunchReminderTime: settings.lunchReminderTime,
            dinnerReminderEnabled: settings.dinnerReminderEnabled,
            dinnerReminderTime: settings.dinnerReminderTime,
            symptomReminderEnabled: settings.symptomReminderEnabled,
            symptomReminderTime: settings.symptomReminderTime,
            medicationReminderEnabled: settings.medicationReminderEnabled,
            medicationReminderTime: settings.medicationReminderTime,
            remindMeLaterInterval: settings.remindMeLaterInterval,
            weeklyInsightEnabled: settings.weeklyInsightEnabled,
            weeklyInsightTime: settings.weeklyInsightTime,
            newInsightsEnabled: settings.newInsightsEnabled,
            patternAlertEnabled: settings.patternAlertEnabled,
            lastUpdated: Date.now
        )
    }

    func apply(_ settings: ReminderSettings) {
        createdBy = settings.createdBy
        breakfastReminderEnabled = settings.breakfastReminderEnabled
        breakfastReminderTime = settings.breakfastReminderTime
        lunchReminderEnabled = settings.lunchReminderEnabled
        lunchReminderTime = settings.lunchReminderTime
        dinnerReminderEnabled = settings.dinnerReminderEnabled
        dinnerReminderTime = settings.dinnerReminderTime
        symptomReminderEnabled = settings.symptomReminderEnabled
        symptomReminderTime = settings.symptomReminderTime
        medicationReminderEnabled = settings.medicationReminderEnabled
        medicationReminderTime = settings.medicationReminderTime
        remindMeLaterInterval = settings.remindMeLaterInterval
        weeklyInsightEnabled = settings.weeklyInsightEnabled
        weeklyInsightTime = settings.weeklyInsightTime
        newInsightsEnabled = settings.newInsightsEnabled
        patternAlertEnabled = settings.patternAlertEnabled
        lastUpdated = Date.now
    }

    var domainModel: ReminderSettings {
        var settings = ReminderSettings(
            id: id,
            createdBy: createdBy,
            breakfastReminderEnabled: breakfastReminderEnabled,
            breakfastReminderTime: breakfastReminderTime,
            lunchReminderEnabled: lunchReminderEnabled,
            lunchReminderTime: lunchReminderTime,
            dinnerReminderEnabled: dinnerReminderEnabled,
            dinnerReminderTime: dinnerReminderTime,
            symptomReminderEnabled: symptomReminderEnabled,
            symptomReminderTime: symptomReminderTime,
            medicationReminderEnabled: medicationReminderEnabled,
            medicationReminderTime: medicationReminderTime,
            remindMeLaterInterval: remindMeLaterInterval,
            weeklyInsightEnabled: weeklyInsightEnabled,
            weeklyInsightTime: weeklyInsightTime,
            newInsightsEnabled: newInsightsEnabled,
            patternAlertEnabled: patternAlertEnabled
        )
        settings.lastUpdated = lastUpdated
        return settings
    }
}
