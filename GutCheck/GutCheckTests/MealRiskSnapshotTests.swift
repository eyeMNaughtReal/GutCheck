//
//  MealRiskSnapshotTests.swift
//  GutCheckTests
//
//  The risk assessment used to be computed while building a meal and dropped on
//  save. These cover the persisted snapshot that replaced that — in particular
//  that "couldn't assess it" survives the round trip as unknown rather than
//  quietly arriving back as a reassuring zero.
//

import Foundation
import SwiftData
import Testing
@testable import GutCheck

@Suite("Meal risk snapshot persistence")
@MainActor
struct MealRiskSnapshotTests {

    // MARK: - Fixtures

    private func detail(
        name: String,
        score: Int,
        level: MealRiskLevel,
        source: RiskDataSource,
        explanation: String = "because"
    ) -> FoodItemRiskDetail {
        FoodItemRiskDetail(
            id: UUID(),
            foodName: name,
            riskScore: score,
            riskLevel: level,
            explanation: explanation,
            matchedTriggerPattern: nil,
            flaggedCompounds: [],
            dataSource: source
        )
    }

    private func assessment(_ details: [FoodItemRiskDetail], overall: Int, level: MealRiskLevel) -> MealRiskAssessment {
        MealRiskAssessment(
            overallRiskScore: overall,
            overallRiskLevel: level,
            foodItemRisks: details,
            overallExplanation: "explanation",
            assessedAt: Date(timeIntervalSince1970: 1_700_000_000),
            hasHistoricalData: true
        )
    }

    private func meal(riskSnapshot: MealRiskSnapshot?) -> Meal {
        Meal(
            id: "meal-under-test",
            name: "Test Meal",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            type: .lunch,
            source: .manual,
            foodItems: [FoodItem(name: "Fries", quantity: "1 serving")],
            createdBy: "tester",
            riskSnapshot: riskSnapshot
        )
    }

