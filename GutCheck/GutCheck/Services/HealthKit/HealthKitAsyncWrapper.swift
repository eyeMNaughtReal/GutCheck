//
//  HealthKitAsyncWrapper.swift
//  GutCheck
//
//  Async wrapper for HealthKitManager to eliminate duplicate withCheckedContinuation patterns
//

import Foundation
import HealthKit

@MainActor
class HealthKitAsyncWrapper {
    static let shared = HealthKitAsyncWrapper()
    
    private let healthKitManager = HealthKitManager.shared
    
    private init() {}
    
    // MARK: - Authorization
    func requestAuthorization() async -> (granted: Bool, error: Error?) {
        return await withCheckedContinuation { continuation in
            healthKitManager.requestAuthorization { granted, error in
                continuation.resume(returning: (granted, error))
            }
        }
    }
    
    // MARK: - Data Fetching
    func fetchUserHealthData() async -> UserHealthData? {
        return await withCheckedContinuation { continuation in
            healthKitManager.fetchUserHealthData { healthData in
                continuation.resume(returning: healthData)
            }
        }
    }
    
    // MARK: - Data Writing
    func writeMeal(_ meal: Meal) async -> (success: Bool, error: Error?) {
        return await withCheckedContinuation { continuation in
            healthKitManager.writeMealToHealthKit(meal) { success, error in
                continuation.resume(returning: (success, error))
            }
        }
    }
    
    func writeSymptom(_ symptom: Symptom) async -> (success: Bool, error: Error?) {
        return await withCheckedContinuation { continuation in
            healthKitManager.writeSymptomToHealthKit(symptom) { success, error in
                continuation.resume(returning: (success, error))
            }
        }
    }
    
    // MARK: - Convenience Methods
    func writeMealWithLogging(_ meal: Meal) async {
        _ = await writeMeal(meal)
    }
    
    func writeSymptomWithLogging(_ symptom: Symptom) async {
        _ = await writeSymptom(symptom)
    }
    
    func requestAuthorizationWithLogging() async -> Bool {
        let (granted, _) = await requestAuthorization()
        return granted
    }
    
    func fetchUserHealthDataWithLogging() async -> UserHealthData? {
        return await fetchUserHealthData()
    }
}
