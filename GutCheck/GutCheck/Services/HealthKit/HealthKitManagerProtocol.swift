//
//  HealthKitManagerProtocol.swift
//  GutCheck
//
//  Protocol for HealthKitManager to enable dependency injection and testability.
//

import Foundation
import HealthKit

protocol HealthKitManagerProtocol {
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void)
    func fetchUserHealthData(completion: @escaping (UserHealthData?) -> Void)
    func writeMealToHealthKit(_ meal: Meal, completion: @escaping (Bool, Error?) -> Void)
    func writeSymptomToHealthKit(_ symptom: Symptom, completion: @escaping (Bool, Error?) -> Void)
    func writeWaterIntakeToHealthKit(amount: Double, date: Date, completion: @escaping (Bool, Error?) -> Void)
    func fetchGutHealthData(from startDate: Date, to endDate: Date, completion: @escaping (GutHealthData) -> Void)
    func writeAuthorizationStatus(for quantityTypeID: HKQuantityTypeIdentifier) -> HKAuthorizationStatus
    func writeAuthorizationStatus(for categoryTypeID: HKCategoryTypeIdentifier) -> HKAuthorizationStatus
}
