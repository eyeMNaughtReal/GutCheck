//
//  IngredientTextParserTests.swift
//  GutCheckTests
//
//  Cases drawn from the real OpenFoodFacts Big Mac record that produced 31
//  "ingredients", several of them unbalanced fragments.
//

import Foundation
import Testing
@testable import GutCheck

@Suite("Ingredient text parsing")
struct IngredientTextParserTests {

    @Test("Commas inside brackets do not split the ingredient")
    func bracketsSurviveSplitting() {
        let parsed = IngredientTextParser.split("Bun, Sauce (water, rapeseed oil, vinegar), Lettuce")

        #expect(parsed == ["Bun", "Sauce (water, rapeseed oil, vinegar)", "Lettuce"])
    }

    @Test("No unbalanced fragments are emitted")
    func noOrphanedBrackets() {
        // The shape that produced "Sauce (Eau", "Épices (Dont Moutarde" and "Edta)".
        let parsed = IngredientTextParser.split("Spices (including mustard), Firming agent (E509, E433, EDTA)")

        #expect(parsed.count == 2)
        for ingredient in parsed {
            let opens = ingredient.filter { $0 == "(" }.count
            let closes = ingredient.filter { $0 == ")" }.count
            #expect(opens == closes)
        }
    }

    @Test("Mustard stays attached to its ingredient rather than being cut in half")
    func compoundContentIsPreserved() {
        let parsed = IngredientTextParser.split("Spices (including mustard), Salt")

        #expect(parsed.first?.lowercased().contains("mustard") == true)
    }

    @Test("Placeholder values are dropped")
    func placeholdersAreRemoved() {
        let parsed = IngredientTextParser.split("undefined, Salt, null, Potatoes, N/A, Oil")

        #expect(parsed == ["Salt", "Potatoes", "Oil"])
    }

    @Test("Percentage annotations are stripped from the name")
    func percentagesAreStripped() {
        let parsed = IngredientTextParser.split("Beef 45%, Cheddar (12%), Onion")

        #expect(parsed == ["Beef", "Cheddar", "Onion"])
    }

    @Test("Semicolons separate at depth zero but not inside brackets")
    func semicolonsBehaveLikeCommas() {
        let parsed = IngredientTextParser.split("Milk; Sugar; Flavouring (vanilla; bourbon)")

        #expect(parsed == ["Milk", "Sugar", "Flavouring (vanilla; bourbon)"])
    }

    @Test("Empty and nil input produce no ingredients")
    func emptyInput() {
        #expect(IngredientTextParser.split(nil).isEmpty)
        #expect(IngredientTextParser.split("").isEmpty)
        #expect(IngredientTextParser.split(" , , ").isEmpty)
    }

    @Test("Punctuation-only fragments are discarded")
    func punctuationFragments() {
        #expect(IngredientTextParser.split("Salt, -, *, Water") == ["Salt", "Water"])
    }

    @Test("The allergen trailer is not treated as ingredients")
    func allergenTrailerIsDropped() {
        // OpenFoodFacts appends the "contains" declaration to the ingredient
        // text. Milk/Eggs/Mustard here are declarations, not ingredients — and
        // allergens_tags already carries them.
        let parsed = IngredientTextParser.split(
            "Bun, Beef, In Unknown Quantities: Sulphur Dioxide, Gluten (Wheat), Milk, Eggs, Mustard"
        )

        #expect(parsed == ["Bun", "Beef"])
    }

    @Test("Other trailer phrasings are handled")
    func otherTrailerPhrasings() {
        #expect(IngredientTextParser.split("Oats, Sugar, Contains: milk") == ["Oats", "Sugar"])
        #expect(IngredientTextParser.split("Oats, Sugar, May contain nuts") == ["Oats", "Sugar"])
        #expect(IngredientTextParser.split("Oats, Sugar, Traces of peanuts") == ["Oats", "Sugar"])
    }

    @Test("An unclosed bracket does not swallow the rest of the list")
    func unbalancedInputDoesNotCollapse() {
        // The real Big Mac text: the sauce's bracket never closes, so a naive
        // depth-tracking parser folds everything after it into one entry.
        let parsed = IngredientTextParser.split("Bread, Sauce (Water, Rapeseed Oil, Gherkins, Onions")

        #expect(parsed.count > 2, "expected the tail to stay separate, got \(parsed)")
        #expect(parsed.contains("Bread"))
        #expect(parsed.contains("Onions"))
        for ingredient in parsed {
            #expect(!ingredient.contains("("), "orphaned bracket in \(ingredient)")
        }
    }

    @Test("A long balanced compound still stays intact")
    func balancedCompoundSurvives() {
        let parsed = IngredientTextParser.split("Bread, Sauce (Water, Rapeseed Oil, Sugar), Onions")

        #expect(parsed == ["Bread", "Sauce (Water, Rapeseed Oil, Sugar)", "Onions"])
    }
}

@Suite("Nutrition detail number parsing")
struct NutritionDetailNumberTests {

    @Test("Period decimals parse as written")
    func periodDecimal() {
        #expect(NutrientValueParser.number(from: "460.5mg") == 460.5)
        #expect(NutrientValueParser.number(from: "15.0g") == 15.0)
    }

