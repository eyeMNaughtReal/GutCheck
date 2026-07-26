//
//  ReminderSettings.swift
//  GutCheck
//
//  Created for Firebase integration of reminder settings
//

import Foundation
import FirebaseFirestore

struct ReminderSettings: Identifiable, Codable, Hashable, Equatable, FirestoreModel {
    var id: String = UUID().uuidString
    var createdBy: String = ""  // Firebase UID - required for FirestoreModel

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

    // Smart Notifications (server-triggered via FCM)
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
    var requiresLocalStorage: Bool { privacyLevel == .private || privacyLevel == .confidential }
    var allowsCloudSync: Bool { privacyLevel == .public }

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

    // MARK: - FirestoreModel Implementation

    init(from document: DocumentSnapshot) throws {
        let data = document.data()
        guard let data = data else {
            throw RepositoryError.invalidData("Document data is nil")
        }

        self.id = document.documentID

        guard let createdBy = data["createdBy"] as? String else {
            throw RepositoryError.invalidData("Missing or invalid createdBy field")
        }
        self.createdBy = createdBy

        // Meal reminders
        self.breakfastReminderEnabled = data["breakfastReminderEnabled"] as? Bool ?? false
        self.lunchReminderEnabled     = data["lunchReminderEnabled"]     as? Bool ?? false
        self.dinnerReminderEnabled    = data["dinnerReminderEnabled"]    as? Bool ?? false

        // Other daily reminders
        self.symptomReminderEnabled   = data["symptomReminderEnabled"]   as? Bool ?? false
        self.medicationReminderEnabled = data["medicationReminderEnabled"] as? Bool ?? false

        // Smart notifications
        self.newInsightsEnabled  = data["newInsightsEnabled"]  as? Bool ?? true
        self.patternAlertEnabled = data["patternAlertEnabled"] as? Bool ?? true

        self.remindMeLaterInterval = data["remindMeLaterInterval"] as? Int ?? 15

        // Meal time fields — fall back to sensible defaults when not yet in Firestore
        if let ts = data["breakfastReminderTime"] as? Timestamp {
            self.breakfastReminderTime = ts.dateValue()
        } else {
            self.breakfastReminderTime = ReminderSettings.defaultTime(hour: 7)
        }

        if let ts = data["lunchReminderTime"] as? Timestamp {
            self.lunchReminderTime = ts.dateValue()
        } else {
            self.lunchReminderTime = ReminderSettings.defaultTime(hour: 12)
        }

        if let ts = data["dinnerReminderTime"] as? Timestamp {
            self.dinnerReminderTime = ts.dateValue()
        } else {
            self.dinnerReminderTime = ReminderSettings.defaultTime(hour: 18)
        }

        if let ts = data["symptomReminderTime"] as? Timestamp {
            self.symptomReminderTime = ts.dateValue()
        } else {
            self.symptomReminderTime = Date.now
        }

        if let ts = data["medicationReminderTime"] as? Timestamp {
            self.medicationReminderTime = ts.dateValue()
        } else {
            self.medicationReminderTime = Date.now
        }

        if let ts = data["weeklyInsightTime"] as? Timestamp {
            self.weeklyInsightTime = ts.dateValue()
        } else {
            self.weeklyInsightTime = Date.now
        }

        self.weeklyInsightEnabled = data["weeklyInsightEnabled"] as? Bool ?? false

        if let ts = data["lastUpdated"] as? Timestamp {
            self.lastUpdated = ts.dateValue()
        } else {
            self.lastUpdated = Date.now
        }
    }

    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "createdBy": createdBy,
            // Meal reminders
            "breakfastReminderEnabled": breakfastReminderEnabled,
            "breakfastReminderTime": Timestamp(date: breakfastReminderTime),
            "lunchReminderEnabled": lunchReminderEnabled,
            "lunchReminderTime": Timestamp(date: lunchReminderTime),
            "dinnerReminderEnabled": dinnerReminderEnabled,
            "dinnerReminderTime": Timestamp(date: dinnerReminderTime),
            // Other daily reminders
            "symptomReminderEnabled": symptomReminderEnabled,
            "symptomReminderTime": Timestamp(date: symptomReminderTime),
            "medicationReminderEnabled": medicationReminderEnabled,
            "medicationReminderTime": Timestamp(date: medicationReminderTime),
            "remindMeLaterInterval": remindMeLaterInterval,
            // Weekly reports
            "weeklyInsightEnabled": weeklyInsightEnabled,
            "weeklyInsightTime": Timestamp(date: weeklyInsightTime),
            // Smart notifications
            "newInsightsEnabled": newInsightsEnabled,
            "patternAlertEnabled": patternAlertEnabled,
            // Metadata
            "lastUpdated": Timestamp(date: Date.now),
            "createdAt": Timestamp(date: Date.now)
        ]
    }
}
