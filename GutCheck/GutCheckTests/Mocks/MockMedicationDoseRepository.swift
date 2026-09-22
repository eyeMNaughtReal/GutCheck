import Foundation
@testable import GutCheck

@MainActor
final class MockMedicationDoseRepository: MedicationDoseRepositoryProtocol {
    // Configurable return values
    var dosesToReturn: [MedicationDoseLog] = []
    var doseToReturn: MedicationDoseLog? = nil
    var errorToThrow: Error? = nil

    // Call tracking
    var savedDoses: [MedicationDoseLog] = []
    var deletedIds: [String] = []
    /// Counts range queries, so a caller issuing one query per day instead of
    /// one per range is visible to a test.
    var rangeFetchCallCount = 0

    func save(_ item: MedicationDoseLog) async throws {
        if let error = errorToThrow { throw error }
        savedDoses.append(item)
    }

    func fetch(id: String) async throws -> MedicationDoseLog? {
        if let error = errorToThrow { throw error }
        return doseToReturn
    }

    func delete(id: String) async throws {
        if let error = errorToThrow { throw error }
        deletedIds.append(id)
    }

    func fetchDosesForDate(_ date: Date, userId: String) async throws -> [MedicationDoseLog] {
        if let error = errorToThrow { throw error }
        return dosesToReturn
    }

    func fetchDosesForDateRange(startDate: Date, endDate: Date, userId: String) async throws -> [MedicationDoseLog] {
        if let error = errorToThrow { throw error }
        rangeFetchCallCount += 1
        return dosesToReturn
    }

    func fetchRecentDoses(userId: String, limit: Int) async throws -> [MedicationDoseLog] {
        if let error = errorToThrow { throw error }
        return Array(dosesToReturn.prefix(limit))
    }
}