    @Test("A comma decimal separator is honoured, not stripped")
    func commaDecimal() {
        // Values persisted by an earlier build in a comma-decimal locale. The
        // parser distinguishes this from thousands grouping; an earlier version
        // stripped the comma outright and read it as 4605.
        #expect(NutrientValueParser.number(from: "460,5mg") == 460.5)
    }

    @Test("Thousands grouping is removed rather than read as a decimal")
    func thousandsGrouping() {
        // Reading this as 1.093 would be a factor-of-1000 error in the other
        // direction from the bug that started all this.
        #expect(NutrientValueParser.number(from: "1,093mg") == 1093)
        #expect(NutrientValueParser.number(from: "1,093,500mg") == 1_093_500)
    }

    @Test("Mixed separators treat the comma as grouping")
    func mixedSeparators() {
        #expect(NutrientValueParser.number(from: "1,093.5mg") == 1093.5)
    }

    @Test("Plain integers and unparseable strings")
    func edgeCases() {
        #expect(NutrientValueParser.number(from: "100mg") == 100)
        #expect(NutrientValueParser.number(from: "mg") == nil)
        #expect(NutrientValueParser.number(from: "") == nil)
    }
}

@Suite("OpenFoodFacts allergen normalisation")
struct OpenFoodFactsAllergenTests {

    private func product(allergens: [String]?, traces: [String]? = nil) -> OpenFoodFactsProduct {
        let json = """
        {
          "code": "test",
          "product_name": "Test",
          "allergens_tags": \(allergens.map { "[\($0.map { "\"\($0)\"" }.joined(separator: ","))]" } ?? "null"),
          "traces_tags": \(traces.map { "[\($0.map { "\"\($0)\"" }.joined(separator: ","))]" } ?? "null")
        }
        """
        return try! JSONDecoder().decode(OpenFoodFactsProduct.self, from: Data(json.utf8))
    }

    @Test("English tags map onto the app's allergen vocabulary")
    func tagsAreMapped() {
        // The real Big Mac record. Milk, eggs and mustard were the ones the
        // keyword matcher missed because the ingredients were in French.
        let big = product(allergens: ["en:gluten", "en:milk", "en:eggs", "en:mustard", "en:sesame-seeds"])

        #expect(big.normalizedAllergens == ["Dairy", "Eggs", "Gluten", "Mustard", "Sesame"])
    }

    @Test("Traces are included alongside declared allergens")
    func tracesAreIncluded() {
        let item = product(allergens: ["en:milk"], traces: ["en:peanuts"])

        #expect(item.normalizedAllergens == ["Dairy", "Peanuts"])
    }

    @Test("Duplicates across allergens and traces collapse")
    func duplicatesCollapse() {
        let item = product(allergens: ["en:milk"], traces: ["en:milk"])

        #expect(item.normalizedAllergens == ["Dairy"])
    }

    @Test("Unmapped and locale-prefixed tags are ignored rather than guessed")
    func unknownTagsAreIgnored() {
        // "fr:lait" is milk, but interpreting arbitrary locale namespaces would
        // be guesswork; keyword detection remains the fallback for these.
        let item = product(allergens: ["fr:lait", "en:milk", "en:something-invented"])

        #expect(item.normalizedAllergens == ["Dairy"])
    }

    @Test("A record with no allergen tags yields an empty list, not a crash")
    func missingTags() {
        #expect(product(allergens: nil).normalizedAllergens.isEmpty)
    }

    @Test("English ingredient text wins over the product's own language")
    func englishIngredientsPreferred() throws {
        let json = """
        {
          "code": "test",
          "product_name": "Big Mac",
          "ingredients_text": "Pain aux graines de sesame, steak haché de boeuf",
          "ingredients_text_en": "Sesame seed bun, beef patty"
        }
        """
        let item = try JSONDecoder().decode(OpenFoodFactsProduct.self, from: Data(json.utf8))

        #expect(item.bestIngredientsText == "Sesame seed bun, beef patty")
    }

    @Test("Trailer markers are matched case-insensitively without shifting the cut")
    func trailerMarkerCasing() {
        // Indexing into a lowercased copy by offset breaks when case folding
        // changes length. These all cut in the same place.
        #expect(IngredientTextParser.split("Oats, Sugar, CONTAINS: milk") == ["Oats", "Sugar"])
        #expect(IngredientTextParser.split("Oats, Sugar, Contains: milk") == ["Oats", "Sugar"])
        #expect(IngredientTextParser.split("İSTANBUL Oats, Sugar, Contains: milk").count == 2)
    }

    @Test("Falls back to the original language when no English text exists")
    func fallsBackToOriginalLanguage() throws {
        let json = """
        {
          "code": "test",
          "product_name": "Big Mac",
          "ingredients_text": "Pain aux graines de sesame"
        }
        """
        let item = try JSONDecoder().decode(OpenFoodFactsProduct.self, from: Data(json.utf8))

        #expect(item.bestIngredientsText == "Pain aux graines de sesame")
    }
}
