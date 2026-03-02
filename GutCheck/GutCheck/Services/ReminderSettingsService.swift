//
//  ReminderSettingsService.swift
//  GutCheck
//
//  Service for managing reminder settings with Firebase sync
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

@MainActor
class ReminderSettingsService: ObservableObject {
    static let shared = ReminderSettingsService()
    
    @Published var reminderSettings: ReminderSettings?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let reminderRepository = ReminderSettingsRepository.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    func loadReminderSettings() async {
        guard let userId = AuthenticationManager.shared.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let settings = try await reminderRepository.fetch(forUser: userId)
            self.reminderSettings = settings
            
            // Sync loaded settings with local storage
            syncToLocalStorage(settings)
            
        } catch {
            #if DEBUG
            print("❌ ReminderSettingsService: Error loading settings: \(error)")
            #endif
            errorMessage = error.localizedDescription
            
            // If no settings found, create default settings
            if case RepositoryError.documentNotFound = error {
                await createDefaultSettings()
            }
        }
        
        isLoading = false
    }
    
    func saveReminderSettings(_ settings: ReminderSettings) async {
        guard let userId = AuthenticationManager.shared.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        var updatedSettings = settings
        updatedSettings.createdBy = userId
        updatedSettings.lastUpdated = Date()
        
        do {
            try await reminderRepository.save(updatedSettings)
            self.reminderSettings = updatedSettings
            
            // Sync to local storage
            syncToLocalStorage(updatedSettings)

            // Schedule local push notifications
            await scheduleNotifications(for: updatedSettings)

            // Sync to Apple Reminders app (opt-in, no-op if not enabled/authorized)
            await RemindersKitService.shared.syncReminders(from: updatedSettings)

            #if DEBUG
            print("✅ ReminderSettingsService: Successfully saved reminder settings")
            #endif
            
        } catch {
            #if DEBUG
            print("❌ ReminderSettingsService: Error saving settings: \(error)")
            #endif
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateReminderSettings(update: @escaping (inout ReminderSettings) -> Void) async {
        guard var settings = reminderSettings else {
            await createDefaultSettings()
            return
        }
        
        update(&settings)
        await saveReminderSettings(settings)
    }
    
    // MARK: - Private Methods
    
    private func createDefaultSettings() async {
        guard let userId = AuthenticationManager.shared.currentUserId else { return }
        
        let defaultSettings = ReminderSettings(createdBy: userId)
        await saveReminderSettings(defaultSettings)
    }
    
    private func syncToLocalStorage(_ settings: ReminderSettings) {
        UserDefaults.standard.set(settings.mealReminderEnabled, forKey: "mealReminderEnabled")
        UserDefaults.standard.set(settings.mealReminderTime, forKey: "mealReminderTime")
        UserDefaults.standard.set(settings.symptomReminderEnabled, forKey: "symptomReminderEnabled")
        UserDefaults.standard.set(settings.symptomReminderTime, forKey: "symptomReminderTime")
        UserDefaults.standard.set(settings.medicationReminderEnabled, forKey: "medicationReminderEnabled")
        UserDefaults.standard.set(settings.medicationReminderTime, forKey: "medicationReminderTime")
        UserDefaults.standard.set(settings.remindMeLaterInterval, forKey: "remindMeLaterInterval")
        UserDefaults.standard.set(settings.weeklyInsightEnabled, forKey: "weeklyInsightEnabled")
        UserDefaults.standard.set(settings.weeklyInsightTime, forKey: "weeklyInsightTime")
        UserDefaults.standard.set(settings.newInsightsEnabled, forKey: "newInsightsEnabled")
        UserDefaults.standard.set(settings.patternAlertEnabled, forKey: "patternAlertEnabled")
    }
    
    private func scheduleNotifications(for settings: ReminderSettings) async {
        let center = UNUserNotificationCenter.current()

        // Query the live authorization status directly — the cached value on
        // PermissionManager is populated asynchronously and may still be
        // .notDetermined the first time this runs, causing all scheduling to
        // be silently skipped.
        let authSettings = await center.notificationSettings()
        let isAuthorized = authSettings.authorizationStatus == .authorized
                        || authSettings.authorizationStatus == .provisional
                        || authSettings.authorizationStatus == .ephemeral

        guard isAuthorized else {
            #if DEBUG
            print("⚠️ ReminderSettingsService: Notification permission not granted (\(authSettings.authorizationStatus.rawValue))")
            #endif
            // Don't request here - should be handled by proper UI flow
            return
        }
        
        // Remove existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Schedule meal reminders
        if settings.mealReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Time to Log Your Meal"
            content.body = "Don't forget to track what you ate. Consistent logging leads to better insights."
            content.sound = .default

            let trigger = calendarTrigger(for: settings.mealReminderTime)
            let request = UNNotificationRequest(identifier: "mealReminder", content: content, trigger: trigger)

            do {
                try await center.add(request)
                #if DEBUG
                print("✅ ReminderSettingsService: Scheduled meal reminder")
                #endif
            } catch {
                #if DEBUG
                print("❌ ReminderSettingsService: Error scheduling meal reminder: \(error)")
                #endif
            }
        }

        // Schedule symptom reminders
        if settings.symptomReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Symptom Check-In"
            content.body = "How's your gut feeling today? Tap to log your symptoms."
            content.sound = .default

            let trigger = calendarTrigger(for: settings.symptomReminderTime)
            let request = UNNotificationRequest(identifier: "symptomReminder", content: content, trigger: trigger)

            do {
                try await center.add(request)
                #if DEBUG
                print("✅ ReminderSettingsService: Scheduled symptom reminder")
                #endif
            } catch {
                #if DEBUG
                print("❌ ReminderSettingsService: Error scheduling symptom reminder: \(error)")
                #endif
            }
        }

        // Schedule medication reminders
        if settings.medicationReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Medication Reminder"
            content.body = "Time to take your medication. Tap to log your dose."
            content.sound = .default

            let trigger = calendarTrigger(for: settings.medicationReminderTime)
            let request = UNNotificationRequest(identifier: "medicationReminder", content: content, trigger: trigger)

            do {
                try await center.add(request)
                #if DEBUG
                print("✅ ReminderSettingsService: Scheduled medication reminder")
                #endif
            } catch {
                #if DEBUG
                print("❌ ReminderSettingsService: Error scheduling medication reminder: \(error)")
                #endif
            }
        }

        // Schedule weekly summary reminders
        if settings.weeklyInsightEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Your Weekly Gut Health Summary"
            content.body = "Your report for the past 7 days is ready. See your trends and patterns."
            content.sound = .default

            let trigger = calendarTrigger(for: settings.weeklyInsightTime, weekday: 2) // Monday
            let request = UNNotificationRequest(identifier: "weeklyInsight", content: content, trigger: trigger)

            do {
                try await center.add(request)
                #if DEBUG
                print("✅ ReminderSettingsService: Scheduled weekly summary reminder")
                #endif
            } catch {
                #if DEBUG
                print("❌ ReminderSettingsService: Error scheduling weekly summary reminder: \(error)")
                #endif
            }
        }
    }
    
    private func calendarTrigger(for date: Date, weekday: Int? = nil) -> UNCalendarNotificationTrigger {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.hour, .minute], from: date)
        if let weekday = weekday {
            dateComponents.weekday = weekday
        }
        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    }
}

// MARK: - Repository

class ReminderSettingsRepository {
    static let shared = ReminderSettingsRepository()
    
    private let db = Firestore.firestore()
    private let collectionPath = "reminderSettings"
    
    private init() {}
    
    func fetch(forUser userId: String) async throws -> ReminderSettings {
        let doc = try await db.collection(collectionPath).document(userId).getDocument()

        guard doc.exists else {
            throw RepositoryError.documentNotFound("No reminder settings found for user")
        }

        return try ReminderSettings(from: doc)
    }

    func save(_ settings: ReminderSettings) async throws {
        let data = settings.toFirestoreData()
        try await db.collection(collectionPath).document(settings.createdBy).setData(data)
    }

    func delete(_ settings: ReminderSettings) async throws {
        try await db.collection(collectionPath).document(settings.createdBy).delete()
    }
}