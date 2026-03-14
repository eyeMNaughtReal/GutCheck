import Testing
import Foundation
@testable import GutCheck

struct FoodCompoundDatabaseTests {
    let database = FoodCompoundDatabase.shared

    // MARK: - Compound lookup

    @Test("getAllCompounds returns non-empty collection")
    func getAllCompoundsNotEmpty() {
        let compounds = database.getAllCompounds()
        #expect(!compounds.isEmpty)
    }

    @Test("getAllCategories returns all CompoundCategory cases")
    func getAllCategoriesComplete() {
        let categories = database.getAllCategories()
        #expect(categories.count == CompoundCategory.allCases.count)
    }

    @Test("getCompoundByName finds known compound")
    func getCompoundByNameFindsKnown() {
        let compound = database.getCompoundByName("Caffeine")
        #expect(compound != nil)
        #expect(compound?.name == "Caffeine")
    }

    @Test("getCompoundByName returns nil for unknown compound")
    func getCompoundByNameReturnsNilForUnknown() {
        let compound = database.getCompoundByName("NonexistentCompound123")
        #expect(compound == nil)
    }

    @Test("getCompoundsByCategory returns compounds for known category")
    func getCompoundsByCategoryWorks() {
        let compounds = database.getCompoundsByCategory(.toxicCompound)
        #expect(!compounds.isEmpty)
        for compound in compounds {
            #expect(compound.category == .toxicCompound)
        }
    }

    // MARK: - Food analysis

    @Test("Analyzes tomato and finds expected compounds")
    func analyzesTomato() {
        let compounds = database.getCompoundsForFood(name: "tomato", ingredients: [])
        #expect(!compounds.isEmpty)
        let names = compounds.map(\.name)
        #expect(names.contains("Histamine") || names.contains("Salicylates") || names.contains("Solanine"))
    }

    @Test("Analyzes chocolate and finds caffeine/theobromine")
    func analyzesChocolate() {
        let compounds = database.getCompoundsForFood(name: "chocolate", ingredients: [])
        let names = compounds.map(\.name)
        #expect(names.contains("Theobromine") || names.contains("Caffeine"))
    }

    @Test("Analyzes food with explicit ingredients")
    func analyzesWithExplicitIngredients() {
        let compounds = database.getCompoundsForFood(name: "mystery dish", ingredients: ["milk", "wheat flour"])
        let names = compounds.map(\.name)
        #expect(names.contains("Casein") || names.contains("Lactose"))
        #expect(names.contains("Gluten"))
    }

    @Test("Analyzes composite food: pizza")
    func analyzesCompositePizza() {
        let compounds = database.getCompoundsForFood(name: "pepperoni pizza", ingredients: [])
        #expect(!compounds.isEmpty)
        // Pizza should include wheat/dairy/nightshade compounds
        let names = compounds.map(\.name)
        #expect(names.contains("Gluten"))
    }

    @Test("Returns empty compounds for completely unknown food with no ingredients")
    func unknownFoodNoIngredients() {
        let compounds = database.getCompoundsForFood(name: "xyzunknownfood", ingredients: [])
        // Should return empty since no matches possible
        // (inferIngredientsFromName won't match anything)
        #expect(compounds.isEmpty)
    }

    // MARK: - Ingredient inference

    @Test("getIngredientsForFood includes provided ingredients")
    func includesProvidedIngredients() {
        let ingredients = database.getIngredientsForFood(name: "custom meal", providedIngredients: ["rice", "chicken"])
        #expect(ingredients.contains("rice"))
        #expect(ingredients.contains("chicken"))
    }

    @Test("getIngredientsForFood expands composite foods")
    func expandsCompositeFoods() {
        let ingredients = database.getIngredientsForFood(name: "apple pie", providedIngredients: [])
        #expect(!ingredients.isEmpty)
        #expect(ingredients.contains("apples") || ingredients.contains("flour"))
    }

    @Test("getIngredientsList is consistent with getIngredientsForFood")
    func ingredientsListConsistent() {
        let list = database.getIngredientsList(name: "pizza", providedIngredients: [])
        let direct = database.getIngredientsForFood(name: "pizza", providedIngredients: [])
        #expect(Set(list) == Set(direct))
    }

    // MARK: - Food description

    @Test("getFoodDescription returns description for known composite food")
    func foodDescriptionForKnown() {
        let description = database.getFoodDescription(name: "hamburger")
        #expect(description != nil)
        #expect(!description!.isEmpty)
    }

    @Test("getFoodDescription returns nil for unknown food")
    func foodDescriptionForUnknown() {
        let description = database.getFoodDescription(name: "xyzunknownfood")
        #expect(description == nil)
    }

    // MARK: - Compound sorting

    @Test("Compounds are sorted by severity (high first)")
    func compoundsSortedBySeverity() {
        let compounds = database.getCompoundsForFood(name: "apple pie", ingredients: [])
        guard compounds.count >= 2 else { return }
        
        for i in 0..<(compounds.count - 1) {
            let current = compounds[i].severity.rawValue
            let next = compounds[i + 1].severity.rawValue
            if current != next {
                #expect(current >= next, "Compounds should be sorted by severity descending")
            }
        }
    }

    @Test("Duplicate compounds are removed")
    func duplicatesRemoved() {
        let compounds = database.getCompoundsForFood(name: "chocolate", ingredients: ["cocoa"])
        let names = compounds.map(\.name)
        #expect(names.count == Set(names).count, "Should have no duplicate compound names")
    }

    // MARK: - Processing-related compounds

    @Test("Fried ingredients trigger acrylamide detection")
    func friedIngredientsDetectAcrylamide() {
        let compounds = database.analyzeIngredients(["fried potatoes"])
        let names = compounds.map(\.name)
        #expect(names.contains("Acrylamide"))
    }

    @Test("Oil ingredients trigger trans fat detection")
    func oilIngredientsTriggerTransFat() {
        let compounds = database.analyzeIngredients(["vegetable oil"])
        let names = compounds.map(\.name)
        #expect(names.contains("Trans Fats"))
    }

    // MARK: - HealthSeverity enum

    @Test("HealthSeverity raw values are ordered")
    func healthSeverityOrdered() {
        #expect(HealthSeverity.low.rawValue < HealthSeverity.medium.rawValue)
        #expect(HealthSeverity.medium.rawValue < HealthSeverity.high.rawValue)
    }

    @Test("CompoundCategory allCases is non-empty")
    func compoundCategoryAllCases() {
        #expect(!CompoundCategory.allCases.isEmpty)
    }
}
