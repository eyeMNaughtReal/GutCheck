//
//  DataSyncService.swift
//  GutCheck
//
//  Service for synchronizing data between local storage and Firestore
//
//  Created by Mark Conley on 8/18/25.
//

import Foundation
import CoreData
import FirebaseFirestore
import FirebaseAuth

@MainActor
class DataSyncService: ObservableObject {
    static let shared = DataSyncService()
    
    private let localStorage = CoreDataStorageService.shared
    private let coreDataStack = CoreDataStack.shared
    private lazy var firestore = Firestore.firestore()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncProgress: Double = 0.0
    
    private init() {}
    
    // MARK: - Full Synchronization
    
    func performFullSync() async throws {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncProgress = 0.0
        
        defer {
            isSyncing = false
            syncProgress = 1.0
            lastSyncDate = Date()
        }
        
        do {
            // Step 1: Upload local changes to Firestore
            syncProgress = 0.2
            try await uploadLocalChanges()
            
            // Step 2: Download remote changes from Firestore
            syncProgress = 0.6
            try await downloadRemoteChanges()
            
            // Step 3: Resolve conflicts and merge data
            syncProgress = 0.8
            try await resolveConflicts()
            
            // Step 4: Clean up old data
            syncProgress = 0.9
            await localStorage.cleanupOldData()
            
            syncProgress = 1.0
            
        } catch {
            print("Full sync failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Upload Local Changes
    
    private func uploadLocalChanges() async throws {
        let unsyncedData = try await localStorage.getUnsyncedData()
        
        // Upload meals
        for meal in unsyncedData.meals {
            try await uploadMeal(meal)
        }
        
        // Upload symptoms
        for symptom in unsyncedData.symptoms {
            try await uploadSymptom(symptom)
        }
        
        // Upload reminder settings
        for settings in unsyncedData.settings {
            try await uploadReminderSettings(settings)
        }
    }
    
    private func uploadMeal(_ localMeal: LocalMeal) async throws {
        guard let id = localMeal.id,
              let name = localMeal.name,
              let date = localMeal.date,
              let type = localMeal.type,
              let source = localMeal.source,
              let createdBy = localMeal.createdBy else {
            return
        }
        
        // Convert to domain model
        var foodItems: [FoodItem] = []
        if let localFoodItems = localMeal.foodItems?.allObjects as? [LocalFoodItem] {
            for localFoodItem in localFoodItems {
                guard let foodId = localFoodItem.id,
                      let foodName = localFoodItem.name else { continue }
                
                // Create NutritionInfo from Core Data values
                let nutrition = NutritionInfo(
                    calories: Int(localFoodItem.calories),
                    protein: localFoodItem.protein,
                    carbs: localFoodItem.carbohydrates,
                    fat: localFoodItem.fat,
                    fiber: localFoodItem.fiber,
                    sugar: localFoodItem.sugar,
                    sodium: localFoodItem.sodium
                )
                
                let foodItem = FoodItem(
                    id: foodId,
                    name: foodName,
                    quantity: String(localFoodItem.quantity),
                    estimatedWeightInGrams: nil,
                    ingredients: [],
                    allergens: [],
                    nutrition: nutrition,
                    source: .manual,
                    barcodeValue: nil,
                    isUserEdited: false,
                    nutritionDetails: [:]
                )
                
                foodItems.append(foodItem)
            }
        }
        
        let meal = Meal(
            id: id,
            name: name,
            date: date,
            type: MealType(rawValue: type) ?? .breakfast,
            source: MealSource(rawValue: source) ?? .manual,
            foodItems: foodItems,
            notes: localMeal.notes,
            createdBy: createdBy
        )
        
        // Upload to Firestore
        try await uploadMealToFirestore(meal)
        
        // Mark as synced
        localStorage.markAsSynced(localMeal)
    }
    
    private func uploadSymptom(_ localSymptom: LocalSymptom) async throws {
        guard let id = localSymptom.id,
              let date = localSymptom.date,
              let stoolType = localSymptom.stoolType,
              let createdBy = localSymptom.createdBy else {
            return
        }
        
        let symptom = Symptom(
            id: id,
            date: date,
            stoolType: StoolType(rawValue: Int(stoolType) ?? 4) ?? .type4,
            painLevel: PainLevel(rawValue: Int(localSymptom.painLevel)) ?? .none,
            urgencyLevel: UrgencyLevel(rawValue: Int(localSymptom.urgencyLevel)) ?? .none,
            notes: localSymptom.notes,
            createdBy: createdBy
        )
        
        // Upload to Firestore
        try await uploadSymptomToFirestore(symptom)
        
        // Mark as synced
        localStorage.markAsSynced(localSymptom)
    }
    
    private func uploadReminderSettings(_ localSettings: LocalReminderSettings) async throws {
        guard let id = localSettings.id,
              let userId = localSettings.userId else {
            return
        }
        
        let settings = ReminderSettings(
            id: id,
            createdBy: userId,
            mealReminderEnabled: localSettings.mealReminderEnabled,
            mealReminderTime: localSettings.mealReminderTime ?? Date(),
            symptomReminderEnabled: localSettings.symptomReminderEnabled,
            symptomReminderTime: localSettings.symptomReminderTime ?? Date(),
            remindMeLaterInterval: Int(localSettings.remindMeLaterInterval),
            weeklyInsightEnabled: localSettings.weeklyInsightEnabled,
            weeklyInsightTime: localSettings.weeklyInsightTime ?? Date()
        )
        
        // Upload to Firestore
        try await uploadReminderSettingsToFirestore(settings)
        
        // Mark as synced
        localStorage.markAsSynced(localSettings)
    }
    
    // MARK: - Download Remote Changes

    private func downloadRemoteChanges() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw SyncError.notAuthenticated
        }

        // Download meals from Firestore
        try await downloadMealsFromFirestore(userId: userId)

        // Download symptoms from Firestore
        try await downloadSymptomsFromFirestore(userId: userId)

        // Download reminder settings from Firestore
        try await downloadReminderSettingsFromFirestore(userId: userId)
    }

    private func downloadMealsFromFirestore(userId: String) async throws {
        let snapshot = try await firestore.collection("meals")
            .whereField("createdBy", isEqualTo: userId)
            .getDocuments()

        for document in snapshot.documents {
            _ = document.data()
            // Convert Firestore data to Meal and save locally
        }
    }

    private func downloadSymptomsFromFirestore(userId: String) async throws {
        let snapshot = try await firestore.collection("symptoms")
            .whereField("createdBy", isEqualTo: userId)
            .getDocuments()

        for document in snapshot.documents {
            _ = document.data()
            // Convert Firestore data to Symptom and save locally
        }
    }

    private func downloadReminderSettingsFromFirestore(userId: String) async throws {
        // Document ID is the user's UID, matching the Firestore security rule: match /reminderSettings/{userId}
        let document = try await firestore.collection("reminderSettings").document(userId).getDocument()
        guard document.exists else { return }
        _ = document.data()
        // Convert Firestore data to ReminderSettings and save locally
    }
    
    // MARK: - Firestore Upload Methods
    
    private func uploadMealToFirestore(_ meal: Meal) async throws {
        let mealData = meal.toFirestoreData()
        try await firestore.collection("meals").document(meal.id).setData(mealData)
    }
    
    private func uploadSymptomToFirestore(_ symptom: Symptom) async throws {
        let symptomData = symptom.toFirestoreData()
        try await firestore.collection("symptoms").document(symptom.id).setData(symptomData)
    }
    
    private func uploadReminderSettingsToFirestore(_ settings: ReminderSettings) async throws {
        let settingsData = settings.toFirestoreData()
        // Document ID is the user's UID, matching the Firestore security rule: match /reminderSettings/{userId}
        try await firestore.collection("reminderSettings").document(settings.createdBy).setData(settingsData)
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflicts() async throws {
        // Implement conflict resolution logic
        // This would compare local and remote versions and merge appropriately
        
        // For now, we'll use a simple "last write wins" approach
        // In production, you might want more sophisticated conflict resolution
    }
    
    // MARK: - Incremental Sync
    
    func performIncrementalSync() async throws {
        // Only sync data that has changed since last sync
        guard lastSyncDate != nil else {
            try await performFullSync()
            return
        }
        
        // Implement incremental sync logic
        // This would be more efficient for regular background syncs
    }
    
    // MARK: - Background Sync
    
    func startBackgroundSync() {
        // Start periodic background synchronization
        Task {
            while true {
                do {
                    try await performIncrementalSync()
                    // Wait 15 minutes before next sync
                    try await Task.sleep(nanoseconds: 15 * 60 * 1_000_000_000)
                } catch {
                    print("Background sync failed: \(error)")
                    // Wait 5 minutes before retry on failure
                    try await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
                }
            }
        }
    }
    
    // MARK: - Sync Status
    
    func getSyncStatus() -> SyncStatus {
        if isSyncing {
            return .syncing(progress: syncProgress)
        } else if let lastSync = lastSyncDate {
            return .lastSynced(date: lastSync)
        } else {
            return .neverSynced
        }
    }
}

// MARK: - Sync Error Enum

enum SyncError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Cannot sync: no authenticated user."
        }
    }
}

// MARK: - Sync Status Enum

enum SyncStatus {
    case neverSynced
    case syncing(progress: Double)
    case lastSynced(date: Date)
    
    var description: String {
        switch self {
        case .neverSynced:
            return "Never synced"
        case .syncing(let progress):
            return "Syncing... \(Int(progress * 100))%"
        case .lastSynced(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "Last synced: \(formatter.string(from: date))"
        }
    }
}
