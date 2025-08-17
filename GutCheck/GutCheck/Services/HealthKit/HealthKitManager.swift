import Foundation
import HealthKit

// MARK: - UserHealthData Model (renamed to avoid conflicts)
struct UserHealthData {
    var dateOfBirth: Date?
    var biologicalSex: HKBiologicalSex?
    var weight: Double? // in kg
    var height: Double? // in meters
}

final class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    private init() {}

    // MARK: - Request Authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthKitError.notAvailable)
            return
        }

        let readTypes: Set<HKObjectType> = Set([
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
            HKObjectType.characteristicType(forIdentifier: .biologicalSex),
            HKObjectType.quantityType(forIdentifier: .bodyMass),
            HKObjectType.quantityType(forIdentifier: .height)
        ].compactMap { $0 })
        
        let writeTypes: Set<HKSampleType> = Set([
            // Nutrition data
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            HKObjectType.quantityType(forIdentifier: .dietaryProtein),
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal),
            HKObjectType.quantityType(forIdentifier: .dietaryFiber),
            HKObjectType.quantityType(forIdentifier: .dietarySugar),
            HKObjectType.quantityType(forIdentifier: .dietarySodium),
            HKObjectType.quantityType(forIdentifier: .dietaryCalcium),
            HKObjectType.quantityType(forIdentifier: .dietaryIron),
            HKObjectType.quantityType(forIdentifier: .dietaryWater),
            // Symptoms - using abdominal cramps as closest match for digestive symptoms
            HKObjectType.categoryType(forIdentifier: .abdominalCramps)
        ].compactMap { $0 })

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            completion(success, error)
        }
    }

    // MARK: - Fetch User Health Profile
    func fetchUserHealthData(completion: @escaping (UserHealthData?) -> Void) {
        var healthData = UserHealthData()

        do {
            if let dob = try healthStore.dateOfBirthComponents().date {
                healthData.dateOfBirth = dob
            }

            if let biologicalSex = try? healthStore.biologicalSex().biologicalSex {
                healthData.biologicalSex = biologicalSex
                print("HealthKit: Retrieved biological sex: \(biologicalSex)")
            } else {
                print("HealthKit: No biological sex data available")
            }

            let group = DispatchGroup()

            group.enter()
            fetchLatestQuantity(for: .bodyMass) { quantity in
                healthData.weight = quantity?.doubleValue(for: .gramUnit(with: .kilo))
                group.leave()
            }

            group.enter()
            fetchLatestQuantity(for: .height) { quantity in
                healthData.height = quantity?.doubleValue(for: .meter())
                group.leave()
            }

            group.notify(queue: .main) {
                completion(healthData)
            }

        } catch {
            print("HealthKit error: \(error.localizedDescription)")
            completion(nil)
        }
    }

    // MARK: - Helper
    private func fetchLatestQuantity(for identifier: HKQuantityTypeIdentifier, completion: @escaping (HKQuantity?) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: quantityType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, results, _ in
            guard let sample = results?.first as? HKQuantitySample else {
                completion(nil)
                return
            }

            completion(sample.quantity)
        }

        healthStore.execute(query)
    }
    
    // MARK: - Write Data to HealthKit
    
    /// Write meal nutrition data to HealthKit
    func writeMealToHealthKit(_ meal: Meal, completion: @escaping (Bool, Error?) -> Void) {
        var samples: [HKQuantitySample] = []
        let mealDate = meal.date
        
        // Calculate total nutrition from food items
        let totalNutrition = meal.foodItems.reduce(NutritionInfo()) { result, foodItem in
            var combined = result
            combined.calories = (combined.calories ?? 0) + (foodItem.nutrition.calories ?? 0)
            combined.protein = (combined.protein ?? 0.0) + (foodItem.nutrition.protein ?? 0.0)
            combined.carbs = (combined.carbs ?? 0.0) + (foodItem.nutrition.carbs ?? 0.0)
            combined.fat = (combined.fat ?? 0.0) + (foodItem.nutrition.fat ?? 0.0)
            combined.fiber = (combined.fiber ?? 0.0) + (foodItem.nutrition.fiber ?? 0.0)
            combined.sugar = (combined.sugar ?? 0.0) + (foodItem.nutrition.sugar ?? 0.0)
            combined.sodium = (combined.sodium ?? 0.0) + (foodItem.nutrition.sodium ?? 0.0)
            return combined
        }
        
        // Create nutrition samples
        if let calories = totalNutrition.calories, calories > 0 {
            if let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
                let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: Double(calories))
                let calorieSample = HKQuantitySample(type: calorieType, quantity: calorieQuantity, start: mealDate, end: mealDate)
                samples.append(calorieSample)
            }
        }
        
        if let protein = totalNutrition.protein, protein > 0 {
            if let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
                let proteinQuantity = HKQuantity(unit: .gram(), doubleValue: protein)
                let proteinSample = HKQuantitySample(type: proteinType, quantity: proteinQuantity, start: mealDate, end: mealDate)
                samples.append(proteinSample)
            }
        }
        
        if let carbs = totalNutrition.carbs, carbs > 0 {
            if let carbType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
                let carbQuantity = HKQuantity(unit: .gram(), doubleValue: carbs)
                let carbSample = HKQuantitySample(type: carbType, quantity: carbQuantity, start: mealDate, end: mealDate)
                samples.append(carbSample)
            }
        }
        
        if let fat = totalNutrition.fat, fat > 0 {
            if let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
                let fatQuantity = HKQuantity(unit: .gram(), doubleValue: fat)
                let fatSample = HKQuantitySample(type: fatType, quantity: fatQuantity, start: mealDate, end: mealDate)
                samples.append(fatSample)
            }
        }
        
        if let fiber = totalNutrition.fiber, fiber > 0 {
            if let fiberType = HKQuantityType.quantityType(forIdentifier: .dietaryFiber) {
                let fiberQuantity = HKQuantity(unit: .gram(), doubleValue: fiber)
                let fiberSample = HKQuantitySample(type: fiberType, quantity: fiberQuantity, start: mealDate, end: mealDate)
                samples.append(fiberSample)
            }
        }
        
        if let sugar = totalNutrition.sugar, sugar > 0 {
            if let sugarType = HKQuantityType.quantityType(forIdentifier: .dietarySugar) {
                let sugarQuantity = HKQuantity(unit: .gram(), doubleValue: sugar)
                let sugarSample = HKQuantitySample(type: sugarType, quantity: sugarQuantity, start: mealDate, end: mealDate)
                samples.append(sugarSample)
            }
        }
        
        if let sodium = totalNutrition.sodium, sodium > 0 {
            if let sodiumType = HKQuantityType.quantityType(forIdentifier: .dietarySodium) {
                let sodiumQuantity = HKQuantity(unit: .gram(), doubleValue: sodium / 1000) // Convert mg to g
                let sodiumSample = HKQuantitySample(type: sodiumType, quantity: sodiumQuantity, start: mealDate, end: mealDate)
                samples.append(sodiumSample)
            }
        }
        
        guard !samples.isEmpty else {
            completion(false, HealthKitError.noData)
            return
        }
        
        healthStore.save(samples) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ HealthKit: Successfully wrote meal data for \(meal.name)")
                } else {
                    print("❌ HealthKit: Failed to write meal data: \(error?.localizedDescription ?? "Unknown error")")
                }
                completion(success, error)
            }
        }
    }
    
    /// Write symptom data to HealthKit
    func writeSymptomToHealthKit(_ symptom: Symptom, completion: @escaping (Bool, Error?) -> Void) {
        guard let categoryType = HKCategoryType.categoryType(forIdentifier: .abdominalCramps) else {
            completion(false, HealthKitError.invalidData)
            return
        }
        
        // Map symptom severity to HealthKit values
        let severity: Int
        switch symptom.painLevel {
        case .none:
            severity = HKCategoryValueSeverity.notPresent.rawValue
        case .mild:
            severity = HKCategoryValueSeverity.mild.rawValue
        case .moderate:
            severity = HKCategoryValueSeverity.moderate.rawValue
        case .severe:
            severity = HKCategoryValueSeverity.severe.rawValue
        }
        
        let symptomSample = HKCategorySample(
            type: categoryType,
            value: severity,
            start: symptom.date,
            end: symptom.date,
            metadata: [
                HKMetadataKeyExternalUUID: symptom.id,
                "stoolType": symptom.stoolType.rawValue,
                "urgencyLevel": symptom.urgencyLevel.rawValue,
                "notes": symptom.notes ?? ""
            ]
        )
        
        healthStore.save(symptomSample) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ HealthKit: Successfully wrote symptom data")
                } else {
                    print("❌ HealthKit: Failed to write symptom data: \(error?.localizedDescription ?? "Unknown error")")
                }
                completion(success, error)
            }
        }
    }
    
    /// Write water intake to HealthKit
    func writeWaterIntakeToHealthKit(amount: Double, date: Date = Date(), completion: @escaping (Bool, Error?) -> Void) {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            completion(false, HealthKitError.invalidData)
            return
        }
        
        let waterQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amount)
        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: date, end: date)
        
        healthStore.save(waterSample) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ HealthKit: Successfully wrote water intake: \(amount)ml")
                } else {
                    print("❌ HealthKit: Failed to write water intake: \(error?.localizedDescription ?? "Unknown error")")
                }
                completion(success, error)
            }
        }
    }
    

}
