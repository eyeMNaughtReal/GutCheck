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
            print("❌ ReminderSettingsService: Error loading settings: \(error)")
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
            
            // Schedule notifications
            await scheduleNotifications(for: updatedSettings)
            
            print("✅ ReminderSettingsService: Successfully saved reminder settings")
            
        } catch {
            print("❌ ReminderSettingsService: Error saving settings: \(error)")
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
        UserDefaults.standard.set(settings.remindMeLaterInterval, forKey: "remindMeLaterInterval")
        UserDefaults.standard.set(settings.weeklyInsightEnabled, forKey: "weeklyInsightEnabled")
        UserDefaults.standard.set(settings.weeklyInsightTime, forKey: "weeklyInsightTime")
    }
    
    private func scheduleNotifications(for settings: ReminderSettings) async {
        let center = UNUserNotificationCenter.current()
        let permissionManager = PermissionManager.shared
        
        // Check permission through centralized system
        if !permissionManager.notificationStatus.isGranted {
            print("⚠️ ReminderSettingsService: Notification permission not granted")
            // Don't request here - should be handled by proper UI flow
            return
        }
        
        // Remove existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Schedule meal reminders
        if settings.mealReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Meal Reminder"
            content.body = "Don't forget to log your meals!"
            content.sound = .default
            
            let trigger = calendarTrigger(for: settings.mealReminderTime)
            let request = UNNotificationRequest(identifier: "mealReminder", content: content, trigger: trigger)
            
            do {
                try await center.add(request)
                print("✅ ReminderSettingsService: Scheduled meal reminder")
            } catch {
                print("❌ ReminderSettingsService: Error scheduling meal reminder: \(error)")
            }
        }
        
        // Schedule symptom reminders
        if settings.symptomReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Symptom Reminder"
            content.body = "Don't forget to log your symptoms!"
            content.sound = .default
            
            let trigger = calendarTrigger(for: settings.symptomReminderTime)
            let request = UNNotificationRequest(identifier: "symptomReminder", content: content, trigger: trigger)
            
            do {
                try await center.add(request)
                print("✅ ReminderSettingsService: Scheduled symptom reminder")
            } catch {
                print("❌ ReminderSettingsService: Error scheduling symptom reminder: \(error)")
            }
        }
        
        // Schedule weekly insight reminders
        if settings.weeklyInsightEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Weekly Insight"
            content.body = "Check your AI-powered weekly health insights!"
            content.sound = .default
            
            let trigger = calendarTrigger(for: settings.weeklyInsightTime, weekday: 2) // Monday
            let request = UNNotificationRequest(identifier: "weeklyInsight", content: content, trigger: trigger)
            
            do {
                try await center.add(request)
                print("✅ ReminderSettingsService: Scheduled weekly insight reminder")
            } catch {
                print("❌ ReminderSettingsService: Error scheduling weekly insight reminder: \(error)")
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
        let document = try await db.collection(collectionPath)
            .whereField("createdBy", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()
        
        guard let doc = document.documents.first else {
            throw RepositoryError.documentNotFound("No reminder settings found for user")
        }
        
        return try ReminderSettings(from: doc)
    }
    
    func save(_ settings: ReminderSettings) async throws {
        let data = settings.toFirestoreData()
        try await db.collection(collectionPath).document(settings.id).setData(data)
    }
    
    func delete(_ settings: ReminderSettings) async throws {
        try await db.collection(collectionPath).document(settings.id).delete()
    }
}