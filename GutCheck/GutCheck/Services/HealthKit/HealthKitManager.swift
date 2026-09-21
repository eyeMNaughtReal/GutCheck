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

    /// Whether anything at all could be read.
    ///
    /// Every field is optional, so an instance where they are all nil means
    /// HealthKit returned nothing — either access was refused or the store is
    /// genuinely empty. The two are indistinguishable by design, and callers
    /// should not present "connected" on the strength of an instance existing.
    var hasAnyData: Bool {
        dateOfBirth != nil
            || biologicalSex != nil
            || weight != nil
            || height != nil
            || bloodPressureSystolic != nil
            || bloodPressureDiastolic != nil
            || bloodGlucose != nil
            || heartRate != nil
    }
}

/// HealthKit read/write access for GutCheck.
///
/// Queries go through `HKSampleQueryDescriptor.result(for:)` rather than
/// `HKSampleQuery` + `execute(_:)`. Beyond being less code, that removes the
/// pattern this file used to rely on: a `DispatchGroup` fanning out several
/// callback queries that each wrote into one shared `var`. Those handlers run on
/// an arbitrary background queue, so the aggregate reads were unsynchronised.
/// `async let` gives the same concurrency with each result returned as a value.
final class HealthKitManager: HealthKitManagerProtocol {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    private init() {}

    // MARK: - Request Authorization
    // Declared once, at type level, so the authorization request and the
    // request-status check below can never fall out of step. Asking about a
    // different set than you requested silently reports the wrong status.
    static let readTypes: Set<HKObjectType> = Set([
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

    static let writeTypes: Set<HKSampleType> = Set([
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

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(toShare: Self.writeTypes, read: Self.readTypes)
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
    func fetchUserHealthData() async -> UserHealthData? {
        var healthData = UserHealthData()

        // Characteristics are synchronous reads and throw when unauthorized.
        // Date of birth being unavailable is not a reason to abandon the rest.
        healthData.dateOfBirth = try? healthStore.dateOfBirthComponents().date
        healthData.biologicalSex = try? healthStore.biologicalSex().biologicalSex

        // Six independent queries, run concurrently. Each returns its value
        // rather than writing into `healthData` from a background callback.
        async let weight = fetchLatestQuantity(for: .bodyMass)
        async let height = fetchLatestQuantity(for: .height)
        async let systolic = fetchLatestQuantity(for: .bloodPressureSystolic)
        async let diastolic = fetchLatestQuantity(for: .bloodPressureDiastolic)
        async let glucose = fetchLatestQuantity(for: .bloodGlucose)
        async let heartRate = fetchLatestQuantity(for: .heartRate)

        let mgPerDL = HKUnit.gramUnit(with: .milli).unitDivided(by: HKUnit.literUnit(with: .deci))
        let beatsPerMinute = HKUnit.count().unitDivided(by: .minute())

        healthData.weight = await weight?.doubleValue(for: .gramUnit(with: .kilo))
        healthData.height = await height?.doubleValue(for: .meter())
        healthData.bloodPressureSystolic = await systolic?.doubleValue(for: .millimeterOfMercury())
        healthData.bloodPressureDiastolic = await diastolic?.doubleValue(for: .millimeterOfMercury())
        healthData.bloodGlucose = await glucose?.doubleValue(for: mgPerDL)
        healthData.heartRate = await heartRate?.doubleValue(for: beatsPerMinute)

        // Nil when nothing came back, rather than an instance of all-nil
        // fields. The old unconditional return made `healthData != nil`
        // meaningless: it was true even when every permission was denied, so
        // the settings screen showed "Connected" regardless.
        return healthData.hasAnyData ? healthData : nil
    }

    // MARK: - Authorization Request Status

    /// Whether requesting authorization would still show a permission sheet.
    ///
    /// The closest thing to a connection check HealthKit offers. Read
    /// authorization is deliberately never disclosed — `authorizationStatus(for:)`
    /// reports sharing only, so that an app cannot infer the absence of data
    /// from a refusal. This at least distinguishes "never asked" from
    /// "already answered", which is what a settings screen actually needs.
    func authorizationRequestStatus() async -> HKAuthorizationRequestStatus {
        guard HKHealthStore.isHealthDataAvailable() else { return .unknown }

        return await withCheckedContinuation { continuation in
            healthStore.getRequestStatusForAuthorization(
                toShare: Self.writeTypes,
                read: Self.readTypes
            ) { status, _ in
                continuation.resume(returning: status)
            }
        }
    }

    // MARK: - Query Helpers

    /// Most recent value for a quantity type, or nil when absent or unauthorized.
    private func fetchLatestQuantity(for identifier: HKQuantityTypeIdentifier) async -> HKQuantity? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )

        let samples = try? await descriptor.result(for: healthStore)
        return samples?.first?.quantity
    }

    /// All samples of one type in a date range. Empty when absent or unauthorized.
    private func fetchSamples(
        ofType sampleType: HKSampleType,
        from startDate: Date,
        to endDate: Date
    ) async -> [HKSample] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.sample(type: sampleType, predicate: predicate)],
            sortDescriptors: []
        )

