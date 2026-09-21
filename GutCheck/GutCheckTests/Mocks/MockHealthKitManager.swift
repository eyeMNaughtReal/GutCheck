import Foundation
import HealthKit
@testable import GutCheck

final class MockHealthKitManager: HealthKitManagerProtocol {
    var gutHealthDataToReturn = GutHealthData()
    var userHealthDataToReturn: UserHealthData?

    /// When set, every throwing method throws this instead of succeeding.
    var errorToThrow: Error?

    /// Drives the connection state under test. `.unnecessary` means the person
    /// has already answered the permission sheet.
    var authorizationRequestStatusToReturn: HKAuthorizationRequestStatus = .shouldRequest

    func requestAuthorization() async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func authorizationRequestStatus() async -> HKAuthorizationRequestStatus {
        authorizationRequestStatusToReturn
    }

    func fetchUserHealthData() async -> UserHealthData? {
        userHealthDataToReturn
    }

    func writeMealToHealthKit(_ meal: Meal) async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func writeSymptomToHealthKit(_ symptom: Symptom) async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func writeWaterIntakeToHealthKit(amount: Double, date: Date) async throws {
        if let errorToThrow { throw errorToThrow }
    }

    func fetchGutHealthData(from startDate: Date, to endDate: Date) async -> GutHealthData {
        gutHealthDataToReturn
    }

    func writeAuthorizationStatus(for quantityTypeID: HKQuantityTypeIdentifier) -> HKAuthorizationStatus {
        return .notDetermined
    }

    func writeAuthorizationStatus(for categoryTypeID: HKCategoryTypeIdentifier) -> HKAuthorizationStatus {
        return .notDetermined
    }
}
