//
//  HealthKitManagerProtocol.swift
//  GutCheck
//
//  Protocol for HealthKitManager to enable dependency injection and testability.
//

import Foundation
import HealthKit

protocol HealthKitManagerProtocol {
    func requestAuthorization() async throws
    func fetchUserHealthData() async -> UserHealthData?
    func writeMealToHealthKit(_ meal: Meal) async throws
    func writeSymptomToHealthKit(_ symptom: Symptom) async throws
    func writeWaterIntakeToHealthKit(amount: Double, date: Date) async throws
    func fetchGutHealthData(from startDate: Date, to endDate: Date) async -> GutHealthData
    func writeAuthorizationStatus(for quantityTypeID: HKQuantityTypeIdentifier) -> HKAuthorizationStatus
    func writeAuthorizationStatus(for categoryTypeID: HKCategoryTypeIdentifier) -> HKAuthorizationStatus
}
