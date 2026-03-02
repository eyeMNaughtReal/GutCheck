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

    // Daily Reminders
    var mealReminderEnabled: Bool = false
    var mealReminderTime: Date = Date()
    var symptomReminderEnabled: Bool = false
    var symptomReminderTime: Date = Date()
    var medicationReminderEnabled: Bool = false
    var medicationReminderTime: Date = Date()
    var remindMeLaterInterval: Int = 15 // minutes

    // Weekly Reports
    var weeklyInsightEnabled: Bool = false
    var weeklyInsightTime: Date = Date()

    // Smart Notifications (server-triggered via FCM)
    var newInsightsEnabled: Bool = true
    var patternAlertEnabled: Bool = true

    // Metadata
    var lastUpdated: Date = Date()
    
    // MARK: - DataClassifiable Conformance
    
    /// Privacy level for reminder settings
    /// Reminder settings are considered public as they don't contain sensitive personal information
    var privacyLevel: DataPrivacyLevel {
        return .public
    }
    
    /// Whether reminder settings require local encrypted storage
    var requiresLocalStorage: Bool {
        return privacyLevel == .private || privacyLevel == .confidential
    }
    
    /// Whether reminder settings can be synced to the cloud
    var allowsCloudSync: Bool {
        return privacyLevel == .public
    }
    
    // MARK: - Initializers
    init(id: String = UUID().uuidString,
         createdBy: String = "",
         mealReminderEnabled: Bool = false,
         mealReminderTime: Date = Date(),
         symptomReminderEnabled: Bool = false,
         symptomReminderTime: Date = Date(),
         medicationReminderEnabled: Bool = false,
         medicationReminderTime: Date = Date(),
         remindMeLaterInterval: Int = 15,
         weeklyInsightEnabled: Bool = false,
         weeklyInsightTime: Date = Date(),
         newInsightsEnabled: Bool = true,
         patternAlertEnabled: Bool = true) {
        self.id = id
        self.createdBy = createdBy
        self.mealReminderEnabled = mealReminderEnabled
        self.mealReminderTime = mealReminderTime
        self.symptomReminderEnabled = symptomReminderEnabled
        self.symptomReminderTime = symptomReminderTime
        self.medicationReminderEnabled = medicationReminderEnabled
        self.medicationReminderTime = medicationReminderTime
        self.remindMeLaterInterval = remindMeLaterInterval
        self.weeklyInsightEnabled = weeklyInsightEnabled
        self.weeklyInsightTime = weeklyInsightTime
        self.newInsightsEnabled = newInsightsEnabled
        self.patternAlertEnabled = patternAlertEnabled
        self.lastUpdated = Date()
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
        
        self.mealReminderEnabled = data["mealReminderEnabled"] as? Bool ?? false
        self.symptomReminderEnabled = data["symptomReminderEnabled"] as? Bool ?? false
        self.medicationReminderEnabled = data["medicationReminderEnabled"] as? Bool ?? false
        self.weeklyInsightEnabled = data["weeklyInsightEnabled"] as? Bool ?? false
        self.newInsightsEnabled = data["newInsightsEnabled"] as? Bool ?? true
        self.patternAlertEnabled = data["patternAlertEnabled"] as? Bool ?? true
        self.remindMeLaterInterval = data["remindMeLaterInterval"] as? Int ?? 15

        // Handle date fields
        if let mealTimestamp = data["mealReminderTime"] as? Timestamp {
            self.mealReminderTime = mealTimestamp.dateValue()
        } else {
            self.mealReminderTime = Date()
        }

        if let symptomTimestamp = data["symptomReminderTime"] as? Timestamp {
            self.symptomReminderTime = symptomTimestamp.dateValue()
        } else {
            self.symptomReminderTime = Date()
        }

        if let medicationTimestamp = data["medicationReminderTime"] as? Timestamp {
            self.medicationReminderTime = medicationTimestamp.dateValue()
        } else {
            self.medicationReminderTime = Date()
        }

        if let weeklyTimestamp = data["weeklyInsightTime"] as? Timestamp {
            self.weeklyInsightTime = weeklyTimestamp.dateValue()
        } else {
            self.weeklyInsightTime = Date()
        }

        if let lastUpdatedTimestamp = data["lastUpdated"] as? Timestamp {
            self.lastUpdated = lastUpdatedTimestamp.dateValue()
        } else {
            self.lastUpdated = Date()
        }
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "createdBy": createdBy,
            "mealReminderEnabled": mealReminderEnabled,
            "mealReminderTime": Timestamp(date: mealReminderTime),
            "symptomReminderEnabled": symptomReminderEnabled,
            "symptomReminderTime": Timestamp(date: symptomReminderTime),
            "medicationReminderEnabled": medicationReminderEnabled,
            "medicationReminderTime": Timestamp(date: medicationReminderTime),
            "remindMeLaterInterval": remindMeLaterInterval,
            "weeklyInsightEnabled": weeklyInsightEnabled,
            "weeklyInsightTime": Timestamp(date: weeklyInsightTime),
            "newInsightsEnabled": newInsightsEnabled,
            "patternAlertEnabled": patternAlertEnabled,
            "lastUpdated": Timestamp(date: Date()),
            "createdAt": Timestamp(date: Date())
        ]
    }
}