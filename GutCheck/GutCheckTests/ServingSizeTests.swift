//
//  ServingSizeTests.swift
//  GutCheckTests
//
//  Pins the serving-size maths from #359: every searched food used to be
//  logged per 100 g, so a Big Mac recorded 46% of a sandwich. These cover the
//  three pieces that decide what actually gets logged — which portion is
//  picked, what it scales the numbers by, and that the micronutrient strings
//  move with the macros.
//
//  Note: CI builds but does not run tests. These are here for when it does,
//  and for running locally with ⌘U.
//

import Testing
@testable import GutCheck

@Suite("Serving sizes")
struct ServingSizeTests {

    // MARK: - Helpers

    private func option(_ label: String, _ grams: Double) -> ServingOption {
        guard let option = ServingOption(label: label, gramWeight: grams) else {
            Issue.record("\(label) at \(grams) g should be a valid serving option")
            // Never reached; keeps the return type non-optional at call sites.
            return ServingOption(label: "fallback", gramWeight: 1)!
        }
        return option
    }

    /// The FNDDS measures a "Big Mac (Mcdonalds)" search actually returns,
    /// minus the "Quantity not specified" entry which is passed separately as
    /// the source's own preferred weight.
    private var bigMacMeasures: [ServingOption] {
        ServingSizeResolver.normalize([
            option("1 MCDonald's Mac Jr", 135),
            option("1 McDonald's Big Mac", 205),
            option("1 McDonald's Grand Mac", 315),
            option("100 g", 100)
        ])
    }

    /// The measures on USDA's "Potato, french fries, restaurant", trimmed to
    /// the ones that matter here.
    private var restaurantFryMeasures: [ServingOption] {
        ServingSizeResolver.normalize([
            option("1 kids meal order", 70),
            option("1 small fast food order", 110),
            option("1 medium fast food order", 145),
            option("1 large fast food order", 180),
            option("100 g", 100)
        ])
    }

    // MARK: - ServingOption

    @Test("A serving with no weight is not a serving")
    func rejectsUnusableOptions() {
        #expect(ServingOption(label: "1 sandwich", gramWeight: 0) == nil)
        #expect(ServingOption(label: "1 sandwich", gramWeight: -5) == nil)
        #expect(ServingOption(label: "   ", gramWeight: 205) == nil)
    }

    @Test("A named portion shows its weight, a weight does not repeat itself")
    func displayNameShowsWeightOnlyWhenItAddsSomething() {
        #expect(option("1 McDonald's Big Mac", 205).displayName == "1 McDonald's Big Mac · 205 g")
        #expect(option("100 g", 100).displayName == "100 g")
        // A volume keeps the source's own unit rather than claiming a density.
        #expect(option("25 ml", 25).displayName == "25 ml")
    }

    @Test("The quantity line states the total weight, not the unit weight")
    func quantityDescriptionMultipliesTheWeight() {
        let medium = option("1 medium fast food order", 145)
        #expect(medium.quantityDescription(count: 1) == "1 medium fast food order · 145 g")
        #expect(medium.quantityDescription(count: 2) == "2 × 1 medium fast food order · 290 g")
    }

    // MARK: - Default selection

    @Test("A Big Mac defaults to the Big Mac, not the Mac Jr or the Grand Mac")
    func defaultsToTheMeasureNamingTheFood() {
        let chosen = ServingSizeResolver.defaultOption(
            forFoodNamed: "Big Mac (Mcdonalds)",
            from: bigMacMeasures,
            preferredGrams: 205
        )
        #expect(chosen?.label == "1 McDonald's Big Mac")
        #expect(chosen?.gramWeight == 205)
    }

    @Test("A size word in the name picks the matching portion")
    func sizeWordInNameWins() {
        let chosen = ServingSizeResolver.defaultOption(
            forFoodNamed: "McDonald's, French Fries, Medium",
            from: restaurantFryMeasures,
            // The source's own default is the small order; the name is more
            // specific than that and has to override it.
            preferredGrams: 110
        )
        #expect(chosen?.label == "1 medium fast food order")
        #expect(chosen?.gramWeight == 145)
    }

    @Test("With nothing to match on, the source's own portion weight decides")
    func fallsBackToThePreferredWeight() {
        let chosen = ServingSizeResolver.defaultOption(
            forFoodNamed: "Potato, french fries, restaurant",
            from: restaurantFryMeasures,
            preferredGrams: 110
        )
        #expect(chosen?.label == "1 small fast food order")
    }

    @Test("An unmatched weight picks nothing rather than the nearest portion")
    func doesNotGuessWhenNothingMatches() {
        // 33 g is nowhere in the list. Returning "1 kids meal order" because it
        // happens to be closest would be a fabricated portion.
        let chosen = ServingSizeResolver.defaultOption(
            forFoodNamed: "Potato, french fries, restaurant",
            from: restaurantFryMeasures,
            preferredGrams: 33
        )
        #expect(chosen == nil)
    }

    @Test("Portions are deduplicated and ordered smallest first")
    func normalizeSortsAndDeduplicates() {
        let normalized = ServingSizeResolver.normalize([
            option("1 large fast food order", 180),
            option("1 small fast food order", 110),
            option("1 small fast food order", 110),
            option("1 kids meal order", 70)
        ])
        #expect(normalized.map(\.gramWeight) == [70, 110, 180])
    }

    // MARK: - Scaling

