import Foundation
import HealthKit

// MARK: - UserHealthData Model (renamed to avoid conflicts)
struct UserHealthData {
    var dateOfBirth: Date?
    var biologicalSex: HKBiologicalSex?
    var weight: Double?                  // kg
    var height: Double?                  // meters
    var bloodPressureSystolic: Double?   // mmHg
    var bloodPressureDiastolic: Double?  // mmHg
    var bloodGlucose: Double?            // mg/dL
    var heartRate: Double?               // bpm
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
            // Basic health characteristics
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
            HKObjectType.characteristicType(forIdentifier: .biologicalSex),
            HKObjectType.quantityType(forIdentifier: .bodyMass),
            HKObjectType.quantityType(forIdentifier: .height),
            
            // Sleep data
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            
            // Cardiovascular data
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic),
            HKObjectType.quantityType(forIdentifier: .bloodGlucose),
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            
            // Stress and activity data
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            
            // Additional gut health indicators
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
            HKObjectType.quantityType(forIdentifier: .waistCircumference),
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
            
            // Water and hydration
            HKObjectType.quantityType(forIdentifier: .dietaryWater),
            
            // Stress indicators
            HKObjectType.quantityType(forIdentifier: .respiratoryRate),
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)
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
            // Digestive symptoms
            HKObjectType.categoryType(forIdentifier: .abdominalCramps),
            HKObjectType.categoryType(forIdentifier: .bloating),
            HKObjectType.categoryType(forIdentifier: .diarrhea),
            HKObjectType.categoryType(forIdentifier: .constipation),
            HKObjectType.categoryType(forIdentifier: .nausea)
        ].compactMap { $0 })

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            completion(success, error)
        }
    }

    // MARK: - Write Authorization Status

    /// Returns the current HealthKit write authorization status for a quantity type.
    /// .sharingAuthorized = granted, .sharingDenied = denied/not yet shown, .notDetermined = never requested
    func writeAuthorizationStatus(for quantityTypeID: HKQuantityTypeIdentifier) -> HKAuthorizationStatus {
        guard let type = HKQuantityType.quantityType(forIdentifier: quantityTypeID) else { return .notDetermined }
        return healthStore.authorizationStatus(for: type)
    }

    /// Returns the current HealthKit write authorization status for a category type.
    func writeAuthorizationStatus(for categoryTypeID: HKCategoryTypeIdentifier) -> HKAuthorizationStatus {
        guard let type = HKCategoryType.categoryType(forIdentifier: categoryTypeID) else { return .notDetermined }
        return healthStore.authorizationStatus(for: type)
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
                #if DEBUG
                print("HealthKit: Retrieved biological sex")
                #endif
            } else {
                #if DEBUG
                print("HealthKit: No biological sex data available")
                #endif
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

            group.enter()
            fetchLatestQuantity(for: .bloodPressureSystolic) { quantity in
                healthData.bloodPressureSystolic = quantity?.doubleValue(for: .millimeterOfMercury())
                group.leave()
            }

            group.enter()
            fetchLatestQuantity(for: .bloodPressureDiastolic) { quantity in
                healthData.bloodPressureDiastolic = quantity?.doubleValue(for: .millimeterOfMercury())
                group.leave()
            }

            group.enter()
            fetchLatestQuantity(for: .bloodGlucose) { quantity in
                let mgPerDL = HKUnit.gramUnit(with: .milli).unitDivided(by: HKUnit.literUnit(with: .deci))
                healthData.bloodGlucose = quantity?.doubleValue(for: mgPerDL)
                group.leave()
            }

            group.enter()
            fetchLatestQuantity(for: .heartRate) { quantity in
                healthData.heartRate = quantity?.doubleValue(for: .count().unitDivided(by: .minute()))
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
                #if DEBUG
                if success {
                    print("✅ HealthKit: Successfully wrote meal data")
                } else {
                    print("❌ HealthKit: Failed to write meal data: \(error?.localizedDescription ?? "Unknown error")")
                }
                #endif
                completion(success, error)
            }
        }
    }

    /// Write symptom data to HealthKit.
    /// Maps GutCheck symptom properties to the most relevant HK category types,
    /// only including types that have been authorized.
    func writeSymptomToHealthKit(_ symptom: Symptom, completion: @escaping (Bool, Error?) -> Void) {
        var samples: [HKCategorySample] = []
        let start = symptom.date
        let end   = symptom.date
        let meta: [String: Any] = [
            HKMetadataKeyExternalUUID: symptom.id,
            "stoolType":    symptom.stoolType.rawValue,
            "urgencyLevel": symptom.urgencyLevel.rawValue,
            "notes":        symptom.notes ?? ""
        ]

        // Helper: convert PainLevel → HKCategoryValueSeverity
        func painSeverity(_ level: PainLevel) -> Int {
            switch level {
            case .none:     return HKCategoryValueSeverity.notPresent.rawValue
            case .mild:     return HKCategoryValueSeverity.mild.rawValue
            case .moderate: return HKCategoryValueSeverity.moderate.rawValue
            case .severe:   return HKCategoryValueSeverity.severe.rawValue
            }
        }

        // Helper: convert UrgencyLevel → HKCategoryValueSeverity
        func urgencySeverity(_ level: UrgencyLevel) -> Int {
            switch level {
            case .none:     return HKCategoryValueSeverity.mild.rawValue
            case .mild:     return HKCategoryValueSeverity.mild.rawValue
            case .moderate: return HKCategoryValueSeverity.moderate.rawValue
            case .urgent:   return HKCategoryValueSeverity.severe.rawValue
            }
        }

        // Abdominal cramps — written whenever there is any pain
        if symptom.painLevel != .none,
           let type = HKCategoryType.categoryType(forIdentifier: .abdominalCramps),
           healthStore.authorizationStatus(for: type) == .sharingAuthorized {
            samples.append(HKCategorySample(type: type,
                                            value: painSeverity(symptom.painLevel),
                                            start: start, end: end, metadata: meta))
        }

        // Bristol scale type 1–2 → constipation
        if (symptom.stoolType == .type1 || symptom.stoolType == .type2),
           let type = HKCategoryType.categoryType(forIdentifier: .constipation),
           healthStore.authorizationStatus(for: type) == .sharingAuthorized {
            let severity = symptom.painLevel != .none ? painSeverity(symptom.painLevel) : HKCategoryValueSeverity.mild.rawValue
            samples.append(HKCategorySample(type: type,
                                            value: severity,
                                            start: start, end: end, metadata: meta))
        }

        // Bristol scale type 5–7 → diarrhea
        if (symptom.stoolType == .type5 || symptom.stoolType == .type6 || symptom.stoolType == .type7),
           let type = HKCategoryType.categoryType(forIdentifier: .diarrhea),
           healthStore.authorizationStatus(for: type) == .sharingAuthorized {
            samples.append(HKCategorySample(type: type,
                                            value: urgencySeverity(symptom.urgencyLevel),
                                            start: start, end: end, metadata: meta))
        }

        // Fallback: if no authorized type matched, try abdominal cramps regardless
        if samples.isEmpty {
            guard let fallbackType = HKCategoryType.categoryType(forIdentifier: .abdominalCramps) else {
                completion(false, HealthKitError.invalidData)
                return
            }
            samples.append(HKCategorySample(type: fallbackType,
                                            value: painSeverity(symptom.painLevel),
                                            start: start, end: end, metadata: meta))
        }

        healthStore.save(samples) { success, error in
            DispatchQueue.main.async {
                #if DEBUG
                if success {
                    print("✅ HealthKit: Successfully wrote \(samples.count) symptom sample(s)")
                } else {
                    print("❌ HealthKit: Failed to write symptom data: \(error?.localizedDescription ?? "Unknown error")")
                }
                #endif
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
    
    // MARK: - Fetch Additional Health Data
    
    /// Fetch sleep data for a specific date range
    func fetchSleepData(from startDate: Date, to endDate: Date, completion: @escaping ([HKSample]) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion([])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, _ in
            completion(results ?? [])
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch blood pressure data for a specific date range
    func fetchBloodPressureData(from startDate: Date, to endDate: Date, completion: @escaping ([HKSample]) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Fetch systolic blood pressure
        if let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) {
            let systolicQuery = HKSampleQuery(sampleType: systolicType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, _ in
                // Handle systolic results
            }
            healthStore.execute(systolicQuery)
        }
        
        // Fetch diastolic blood pressure
        if let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) {
            let diastolicQuery = HKSampleQuery(sampleType: diastolicType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, _ in
                // Handle diastolic results
            }
            healthStore.execute(diastolicQuery)
        }
        
        // For now, return empty array - you can implement more sophisticated blood pressure handling
        completion([])
    }
    
    /// Fetch blood glucose data for a specific date range
    func fetchBloodGlucoseData(from startDate: Date, to endDate: Date, completion: @escaping ([HKSample]) -> Void) {
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
            completion([])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: glucoseType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, _ in
            completion(results ?? [])
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch heart rate data for a specific date range
    func fetchHeartRateData(from startDate: Date, to endDate: Date, completion: @escaping ([HKSample]) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion([])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, _ in
            completion(results ?? [])
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch step count data for a specific date range
    func fetchStepCountData(from startDate: Date, to endDate: Date, completion: @escaping ([HKSample]) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion([])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: stepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, _ in
            completion(results ?? [])
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch comprehensive health data for gut health analysis
    func fetchGutHealthData(from startDate: Date, to endDate: Date, completion: @escaping (GutHealthData) -> Void) {
        var gutHealthData = GutHealthData()
        let group = DispatchGroup()
        
        // Fetch sleep data
        group.enter()
        fetchSleepData(from: startDate, to: endDate) { samples in
            gutHealthData.sleepData = samples
            group.leave()
        }
        
        // Fetch blood pressure data
        group.enter()
        fetchBloodPressureData(from: startDate, to: endDate) { samples in
            gutHealthData.bloodPressureData = samples
            group.leave()
        }
        
        // Fetch blood glucose data
        group.enter()
        fetchBloodGlucoseData(from: startDate, to: endDate) { samples in
            gutHealthData.bloodGlucoseData = samples
            group.leave()
        }
        
        // Fetch heart rate data
        group.enter()
        fetchHeartRateData(from: startDate, to: endDate) { samples in
            gutHealthData.heartRateData = samples
            group.leave()
        }
        
        // Fetch step count data
        group.enter()
        fetchStepCountData(from: startDate, to: endDate) { samples in
            gutHealthData.stepCountData = samples
            group.leave()
        }
        
        // Fetch additional metrics
        group.enter()
        fetchLatestQuantity(for: .bodyFatPercentage) { quantity in
            gutHealthData.bodyFatPercentage = quantity?.doubleValue(for: .percent())
            group.leave()
        }
        
        group.enter()
        fetchLatestQuantity(for: .waistCircumference) { quantity in
            gutHealthData.waistCircumference = quantity?.doubleValue(for: .meter())
            group.leave()
        }
        
        group.enter()
        fetchLatestQuantity(for: .bodyMassIndex) { quantity in
            gutHealthData.bodyMassIndex = quantity?.doubleValue(for: .count())
            group.leave()
        }
        
        group.enter()
        fetchLatestQuantity(for: .respiratoryRate) { quantity in
            gutHealthData.respiratoryRate = quantity?.doubleValue(for: .count().unitDivided(by: .minute()))
            group.leave()
        }
        
        group.enter()
        fetchLatestQuantity(for: .oxygenSaturation) { quantity in
            gutHealthData.oxygenSaturation = quantity?.doubleValue(for: .percent())
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(gutHealthData)
        }
    }
}

// MARK: - Gut Health Data Model
struct GutHealthData {
    var sleepData: [HKSample] = []
    var bloodPressureData: [HKSample] = []
    var bloodGlucoseData: [HKSample] = []
    var heartRateData: [HKSample] = []
    var stepCountData: [HKSample] = []
    var bodyFatPercentage: Double?
    var waistCircumference: Double?
    var bodyMassIndex: Double?
    var respiratoryRate: Double?
    var oxygenSaturation: Double?
}