    /// Writes the meal to a real (in-memory) store and reads it back, so the
    /// test exercises the SwiftData attribute rather than just the structs.
    private func roundTripThroughStore(_ meal: Meal) throws -> Meal {
        let container = try SwiftDataStack.inMemoryContainer()
        let context = ModelContext(container)

        context.insert(StoredMeal(meal))
        try context.save()

        let id = meal.id
        let descriptor = FetchDescriptor<StoredMeal>(predicate: #Predicate { $0.id == id })
        let stored = try #require(try context.fetch(descriptor).first)
        return stored.domainModel
    }

    // MARK: - Round trip

    @Test("A saved meal comes back with the score and per-item breakdown it had")
    func snapshotSurvivesSave() throws {
        let snapshot = MealRiskSnapshot(assessment(
            [
                detail(name: "Fries", score: 54, level: .moderate, source: .compoundAnalysis,
                       explanation: "Fries contains Solanine, Trans Fats which may cause digestive issues"),
                detail(name: "Water", score: 0, level: .low, source: .compoundAnalysis)
            ],
            overall: 54,
            level: .moderate
        ))

        let loaded = try roundTripThroughStore(meal(riskSnapshot: snapshot))
        let restored = try #require(loaded.riskSnapshot)

        #expect(restored.overallRiskScore == 54)
        #expect(restored.overallRiskLevel == .moderate)
        #expect(restored.foodItemRisks.count == 2)
        #expect(restored.foodItemRisks[0].foodName == "Fries")
        #expect(restored.foodItemRisks[0].riskScore == 54)
        #expect(restored.foodItemRisks[0].explanation.contains("Solanine"))
        #expect(restored.foodItemRisks[0].dataSource == .compoundAnalysis)
        #expect(restored.schemaVersion == MealRiskSnapshot.currentSchemaVersion)
    }

    @Test("Unknown stays unknown rather than round-tripping as a low-risk zero")
    func unknownSurvivesAsUnknown() throws {
        let snapshot = MealRiskSnapshot(assessment(
            [detail(name: "Zzyzx Mystery Item", score: 0, level: .unknown, source: .insufficientData)],
            overall: 0,
            level: .unknown
        ))

        let loaded = try roundTripThroughStore(meal(riskSnapshot: snapshot))
        let restored = try #require(loaded.riskSnapshot)

        #expect(restored.overallRiskLevel == .unknown)
        #expect(restored.overallRiskLevel != .low)
        // Absent, not zero — the same rule `Meal.nutrition` follows.
        #expect(restored.overallRiskScore == nil)

        let item = try #require(restored.foodItemRisks.first)
        #expect(item.riskLevel == .unknown)
        #expect(item.riskScore == nil)
        #expect(item.dataSource == .insufficientData)
    }

    @Test("An unknown item keeps its unknown level when replayed for the card")
    func unknownSurvivesReplay() throws {
        let snapshot = MealRiskSnapshot(assessment(
            [
                detail(name: "Fries", score: 54, level: .moderate, source: .compoundAnalysis),
                detail(name: "Zzyzx Mystery Item", score: 0, level: .unknown, source: .insufficientData)
            ],
            overall: 54,
            level: .moderate
        ))

        let replayed = try #require(try roundTripThroughStore(meal(riskSnapshot: snapshot)).riskSnapshot).assessment

        #expect(replayed.overallRiskScore == 54)
        #expect(replayed.overallRiskLevel == .moderate)
        #expect(replayed.foodItemRisks[1].riskLevel == .unknown)
        #expect(replayed.foodItemRisks[1].dataSource == .insufficientData)
    }

    @Test("Item identity is stable across reads so the list doesn't churn")
    func itemIdentityIsStable() throws {
        let original = detail(name: "Fries", score: 54, level: .moderate, source: .compoundAnalysis)
        let snapshot = MealRiskSnapshot(assessment([original], overall: 54, level: .moderate))

        let restored = try #require(try roundTripThroughStore(meal(riskSnapshot: snapshot)).riskSnapshot)

        #expect(restored.foodItemRisks[0].id == original.id)
    }

    // MARK: - Existing records

    @Test("A meal saved before risk was recorded still loads, with no assessment")
    func preExistingMealLoads() throws {
        // What every row already in the store looks like: no risk column value.
        let loaded = try roundTripThroughStore(meal(riskSnapshot: nil))

        #expect(loaded.riskSnapshot == nil)
        #expect(loaded.name == "Test Meal")
        #expect(loaded.foodItems.count == 1)
    }

    @Test("Decoding a Meal from JSON without the risk key succeeds")
    func legacyJSONDecodes() throws {
        // Meals are also encoded whole in a few places; an added optional must
        // not make older payloads undecodable.
        let json = """
        {
          "id": "legacy", "name": "Old Lunch", "date": 0, "type": "lunch",
          "source": "manual", "foodItems": [], "tags": [], "createdBy": "",
          "createdAt": 0, "updatedAt": 0
        }
        """
        let decoded = try JSONDecoder().decode(Meal.self, from: Data(json.utf8))

        #expect(decoded.riskSnapshot == nil)
        #expect(decoded.name == "Old Lunch")
    }

    @Test("Unreadable stored bytes read as no assessment, not a clean bill")
    func corruptSnapshotDegradesToNil() throws {
        let stored = StoredMeal(meal(riskSnapshot: nil))
        stored.riskSnapshotData = Data("not json".utf8)

        #expect(stored.domainModel.riskSnapshot == nil)
    }

    // MARK: - Forward compatibility

    @Test("A risk level this build doesn't know reads as unknown, not low")
    func unrecognisedLevelIsUnknown() throws {
        let json = """
        {
          "schemaVersion": 99,
          "overallRiskLevelRawValue": "catastrophic",
          "overallExplanation": "from a future build",
          "assessedAt": 0,
          "hasHistoricalData": false,
          "foodItemRisks": [{
            "id": "\(UUID().uuidString)",
            "foodName": "Something",
            "riskLevelRawValue": "catastrophic",
            "explanation": "e",
            "dataSourceRawValue": "telepathy",
            "flaggedCompoundNames": []
          }]
        }
        """
        let snapshot = try JSONDecoder().decode(MealRiskSnapshot.self, from: Data(json.utf8))

        #expect(snapshot.overallRiskLevel == .unknown)
        #expect(snapshot.foodItemRisks[0].riskLevel == .unknown)
        #expect(snapshot.foodItemRisks[0].dataSource == .insufficientData)
    }
}

// MARK: - Aggregation

@Suite("Meal risk aggregation")
@MainActor
struct MealRiskAggregationTests {

    private let service = MealRiskPredictionService.shared

    private func item(_ name: String, ingredients: [String] = []) -> FoodItem {
        FoodItem(name: name, quantity: "1 serving", ingredients: ingredients)
    }

    @Test("Adding a zero-risk item never lowers the meal's score")
    func safeItemDoesNotDilute() throws {
        let fries = item("Fries", ingredients: ["potatoes", "oil", "salt"])
        // Has ingredients, so it is genuinely assessed — and comes back clean.
        let water = item("Plain Water", ingredients: ["water"])

        let alone = try #require(service.predictRisk(for: [fries]))
        let withSafeItem = try #require(service.predictRisk(for: [fries, water]))

        #expect(withSafeItem.overallRiskScore >= alone.overallRiskScore)
    }

    @Test("A second risky item raises the score rather than averaging it away")
    func riskyItemsCompound() throws {
        let fries = item("Fries", ingredients: ["potatoes", "oil", "salt"])
        let cheese = item("Cheddar Cheese", ingredients: ["milk", "cheese"])

        let alone = try #require(service.predictRisk(for: [fries]))
        let both = try #require(service.predictRisk(for: [fries, cheese]))

        // Only meaningful if the second item actually scored.
        let secondScored = both.foodItemRisks.dropFirst().contains { $0.riskScore > 0 }
        if secondScored {
            #expect(both.overallRiskScore > alone.overallRiskScore)
        }
    }
}