    /// A Big Mac as the app receives it: nutrition reported against 100 g, with
    /// the sandwich itself offered as a 205 g portion.
    private func bigMacResult() -> FoodSearchResult {
        FoodSearchResult(
            id: "test-big-mac",
            name: "Big Mac (Mcdonalds)",
            calories: 261,
            protein: 12.6,
            carbs: 20.5,
            fat: 14.4,
            // Grams, per the convention both sources normalise to.
            sodium: 0.46,
            servingUnit: "g",
            servingQty: 100,
            servingWeight: 100,
            servingOptions: bigMacMeasures,
            defaultServing: option("1 McDonald's Big Mac", 205)
        )
    }

    @Test("A searched food logs its own portion, not the 100 g it was reported against")
    func scaleFactorUsesTheChosenPortion() {
        let result = bigMacResult()
        #expect(result.baseServingGrams == 100)
        #expect(abs(result.scaleFactor(for: result.defaultServing) - 2.05) < 0.000_001)
        #expect(abs(result.scaleFactor(for: result.defaultServing, count: 2) - 4.10) < 0.000_001)
        // No portion data at all leaves the source's figures alone.
        #expect(result.scaleFactor(for: nil) == 1)
    }

    @Test("Building a food item applies the default portion")
    func toFoodItemUsesTheDefaultServing() {
        let item = bigMacResult().toFoodItem()

        #expect(item.quantity == "1 McDonald's Big Mac · 205 g")
        #expect(item.estimatedWeightInGrams == 205)
        #expect(item.selectedServing?.label == "1 McDonald's Big Mac")
        #expect(item.servingCount == 1)

        // 261 kcal per 100 g over 205 g. Not McDonald's published 563 — that is
        // a different record — but the whole sandwich rather than 46% of it.
        #expect(item.nutrition.calories == 535)
        // Sodium still crosses grams to milligrams on the way out.
        #expect(abs((item.nutrition.sodium ?? 0) - 943) < 0.5)
    }

    @Test("Calories round rather than truncate")
    func caloriesRound() {
        // 261 × 2.05 is 535.05; 261 × 1.999 is 521.7, which truncation would
        // report as 521.
        #expect(NutritionScaling.scaled(NutritionInfo(calories: 261), by: 1.999).calories == 522)
        #expect(NutritionScaling.scaled(NutritionInfo(calories: 261), by: 2.05).calories == 535)
    }

    @Test("Micronutrient strings scale with the macros")
    func detailStringsScale() {
        let details = [
            "Calories": "261kcal",
            "Saturated Fat": "5.2g",
            "Sodium": "460.5mg",
            "Selenium": "26.5mcg"
        ]
        let scaled = NutritionScaling.scaled(details, by: 2)

        #expect(scaled["Calories"] == "522kcal")
        #expect(scaled["Saturated Fat"] == "10.4g")
        #expect(scaled["Sodium"] == "921mg")
        #expect(scaled["Selenium"] == "53mcg")
    }

    @Test("Non-nutrient entries are left alone")
    func detailScalingIgnoresNonNutrients() {
        // "brand" is written into the same dictionary, and a brand that starts
        // with a digit must not be multiplied.
        let scaled = NutritionScaling.scaled(
            ["brand": "McDonald's", "name": "7 Up", "Protein": "12.6g"],
            by: 2
        )

        #expect(scaled["brand"] == "McDonald's")
        #expect(scaled["name"] == "7 Up")
        #expect(scaled["Protein"] == "25.2g")
    }

    @Test("Scaled values survive being read back")
    func scaledValuesRoundTripThroughTheParser() {
        // The strings are re-parsed by NutritionDetailsView, so the fixed
        // en_US_POSIX separator convention has to survive the rewrite.
        let scaled = NutritionScaling.scaled(["Sodium": "1093mg"], by: 1.5)
        #expect(NutrientValueParser.number(from: scaled["Sodium"] ?? "") == 1639.5)
    }

    // MARK: - OpenFoodFacts weights

    @Test("A bare serving size is grams, a volume is not a weight")
    func parsesOpenFoodFactsWeights() {
        // OpenFoodFacts records the European Big Mac's serving size as "219".
        #expect(OpenFoodFactsService.weightInGrams(from: "219") == 219)
        #expect(OpenFoodFactsService.weightInGrams(from: "30 g") == 30)
        #expect(OpenFoodFactsService.weightInGrams(from: "30g (1 biscuit)") == 30)
        #expect(OpenFoodFactsService.weightInGrams(from: "25 ml") == nil)
        #expect(OpenFoodFactsService.weightInGrams(from: "1 cup") == nil)
        #expect(OpenFoodFactsService.weightInGrams(from: "") == nil)
    }
}

// MARK: - Review regressions (#407)

@Suite("Serving description does not invent grams for volumes")
struct VolumeServingDescriptionTests {

    @Test("A volume label gets no gram suffix at any count")
    func volumeNeverGetsGrams() throws {
        // Printing "2 × 25 ml · 50 g" asserts a density the source never gave.
        // The guard originally applied only when count == 1, so the claim came
        // back the moment the stepper moved.
        let option = try #require(ServingOption(label: "25 ml", gramWeight: 25))

        #expect(option.quantityDescription(count: 1) == "25 ml")
        #expect(!option.quantityDescription(count: 2).contains(" g"))
        #expect(option.quantityDescription(count: 2) == "2 × 25 ml")
    }

    @Test("A named portion still states its total weight")
    func namedPortionKeepsWeight() throws {
        let option = try #require(ServingOption(label: "1 medium fast food order", gramWeight: 145))

        #expect(option.quantityDescription(count: 1) == "1 medium fast food order · 145 g")
        #expect(option.quantityDescription(count: 2) == "2 × 1 medium fast food order · 290 g")
    }
}
