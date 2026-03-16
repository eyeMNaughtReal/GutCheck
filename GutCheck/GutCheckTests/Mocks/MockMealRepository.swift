import Foundation
@testable import GutCheck

@MainActor
final class MockMealRepository: MealRepositoryProtocol {
    // Configurable return values
    var mealsToReturn: [Meal] = []
    var mealToReturn: Meal? = nil
    var errorToThrow: Error? = nil

    // Call tracking
    var savedMeals: [Meal] = []
    var deletedIds: [String] = []
    var fetchCallCount = 0

    func save(_ item: Meal) async throws {
        if let error = errorToThrow { throw error }
        savedMeals.append(item)
    }

    func fetch(id: String) async throws -> Meal? {
        if let error = errorToThrow { throw error }
        fetchCallCount += 1
        return mealToReturn
    }

    func delete(id: String) async throws {
        if let error = errorToThrow { throw error }
        deletedIds.append(id)
    }

    func fetchMealsForDate(_ date: Date, userId: String) async throws -> [Meal] {
        if let error = errorToThrow { throw error }
        return mealsToReturn
    }

    func fetchRecentMeals(userId: String, limit: Int) async throws -> [Meal] {
        if let error = errorToThrow { throw error }
        return Array(mealsToReturn.prefix(limit))
    }

    func fetchMealsForDateRange(startDate: Date, endDate: Date, userId: String) async throws -> [Meal] {
        if let error = errorToThrow { throw error }
        return mealsToReturn
    }
}
