import Foundation
@testable import GutCheck

@MainActor
final class MockSymptomRepository: SymptomRepositoryProtocol {
    // Configurable return values
    var symptomsToReturn: [Symptom] = []
    var symptomToReturn: Symptom? = nil
    var errorToThrow: Error? = nil

    // Call tracking
    var savedSymptoms: [Symptom] = []
    var deletedIds: [String] = []
    var fetchCallCount = 0

    func save(_ item: Symptom) async throws {
        if let error = errorToThrow { throw error }
        savedSymptoms.append(item)
    }

    func fetch(id: String) async throws -> Symptom? {
        if let error = errorToThrow { throw error }
        fetchCallCount += 1
        return symptomToReturn
    }

    func delete(id: String) async throws {
        if let error = errorToThrow { throw error }
        deletedIds.append(id)
    }

    func getSymptoms(for date: Date) async throws -> [Symptom] {
        if let error = errorToThrow { throw error }
        return symptomsToReturn
    }

    func fetchSymptomsForDate(_ date: Date, userId: String) async throws -> [Symptom] {
        if let error = errorToThrow { throw error }
        return symptomsToReturn
    }

    func fetchRecentSymptoms(userId: String, limit: Int) async throws -> [Symptom] {
        if let error = errorToThrow { throw error }
        return Array(symptomsToReturn.prefix(limit))
    }

    func fetchSymptomsForDateRange(startDate: Date, endDate: Date, userId: String) async throws -> [Symptom] {
        if let error = errorToThrow { throw error }
        return symptomsToReturn
    }
}