        return (try? await descriptor.result(for: healthStore)) ?? []
    }

    // MARK: - Write Data to HealthKit

    /// Write meal nutrition data to HealthKit
    func writeMealToHealthKit(_ meal: Meal) async throws {
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
            throw HealthKitError.noData
        }

        try await healthStore.save(samples)
    }

    /// Write symptom data to HealthKit.
    /// Maps GutCheck symptom properties to the most relevant HK category types,
    /// only including types that have been authorized.
    func writeSymptomToHealthKit(_ symptom: Symptom) async throws {
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
                throw HealthKitError.invalidData
            }
            samples.append(HKCategorySample(type: fallbackType,
                                            value: painSeverity(symptom.painLevel),
                                            start: start, end: end, metadata: meta))
        }

        try await healthStore.save(samples)
    }

    /// Write water intake to HealthKit
    func writeWaterIntakeToHealthKit(amount: Double, date: Date = Date.now) async throws {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            throw HealthKitError.invalidData
        }

        let waterQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amount)
        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: date, end: date)

        try await healthStore.save(waterSample)
    }

    // MARK: - Fetch Additional Health Data

    /// Fetch sleep data for a specific date range
    func fetchSleepData(from startDate: Date, to endDate: Date) async -> [HKSample] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }
        return await fetchSamples(ofType: sleepType, from: startDate, to: endDate)
    }

    /// Fetch blood pressure data for a specific date range.
    ///
    /// Returns systolic and diastolic samples together. The previous version ran
    /// both queries, discarded the results in empty handlers, and returned `[]`
    /// unconditionally — so `GutHealthData.bloodPressureData` was always empty.
    /// Callers that render or analyse it will now see real samples.
    func fetchBloodPressureData(from startDate: Date, to endDate: Date) async -> [HKSample] {
        guard let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            return []
        }

        async let systolic = fetchSamples(ofType: systolicType, from: startDate, to: endDate)
        async let diastolic = fetchSamples(ofType: diastolicType, from: startDate, to: endDate)

        return await systolic + diastolic
    }

    /// Fetch blood glucose data for a specific date range
    func fetchBloodGlucoseData(from startDate: Date, to endDate: Date) async -> [HKSample] {
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
            return []
        }
        return await fetchSamples(ofType: glucoseType, from: startDate, to: endDate)
    }

    /// Fetch heart rate data for a specific date range
    func fetchHeartRateData(from startDate: Date, to endDate: Date) async -> [HKSample] {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return []
        }
        return await fetchSamples(ofType: heartRateType, from: startDate, to: endDate)
    }

    /// Fetch step count data for a specific date range
    func fetchStepCountData(from startDate: Date, to endDate: Date) async -> [HKSample] {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return []
        }
        return await fetchSamples(ofType: stepType, from: startDate, to: endDate)
    }

    /// Fetch comprehensive health data for gut health analysis
    func fetchGutHealthData(from startDate: Date, to endDate: Date) async -> GutHealthData {
        // Ten independent queries. `async let` starts them all before the first
        // `await`, so this is as concurrent as the DispatchGroup version was,
        // without the shared mutable aggregate.
        async let sleep = fetchSleepData(from: startDate, to: endDate)
        async let bloodPressure = fetchBloodPressureData(from: startDate, to: endDate)
        async let bloodGlucose = fetchBloodGlucoseData(from: startDate, to: endDate)
        async let heartRate = fetchHeartRateData(from: startDate, to: endDate)
        async let stepCount = fetchStepCountData(from: startDate, to: endDate)
        async let bodyFat = fetchLatestQuantity(for: .bodyFatPercentage)
        async let waist = fetchLatestQuantity(for: .waistCircumference)
        async let bmi = fetchLatestQuantity(for: .bodyMassIndex)
        async let respiratoryRate = fetchLatestQuantity(for: .respiratoryRate)
        async let oxygenSaturation = fetchLatestQuantity(for: .oxygenSaturation)

        let breathsPerMinute = HKUnit.count().unitDivided(by: .minute())

        var gutHealthData = GutHealthData()
        gutHealthData.sleepData = await sleep
        gutHealthData.bloodPressureData = await bloodPressure
        gutHealthData.bloodGlucoseData = await bloodGlucose
        gutHealthData.heartRateData = await heartRate
        gutHealthData.stepCountData = await stepCount
        gutHealthData.bodyFatPercentage = await bodyFat?.doubleValue(for: .percent())
        gutHealthData.waistCircumference = await waist?.doubleValue(for: .meter())
        gutHealthData.bodyMassIndex = await bmi?.doubleValue(for: .count())
        gutHealthData.respiratoryRate = await respiratoryRate?.doubleValue(for: breathsPerMinute)
        gutHealthData.oxygenSaturation = await oxygenSaturation?.doubleValue(for: .percent())

        return gutHealthData
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
