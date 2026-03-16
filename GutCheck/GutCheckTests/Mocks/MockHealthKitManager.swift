import Foundation
import HealthKit
@testable import GutCheck

final class MockHealthKitManager: HealthKitManagerProtocol {
    var gutHealthDataToReturn = GutHealthData()

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }

    func fetchUserHealthData(completion: @escaping (UserHealthData?) -> Void) {
        completion(nil)
    }

    func writeMealToHealthKit(_ meal: Meal, completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }

    func writeSymptomToHealthKit(_ symptom: Symptom, completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }

    func writeWaterIntakeToHealthKit(amount: Double, date: Date, completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }

    func fetchGutHealthData(from startDate: Date, to endDate: Date, completion: @escaping (GutHealthData) -> Void) {
        completion(gutHealthDataToReturn)
    }

    func writeAuthorizationStatus(for quantityTypeID: HKQuantityTypeIdentifier) -> HKAuthorizationStatus {
        return .notDetermined
    }

    func writeAuthorizationStatus(for categoryTypeID: HKCategoryTypeIdentifier) -> HKAuthorizationStatus {
        return .notDetermined
    }
}
