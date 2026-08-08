//
//  BrandedFoodRiskTests.swift
//  GutCheckTests
//
//  A Big Mac scored 0 with "No known risk factors" — a green shield on one of
//  the most trigger-dense items on any menu — because nothing about it could be
//  analysed and the app reported that absence as safety.
//

import Foundation
import Testing
@testable import GutCheck

@Suite("Branded food name aliasing")
struct BrandedNameAliasTests {

    private func inferredIngredients(for name: String) -> [String] {
        FoodCompoundDatabase.shared.getIngredientsForFood(name: name, providedIngredients: [])
    }

    @Test("A Big Mac resolves to burger ingredients")
    func bigMacResolves() {
        // The exact string the search API returns, which matched no composite
        // keyword: "burger" does not appear anywhere in it.
        let ingredients = inferredIngredients(for: "Big Mac (Mcdonalds)")

        #expect(!ingredients.isEmpty, "expected burger ingredients, got none")
        #expect(ingredients.contains { $0.contains("beef") })
        #expect(ingredients.contains { $0.contains("bun") })
    }

    @Test("Other branded names resolve too")
    func otherBrandedNames() {
        #expect(!inferredIngredients(for: "Whopper").isEmpty)
        #expect(!inferredIngredients(for: "Crunchwrap Supreme").isEmpty)
        #expect(!inferredIngredients(for: "Frosty").isEmpty)
    }

    @Test("Every alias points at a composite that actually exists")
    func aliasesHaveRealTargets() {
        // An alias to a non-existent composite looks like coverage and does
        // nothing — the same silent-gap failure this table exists to close.
        // Caught two of these in review; this makes it impossible to reship.
        for (branded, generic) in FoodCompoundDatabase.brandedNameAliases {
            let resolved = inferredIngredients(for: branded)
            #expect(
                !resolved.isEmpty,
                "alias '\(branded)' → '\(generic)' resolved to nothing; no composite matches '\(generic)'"
            )
        }
    }

    @Test("Aliasing does not disturb names that already matched")
    func genericNamesUnaffected() {
        let burger = inferredIngredients(for: "cheeseburger")

        #expect(!burger.isEmpty)
        #expect(burger.contains { $0.contains("beef") })
    }

    @Test("An unrecognised name still yields nothing rather than a wrong guess")
    func unknownNameStaysUnknown() {
        // Better to report "unknown" than to invent ingredients.
        #expect(inferredIngredients(for: "Zzyzx Brand Mystery Item").isEmpty)
    }
}

@Suite("Unknown vs low risk")
@MainActor
struct UnknownRiskTests {

    private func item(name: String, ingredients: [String] = []) -> FoodItem {
        FoodItem(name: name, quantity: "1 serving", ingredients: ingredients)
    }

    @Test("A food with no ingredient data is unknown, not low risk")
    func noDataIsUnknown() throws {
        let assessment = try #require(
            MealRiskPredictionService.shared.predictRisk(for: [item(name: "Zzyzx Mystery Item")])
        )

        let detail = assessment.foodItemRisks[0]

        // The bug: this reported .low with score 0 and a green shield.
        #expect(detail.riskLevel == .unknown)
        #expect(!detail.explanation.contains("No known risk factors"))
    }

    @Test("A food that was analysed and came back clean is still low risk")
    func analysedCleanStaysLow() throws {
        // Has ingredients, so it genuinely was assessed.
        let assessment = try #require(
            MealRiskPredictionService.shared.predictRisk(
                for: [item(name: "Plain Water", ingredients: ["water"])]
            )
        )

        #expect(assessment.foodItemRisks[0].riskLevel != .unknown)
    }

    @Test("Unknown items don't drag a risky meal's score down")
    func unknownDoesNotDilute() throws {
        let service = MealRiskPredictionService.shared

        let riskyAlone = try #require(
            service.predictRisk(for: [item(name: "Fries", ingredients: ["potatoes", "oil", "salt"])])
        )
        let riskyPlusUnknown = try #require(
            service.predictRisk(for: [
                item(name: "Fries", ingredients: ["potatoes", "oil", "salt"]),
                item(name: "Zzyzx Mystery Item")
            ])
        )

        // Adding an unassessable item must not make the meal look safer.
        #expect(riskyPlusUnknown.overallRiskScore >= riskyAlone.overallRiskScore)
    }

    @Test("A meal of only unknown items is reported as unknown")
    func whollyUnknownMeal() throws {
        let assessment = try #require(
            MealRiskPredictionService.shared.predictRisk(for: [item(name: "Zzyzx Mystery Item")])
        )

        #expect(assessment.overallRiskLevel == .unknown)
        #expect(assessment.overallExplanation.contains("can't be assessed"))
    }

    @Test("An unassessable item is called out even when the rest scored")
    func caveatSurfacedAlongsideScore() throws {
        let assessment = try #require(
            MealRiskPredictionService.shared.predictRisk(for: [
                item(name: "Fries", ingredients: ["potatoes", "oil", "salt"]),
                item(name: "Zzyzx Mystery Item")
            ])
        )

        #expect(assessment.overallExplanation.contains("couldn't be assessed"))
    }
}
