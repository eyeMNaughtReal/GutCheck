import Testing
import Foundation
@testable import GutCheck

struct InsightModelsTests {

    // MARK: - InsightCategory

    @Test("InsightCategory has 4 cases")
    func insightCategoryCount() {
        #expect(InsightCategory.allCases.count == 4)
    }

    @Test("InsightCategory id matches rawValue", arguments: InsightCategory.allCases)
    func insightCategoryId(category: InsightCategory) {
        #expect(category.id == category.rawValue)
    }

    @Test("InsightCategory properties are non-empty", arguments: InsightCategory.allCases)
    func insightCategoryProperties(category: InsightCategory) {
        #expect(!category.iconName.isEmpty)
        #expect(!category.description.isEmpty)
        #expect(!category.title.isEmpty)
    }

    // MARK: - InsightType

    @Test("InsightType Codable round-trip", arguments: [
        InsightType.foodTrigger,
        InsightType.symptomPattern,
        InsightType.mealTiming,
        InsightType.nutritionTrend,
        InsightType.activityCorrelation,
        InsightType.recommendation
    ])
    func insightTypeCodable(type: InsightType) throws {
        let data = try JSONEncoder().encode(type)
        let decoded = try JSONDecoder().decode(InsightType.self, from: data)
        #expect(decoded == type)
    }

    // MARK: - InsightStatus

    @Test("InsightStatus Codable round-trip", arguments: [
        InsightStatus.active,
        InsightStatus.resolved,
        InsightStatus.dismissed,
        InsightStatus.archived
    ])
    func insightStatusCodable(status: InsightStatus) throws {
        let data = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(InsightStatus.self, from: data)
        #expect(decoded == status)
    }

    // MARK: - InsightConfidenceLevel

    @Test("InsightConfidenceLevel percentages increase with level")
    func confidenceLevelPercentages() {
        #expect(InsightConfidenceLevel.low.percentage < InsightConfidenceLevel.medium.percentage)
        #expect(InsightConfidenceLevel.medium.percentage < InsightConfidenceLevel.high.percentage)
    }

    @Test("InsightConfidenceLevel descriptions are non-empty")
    func confidenceLevelDescriptions() {
        #expect(!InsightConfidenceLevel.low.description.isEmpty)
        #expect(!InsightConfidenceLevel.medium.description.isEmpty)
        #expect(!InsightConfidenceLevel.high.description.isEmpty)
    }

    @Test("InsightConfidenceLevel raw values are ordered")
    func confidenceLevelRawValues() {
        #expect(InsightConfidenceLevel.low.rawValue == 1)
        #expect(InsightConfidenceLevel.medium.rawValue == 2)
        #expect(InsightConfidenceLevel.high.rawValue == 3)
    }

    // MARK: - HealthRecommendation.RecommendationPriority

    @Test("RecommendationPriority is comparable")
    func priorityComparable() {
        #expect(HealthRecommendation.RecommendationPriority.low < .medium)
        #expect(HealthRecommendation.RecommendationPriority.medium < .high)
    }

    // MARK: - MealType enum

    @Test("MealType has 5 cases")
    func mealTypeCount() {
        #expect(MealType.allCases.count == 5)
    }

    @Test("MealType Codable round-trip", arguments: MealType.allCases)
    func mealTypeCodable(type: MealType) throws {
        let data = try JSONEncoder().encode(type)
        let decoded = try JSONDecoder().decode(MealType.self, from: data)
        #expect(decoded == type)
    }

    // MARK: - Meal computed properties

    @Test("Meal with notes is private")
    func mealWithNotesIsPrivate() {
        let meal = Meal(
            name: "Lunch",
            date: Date(),
            type: .lunch,
            source: .manual,
            foodItems: [],
            notes: "Had a bad reaction"
        )
        #expect(meal.privacyLevel == .private)
        #expect(meal.requiresLocalStorage)
        #expect(!meal.allowsCloudSync)
    }

    @Test("Meal with location tag is private")
    func mealWithLocationTagIsPrivate() {
        let meal = Meal(
            name: "Dinner",
            date: Date(),
            type: .dinner,
            source: .manual,
            foodItems: [],
            tags: ["location"]
        )
        #expect(meal.privacyLevel == .private)
    }

    @Test("Basic meal without notes or tags is public")
    func basicMealIsPublic() {
        let meal = Meal(
            name: "Breakfast",
            date: Date(),
            type: .breakfast,
            source: .manual,
            foodItems: []
        )
        #expect(meal.privacyLevel == .public)
        #expect(!meal.requiresLocalStorage)
        #expect(meal.allowsCloudSync)
    }
}
