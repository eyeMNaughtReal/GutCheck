//
//  CoreDataStorageService.swift
//  GutCheck
//
//  Service for managing local data storage with Core Data
//
//  Created by Mark Conley on 8/18/25.
//

import Foundation
import CoreData

@MainActor
class CoreDataStorageService: ObservableObject {
    static let shared = CoreDataStorageService()
    
    private let coreDataStack = CoreDataStack.shared
    
    private init() {}
    
    // MARK: - Meal Management
    
    func saveMeal(_ meal: Meal) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let localMeal = LocalMeal(context: context)
            localMeal.id = meal.id
            localMeal.name = meal.name
            localMeal.date = meal.date
            localMeal.type = meal.type.rawValue
            localMeal.source = meal.source.rawValue
            localMeal.notes = meal.notes
            localMeal.createdBy = meal.createdBy
            localMeal.createdAt = Date()
            localMeal.lastModified = Date()
            localMeal.syncStatus = "local"
            
            // Save food items
            for foodItem in meal.foodItems {
                let localFoodItem = LocalFoodItem(context: context)
                localFoodItem.id = foodItem.id
                localFoodItem.name = foodItem.name
                localFoodItem.quantity = Double(foodItem.quantity) ?? 1.0
                // Note: FoodItem model doesn't have unit property
                localFoodItem.servingSize = String(foodItem.estimatedWeightInGrams ?? 0)
                localFoodItem.calories = Double(foodItem.nutrition.calories ?? 0)
                localFoodItem.protein = foodItem.nutrition.protein ?? 0.0
                localFoodItem.carbohydrates = foodItem.nutrition.carbs ?? 0.0
                localFoodItem.fat = foodItem.nutrition.fat ?? 0.0
                localFoodItem.fiber = foodItem.nutrition.fiber ?? 0.0
                localFoodItem.sugar = foodItem.nutrition.sugar ?? 0.0
                localFoodItem.sodium = foodItem.nutrition.sodium ?? 0.0
                localFoodItem.meal = localMeal
            }
            
