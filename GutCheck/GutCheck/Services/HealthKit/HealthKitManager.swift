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

        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
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
}
