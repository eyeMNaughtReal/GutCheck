//
//  NutrientUnitConversionTests.swift
//  GutCheckTests
//
//  Pins the gram → milligram boundary between FoodSearchResult and
//  NutritionInfo. Sodium read 0 mg for a Big Mac because that conversion was
//  missing; these tests exist so a refactor cannot quietly restore it.
//
//  Note: CI builds but does not run tests. These are here for when it does,
//  and for running locally with ⌘U.
//

import Testing
@testable import GutCheck

@Suite("Nutrient unit conversion")
struct NutrientUnitConversionTests {

    /// Scaling by 1000 is not exact in binary floating point — 0.4605 * 1000 is
    /// 460.49999999999994 — so these comparisons carry a tolerance. It is
    /// deliberately tight: the bug being guarded against is a factor of 1000,
    /// which no rounding slack could hide.
    private func expectClose(
        _ actual: Double?,
        _ expected: Double,
        tolerance: Double = 0.000_001,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        guard let actual else {
            Issue.record("expected \(expected), got nil", sourceLocation: sourceLocation)
            return
        }
        #expect(abs(actual - expected) < tolerance, sourceLocation: sourceLocation)
    }

    /// Per-100 g values for a Big Mac, in the grams convention that both search
    /// sources normalise to.
    private func bigMac() -> FoodSearchResult {
        FoodSearchResult(
            id: "test-big-mac",
            name: "Big Mac",
            brand: "McDonald's",
            calories: 257,
            protein: 11.8,
            carbs: 20.1,
            fat: 15.0,
            fiber: 1.4,
            sugar: 4.1,
            sodium: 0.4605,          // 460.5 mg
            saturatedFat: 5.0,
            transFat: 0.25,
            cholesterol: 0.0388,     // 38.8 mg
            potassium: 0.1553,       // 155.3 mg
            calcium: 0.1096,         // 109.6 mg
            iron: 0.0023,            // 2.3 mg
            magnesium: 0.02,         // 20 mg
            vitaminA: 0.000_058,     // 58 mcg
            vitaminC: 0.0009,        // 0.9 mg
            vitaminD: 0.000_000_2,   // 0.2 mcg
            vitaminE: 0.0012,        // 1.2 mg
            vitaminK: 0.00002,       // 20 mcg
            thiamin: 0.00012,        // 0.12 mg
            niacin: 0.0018,          // 1.8 mg
            vitaminB12: 0.0000002,   // 0.2 mcg
            biotin: 0.00000003,      // 0.03 mcg
            pantothenicAcid: 0.0005, // 0.5 mg
            selenium: 0.000004       // 4 mcg
        )
    }

    // MARK: - Accessors

    @Test("Minerals convert grams to milligrams")
    func mineralsConvertToMilligrams() {
        let food = bigMac()

        expectClose(food.sodiumMilligrams, 460.5)
        expectClose(food.cholesterolMilligrams, 38.8)
        expectClose(food.potassiumMilligrams, 155.3)
        expectClose(food.calciumMilligrams, 109.6)
        expectClose(food.ironMilligrams, 2.3)
        expectClose(food.vitaminCMilligrams, 0.9)
    }

    @Test("Vitamins A and D convert grams to micrograms")
    func vitaminsConvertToMicrograms() {
        let food = bigMac()

        expectClose(food.vitaminAMicrograms, 58)
        expectClose(food.vitaminDMicrograms, 0.2)
    }

    @Test("nil stays nil rather than becoming zero")
    func nilIsPreserved() {
        let empty = FoodSearchResult(id: "empty", name: "Empty", brand: nil)

        #expect(empty.sodiumMilligrams == nil)
        #expect(empty.potassiumMilligrams == nil)
        #expect(empty.vitaminAMicrograms == nil)
    }

    // MARK: - The boundary that actually broke

    @Test("toFoodItem puts milligrams into the milligram-documented field")
    func foodItemSodiumIsMilligrams() {
        let item = bigMac().toFoodItem()

        // The bug: 0.4605 g arrived here unconverted and rendered as "0 mg".
        expectClose(item.nutrition.sodium, 460.5)
    }

    @Test("Macronutrients stay in grams and are not scaled")
    func macrosAreUntouched() {
        let item = bigMac().toFoodItem()

        #expect(item.nutrition.protein == 11.8)
        #expect(item.nutrition.carbs == 20.1)
        #expect(item.nutrition.fat == 15.0)
        #expect(item.nutrition.fiber == 1.4)
        #expect(item.nutrition.sugar == 4.1)
        #expect(item.nutrition.calories == 257)
    }

    @Test("nutritionDetails numbers agree with their unit suffix")
    func detailStringsMatchTheirSuffix() {
        let details = bigMac().toFoodItem().nutritionDetails

        #expect(details["Cholesterol"] == "38.8mg")
        #expect(details["Potassium"] == "155.3mg")
        #expect(details["Calcium"] == "109.6mg")
        #expect(details["Iron"] == "2.3mg")
        #expect(details["Vitamin C"] == "0.9mg")
        #expect(details["Vitamin A"] == "58mcg")
        #expect(details["Protein"] == "11.8g")
        #expect(details["Total Carbohydrate"] == "20.1g")
        #expect(details["Total Fat"] == "15g")
        #expect(details["Dietary Fiber"] == "1.4g")
        #expect(details["Total Sugars"] == "4.1g")
        #expect(details["Sodium"] == "460.5mg")
        #expect(details["Trans Fat"] == "0.25g")
        #expect(details["Magnesium"] == "20mg")
        #expect(details["Vitamin E"] == "1.2mg")
        #expect(details["Vitamin K"] == "20mcg")
        #expect(details["Thiamin"] == "0.12mg")
        #expect(details["Vitamin B12"] == "0.2mcg")
        #expect(details["Biotin"] == "0.03mcg")
        #expect(details["Pantothenic Acid"] == "0.5mg")
        #expect(details["Selenium"] == "4mcg")

        // Grams are not converted.
        #expect(details["Saturated Fat"] == "5g")
    }

    // MARK: - Locale

    @Test("Stored numbers use a period regardless of device locale")
    func storedNumbersUsePeriodSeparator() {
        // A comma decimal separator would survive into nutritionDetails and be
        // stripped by the parser, turning 460.5 into 4605.
        let formatted = FoodSearchResult.amount(460.5)

        #expect(formatted == "460.5")
        #expect(!formatted.contains(","))
        #expect(FoodSearchResult.amount(0.03) == "0.03")
    }

    @Test("Large values carry no grouping separator")
    func largeValuesHaveNoGrouping() {
        // "1,093" would be read back as 1093 only by luck; "1093" is unambiguous.
        #expect(FoodSearchResult.amount(1093) == "1093")
    }

    @Test("Float noise is trimmed")
    func floatNoiseIsTrimmed() {
        // 0.4605 * 1000 is 460.49999999999994 in binary floating point.
        #expect(FoodSearchResult.amount(0.4605 * 1_000) == "460.5")
    }
}