            try context.save()
        }
    }
    
    func fetchMeals(for dateRange: DateInterval) async throws -> [Meal] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<LocalMeal> = LocalMeal.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", dateRange.start as CVarArg, dateRange.end as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            let localMeals = try context.fetch(fetchRequest)
            var meals: [Meal] = []
            for localMeal in localMeals {
                guard let id = localMeal.id,
                      let name = localMeal.name,
                      let date = localMeal.date,
                      let typeString = localMeal.type,
                      let type = MealType(rawValue: typeString),
                      let sourceString = localMeal.source,
                      let source = MealSource(rawValue: sourceString),
                      let createdBy = localMeal.createdBy else {
                    continue
                }
                
                var foodItems: [FoodItem] = []
                if let localFoodItems = localMeal.foodItems?.allObjects as? [LocalFoodItem] {
                    for localFoodItem in localFoodItems {
                        guard let foodId = localFoodItem.id,
                              let foodName = localFoodItem.name else { continue }
                        
                        let foodItem = FoodItem(
                            id: foodId,
                            name: foodName,
                            quantity: String(localFoodItem.quantity),
                            estimatedWeightInGrams: nil,
                            ingredients: [],
                            allergens: [],
                            nutrition: NutritionInfo(
                                calories: Int(localFoodItem.calories),
                                protein: localFoodItem.protein,
                                carbs: localFoodItem.carbohydrates,
                                fat: localFoodItem.fat,
                                fiber: localFoodItem.fiber,
                                sugar: localFoodItem.sugar,
                                sodium: localFoodItem.sodium
                            ),
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
                    type: type,
                    source: source,
                    foodItems: foodItems,
                    notes: localMeal.notes,
                    createdBy: createdBy
                )
                
                meals.append(meal)
            }
            
            return meals
        }
    }
    
    func deleteMeal(id: String) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<LocalMeal> = LocalMeal.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            let localMeals = try context.fetch(fetchRequest)
            for localMeal in localMeals {
                context.delete(localMeal)
            }
            
            try context.save()
        }
    }
    
    // MARK: - Symptom Management
    
    func saveSymptom(_ symptom: Symptom) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let localSymptom = LocalSymptom(context: context)
            localSymptom.id = symptom.id
            localSymptom.date = symptom.date
            localSymptom.stoolType = String(symptom.stoolType.rawValue)
            localSymptom.painLevel = Int16(symptom.painLevel.rawValue)
            localSymptom.urgencyLevel = Int16(symptom.urgencyLevel.rawValue)
            localSymptom.bloating = false
            localSymptom.notes = symptom.notes
            localSymptom.createdBy = symptom.createdBy
            localSymptom.createdAt = Date()
            localSymptom.lastModified = Date()
            localSymptom.syncStatus = "local"
            
            try context.save()
        }
    }
    
    func fetchSymptoms(for dateRange: DateInterval) async throws -> [Symptom] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<LocalSymptom> = LocalSymptom.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", dateRange.start as CVarArg, dateRange.end as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            let localSymptoms = try context.fetch(fetchRequest)
            var symptoms: [Symptom] = []
            for localSymptom in localSymptoms {
                guard let id = localSymptom.id,
                      let date = localSymptom.date,
                      let stoolTypeString = localSymptom.stoolType,
                      let stoolTypeInt = Int(stoolTypeString),
                      let stoolType = StoolType(rawValue: stoolTypeInt),
                      let createdBy = localSymptom.createdBy else {
                    continue
                }
                
                let painLevel = PainLevel(rawValue: Int(localSymptom.painLevel)) ?? .none
                let urgencyLevel = UrgencyLevel(rawValue: Int(localSymptom.urgencyLevel)) ?? .none
                
                let symptom = Symptom(
                    id: id,
                    date: date,
                    stoolType: stoolType,
                    painLevel: painLevel,
                    urgencyLevel: urgencyLevel,
                    notes: localSymptom.notes,
                    createdBy: createdBy
                )
                
                symptoms.append(symptom)
            }
            
            return symptoms
        }
    }
    
    func deleteSymptom(id: String) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<LocalSymptom> = LocalSymptom.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            let localSymptoms = try context.fetch(fetchRequest)
            for localSymptom in localSymptoms {
                context.delete(localSymptom)
            }
            
            try context.save()
        }
    }
    
    // MARK: - User Management
    
    func saveUser(_ user: User) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let localUser = LocalUser(context: context)
            localUser.id = user.id
            localUser.email = user.email
            localUser.firstName = user.firstName
            localUser.lastName = user.lastName
            localUser.signInMethod = user.signInMethod.rawValue
            localUser.createdAt = user.createdAt
            localUser.updatedAt = user.updatedAt
            localUser.profileImageURL = user.profileImageURL
            localUser.dateOfBirth = user.dateOfBirth
            localUser.biologicalSexRawValue = Int16(user.biologicalSexRawValue ?? 0)
            localUser.weight = user.weight ?? 0.0
            localUser.height = user.height ?? 0.0
            localUser.privacyPolicyAccepted = user.privacyPolicyAccepted
            localUser.privacyPolicyAcceptedDate = user.privacyPolicyAcceptedDate
            localUser.privacyPolicyVersion = user.privacyPolicyVersion
            localUser.lastSync = Date()
            localUser.syncStatus = "synced"
            
            try context.save()
        }
    }
    
    func fetchUser(id: String) async throws -> User? {
        return try await coreDataStack.performBackgroundTask { context -> User? in
            let fetchRequest: NSFetchRequest<LocalUser> = LocalUser.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1
            
            let localUsers = try context.fetch(fetchRequest)
            guard let localUser = localUsers.first,
                  let email = localUser.email,
                  let firstName = localUser.firstName,
                  let lastName = localUser.lastName,
                  let signInMethodString = localUser.signInMethod,
                  let signInMethod = SignInMethod(rawValue: signInMethodString),
                  let createdAt = localUser.createdAt,
                  let updatedAt = localUser.updatedAt else {
                return nil
            }
            
            return User(
                id: localUser.id ?? "",
                email: email,
                firstName: firstName,
                lastName: lastName,
                signInMethod: signInMethod,
                createdAt: createdAt,
                updatedAt: updatedAt,
                privacyPolicyAccepted: localUser.privacyPolicyAccepted,
                privacyPolicyAcceptedDate: localUser.privacyPolicyAcceptedDate,
                privacyPolicyVersion: localUser.privacyPolicyVersion ?? "1.0"
            )
        }
    }
    
    // MARK: - Reminder Settings Management
    
    func saveReminderSettings(_ settings: ReminderSettings) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let localSettings = LocalReminderSettings(context: context)
            localSettings.id = settings.id
            localSettings.userId = settings.createdBy
            localSettings.mealReminderEnabled = settings.mealReminderEnabled
            localSettings.mealReminderTime = settings.mealReminderTime
            localSettings.symptomReminderEnabled = settings.symptomReminderEnabled
            localSettings.symptomReminderTime = settings.symptomReminderTime
            localSettings.remindMeLaterInterval = Int16(settings.remindMeLaterInterval)
            localSettings.weeklyInsightEnabled = settings.weeklyInsightEnabled
            localSettings.weeklyInsightTime = settings.weeklyInsightTime
            localSettings.lastModified = Date()
            localSettings.syncStatus = "local"
            
            try context.save()
        }
    }
    
    func fetchReminderSettings(userId: String) async throws -> ReminderSettings? {
        return try await coreDataStack.performBackgroundTask { context -> ReminderSettings? in
            let fetchRequest: NSFetchRequest<LocalReminderSettings> = LocalReminderSettings.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
            fetchRequest.fetchLimit = 1
            
            let localSettings = try context.fetch(fetchRequest)
            guard let localSetting = localSettings.first,
                  let id = localSetting.id,
                  let userId = localSetting.userId else {
                return nil
            }
            
            return ReminderSettings(
                id: id,
                createdBy: userId,
                mealReminderEnabled: localSetting.mealReminderEnabled,
                mealReminderTime: localSetting.mealReminderTime ?? Date(),
                symptomReminderEnabled: localSetting.symptomReminderEnabled,
                symptomReminderTime: localSetting.symptomReminderTime ?? Date(),
                remindMeLaterInterval: Int(localSetting.remindMeLaterInterval),
                weeklyInsightEnabled: localSetting.weeklyInsightEnabled,
                weeklyInsightTime: localSetting.weeklyInsightTime ?? Date()
            )
        }
    }
    
    // MARK: - Data Synchronization
    
    func markAsSynced<T: NSManagedObject>(_ entity: T, syncStatus: String = "synced") {
        if let localMeal = entity as? LocalMeal {
            localMeal.syncStatus = syncStatus
            localMeal.lastModified = Date()
        } else if let localSymptom = entity as? LocalSymptom {
            localSymptom.syncStatus = syncStatus
            localSymptom.lastModified = Date()
        } else if let localUser = entity as? LocalUser {
            localUser.syncStatus = syncStatus
            localUser.lastSync = Date()
        } else if let localSettings = entity as? LocalReminderSettings {
            localSettings.syncStatus = syncStatus
            localSettings.lastModified = Date()
        }

        guard let context = entity.managedObjectContext else { return }
        context.perform {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("Error saving sync status: \(error)")
                }
            }
        }
    }
    
    func getUnsyncedData() async throws -> (meals: [LocalMeal], symptoms: [LocalSymptom], settings: [LocalReminderSettings]) {
        return try await coreDataStack.performBackgroundTask { context in
            let mealFetchRequest: NSFetchRequest<LocalMeal> = LocalMeal.fetchRequest()
            mealFetchRequest.predicate = NSPredicate(format: "syncStatus == %@", "local")
            
            let symptomFetchRequest: NSFetchRequest<LocalSymptom> = LocalSymptom.fetchRequest()
            symptomFetchRequest.predicate = NSPredicate(format: "syncStatus == %@", "local")
            
            let settingsFetchRequest: NSFetchRequest<LocalReminderSettings> = LocalReminderSettings.fetchRequest()
            settingsFetchRequest.predicate = NSPredicate(format: "syncStatus == %@", "local")
            
            let meals = try context.fetch(mealFetchRequest)
            let symptoms = try context.fetch(symptomFetchRequest)
            let settings = try context.fetch(settingsFetchRequest)
            
            return (meals: meals, symptoms: symptoms, settings: settings)
        }
    }
    
    // MARK: - Data Cleanup
    
    func cleanupOldData() async {
        do {
            try await coreDataStack.performBackgroundTask { context in
            // Remove data older than 90 days
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
            
            let mealFetchRequest: NSFetchRequest<LocalMeal> = LocalMeal.fetchRequest()
            mealFetchRequest.predicate = NSPredicate(format: "date < %@ AND syncStatus == %@", cutoffDate as CVarArg, "synced")
            
            let symptomFetchRequest: NSFetchRequest<LocalSymptom> = LocalSymptom.fetchRequest()
            symptomFetchRequest.predicate = NSPredicate(format: "date < %@ AND syncStatus == %@", cutoffDate as CVarArg, "synced")
            
            do {
                let oldMeals = try context.fetch(mealFetchRequest)
                let oldSymptoms = try context.fetch(symptomFetchRequest)
                
                for meal in oldMeals {
                    context.delete(meal)
                }
                
                for symptom in oldSymptoms {
                    context.delete(symptom)
                }
                
                try context.save()
            } catch {
                print("Error cleaning up old data: \(error)")
            }
        }
        } catch {
            print("Error performing background task: \(error)")
        }
    }
}
