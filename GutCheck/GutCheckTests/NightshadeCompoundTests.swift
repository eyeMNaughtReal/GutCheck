//
//  NightshadeCompoundTests.swift
//  GutCheckTests
//
//  The nightshade family shares a dietary tag, not a compound profile. A
//  single mapping used to attach all four compounds to every nightshade, so
//  McDonald's fries reported capsaicin and were tagged "Spicy".
//

import Foundation
import Testing
@testable import GutCheck

@Suite("Nightshade compound attribution")
struct NightshadeCompoundTests {

    private func compoundNames(for ingredients: [String]) -> Set<String> {
        Set(FoodCompoundDatabase.shared.analyzeIngredients(ingredients).map(\.name))
    }

    // MARK: - Potato

    @Test("Potatoes do not report capsaicin")
    func potatoHasNoCapsaicin() {
        // Capsaicin occurs only in Capsicum. This is what produced the
        // "Spicy" tag on a McDonald's fry.
        #expect(!compoundNames(for: ["potatoes"]).contains("Capsaicin"))
    }

    @Test("Potatoes do not report the tomato glycoalkaloid")
    func potatoHasNoTomatine() {
        #expect(!compoundNames(for: ["potatoes"]).contains("α-Tomatine"))
    }

    @Test("Potatoes report their own glycoalkaloids")
    func potatoHasItsOwnGlycoalkaloids() {
        let compounds = compoundNames(for: ["potatoes"])

        #expect(compounds.contains("α-Solanine"))
        #expect(compounds.contains("α-Chaconine"))
    }

    // MARK: - Sweet potato

    @Test("Sweet potato is not treated as a nightshade")
    func sweetPotatoIsNotANightshade() {
        // Convolvulaceae, not Solanaceae — no glycoalkaloids. Substring
        // matching would otherwise catch it via "potato".
        let compounds = compoundNames(for: ["sweet potato"])

        #expect(!compounds.contains("α-Solanine"))
        #expect(!compounds.contains("α-Chaconine"))
    }

    // MARK: - Pepper and tomato

    @Test("Peppers report capsaicin")
    func peppersHaveCapsaicin() {
        #expect(compoundNames(for: ["jalapeño"]).contains("Capsaicin"))
    }

    @Test("Tomatoes report tomatine and not capsaicin")
    func tomatoProfile() {
        let compounds = compoundNames(for: ["tomatoes"])

        #expect(compounds.contains("α-Tomatine"))
        #expect(!compounds.contains("Capsaicin"))
    }

    @Test("Aubergine reports solasonine rather than the potato glycoalkaloids")
    func eggplantProfile() {
        let compounds = compoundNames(for: ["eggplant"])

        #expect(compounds.contains("Solasonine"))
        #expect(!compounds.contains("Capsaicin"))
    }

    // MARK: - The reported symptom

    @Test("McDonald's fries are not tagged spicy")
    func friesAreNotSpicy() {
        let breakdown = IngredientBreakdownService.shared.analyzeFood(
            name: "McDonald's, French Fries, Medium"
        )

        #expect(!breakdown.dietaryTags.contains(.spicy))
        #expect(!breakdown.flaggedCompounds.contains { $0.name == "Capsaicin" })
    }

    @Test("Fries are still tagged as a nightshade")
    func friesRemainANightshade() {
        // The family grouping is legitimate and useful for elimination diets;
        // only the per-plant compound attribution was wrong.
        let breakdown = IngredientBreakdownService.shared.analyzeFood(
            name: "McDonald's, French Fries, Medium"
        )

        #expect(breakdown.dietaryTags.contains(.nightshade))
    }
}
