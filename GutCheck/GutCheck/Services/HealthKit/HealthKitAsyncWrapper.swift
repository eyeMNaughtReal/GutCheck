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
    
    // MARK: - Convenience Methods with Logging
    func writeMealWithLogging(_ meal: Meal) async {
        let (success, error) = await writeMeal(meal)
        if success {
        } else if let error = error {
        }
    }
    
    func writeSymptomWithLogging(_ symptom: Symptom) async {
        let (success, error) = await writeSymptom(symptom)
        if success {
        } else if let error = error {
        }
    }
    
    func requestAuthorizationWithLogging() async -> Bool {
        let (granted, error) = await requestAuthorization()
        if granted {
        } else {
            if let error = error {
            } else {
            }
        }
        return granted
    }
    
    func fetchUserHealthDataWithLogging() async -> UserHealthData? {
        let healthData = await fetchUserHealthData()
        if healthData != nil {
        } else {
        }
        return healthData
    }
}