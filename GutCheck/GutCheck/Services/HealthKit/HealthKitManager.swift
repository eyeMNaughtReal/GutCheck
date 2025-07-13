import Foundation
import HealthKit

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

    // MARK: - Fetch User Profile
    func fetchUserProfile(completion: @escaping (UserHealthProfile?) -> Void) {
        var profile = UserHealthProfile()

        do {
            if let dob = try healthStore.dateOfBirthComponents().date {
                profile.dateOfBirth = dob
            }

            if let biologicalSex = try? healthStore.biologicalSex().biologicalSex {
                profile.biologicalSex = biologicalSex
            }

            let group = DispatchGroup()

            group.enter()
            fetchLatestQuantity(for: .bodyMass) { quantity in
                profile.weight = quantity?.doubleValue(for: .gramUnit(with: .kilo))
                group.leave()
            }

            group.enter()
            fetchLatestQuantity(for: .height) { quantity in
                profile.height = quantity?.doubleValue(for: .meter())
                group.leave()
            }

            group.notify(queue: .main) {
                completion(profile)
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

// ...existing code...

// MARK: - Custom Error
enum HealthKitError: Error {
    case notAvailable
}
