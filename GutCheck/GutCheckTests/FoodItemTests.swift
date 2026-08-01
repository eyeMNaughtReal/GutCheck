import Testing
import Foundation
@testable import GutCheck

struct FoodItemTests {

    // MARK: - Initialization

    @Test("Default initializer sets expected defaults")
    func defaultInit() {
        let item = FoodItem(name: "Apple", quantity: "1 medium")
        #expect(item.name == "Apple")
        #expect(item.quantity == "1 medium")
        #expect(item.source == .manual)
        #expect(item.ingredients.isEmpty)
        #expect(item.allergens.isEmpty)
        #expect(!item.isUserEdited)
        #expect(item.barcodeValue == nil)
        #expect(item.estimatedWeightInGrams == nil)
    }

    @Test("Full initializer preserves all values")
    func fullInit() {
        let nutrition = NutritionInfo(calories: 250, protein: 10.0, carbs: 30.0, fat: 8.0)
        let item = FoodItem(
            name: "Chicken Breast",
            quantity: "6 oz",
            estimatedWeightInGrams: 170.0,
            ingredients: ["chicken"],
            allergens: [],
            nutrition: nutrition,
            source: .ai,
            barcodeValue: "12345",
            isUserEdited: true,
            nutritionDetails: ["vitamin_a": "10%"]
        )
        #expect(item.name == "Chicken Breast")
        #expect(item.estimatedWeightInGrams == 170.0)
        #expect(item.source == .ai)
        #expect(item.barcodeValue == "12345")
        #expect(item.isUserEdited)
        #expect(item.nutritionDetails["vitamin_a"] == "10%")
    }

    // MARK: - Codable round-trip
    //
    // Food items are persisted as a JSON blob on StoredMeal, so this is the
    // path the storage layer actually uses. It replaced a dictionary
    // round-trip that existed only to talk to Firestore.

    @Test("Codable round-trip preserves data")
    func codableRoundTrip() throws {
        let nutrition = NutritionInfo(calories: 200, protein: 15.0, carbs: 25.0, fat: 5.0, fiber: 3.0, sugar: 2.0, sodium: 100.0)
        let original = FoodItem(
            id: "test-id",
            name: "Rice Bowl",
            quantity: "1 cup",
            estimatedWeightInGrams: 240.0,
            ingredients: ["rice", "vegetables"],
            allergens: ["soy"],
            nutrition: nutrition,
            source: .barcode,
            barcodeValue: "98765",
            isUserEdited: true,
            nutritionDetails: ["iron": "8%"]
        )

        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(FoodItem.self, from: data)

        #expect(restored.id == "test-id")
        #expect(restored.name == "Rice Bowl")
        #expect(restored.quantity == "1 cup")
        #expect(restored.estimatedWeightInGrams == 240.0)
        #expect(restored.ingredients == ["rice", "vegetables"])
        #expect(restored.allergens == ["soy"])
        #expect(restored.source == .barcode)
        #expect(restored.barcodeValue == "98765")
        #expect(restored.isUserEdited)
        #expect(restored.nutritionDetails["iron"] == "8%")
        #expect(restored.nutrition.calories == 200)
        #expect(restored.nutrition.protein == 15.0)
        #expect(restored.nutrition.carbs == 25.0)
        #expect(restored.nutrition.fat == 5.0)
        #expect(restored.nutrition.fiber == 3.0)
        #expect(restored.nutrition.sugar == 2.0)
        #expect(restored.nutrition.sodium == 100.0)
    }

    @Test("Decoding fails when a required field is missing")
    func decodingThrowsForMissingFields() {
        // No "quantity", which has no default on the decoding side.
        let json = Data(#"{"id":"test-id","name":"Apple"}"#.utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(FoodItem.self, from: json)
        }
    }

    @Test("A round-tripped item keeps its empty optionals empty")
    func roundTripPreservesEmptyOptionals() throws {
        let original = FoodItem(id: "test-id", name: "Banana", quantity: "1 medium")

        let data = try JSONEncoder().encode(original)
        let item = try JSONDecoder().decode(FoodItem.self, from: data)

        #expect(item.name == "Banana")
        #expect(item.ingredients.isEmpty)
        #expect(item.allergens.isEmpty)
        #expect(item.barcodeValue == nil)
        #expect(!item.isUserEdited)
        #expect(item.source == .manual)
    }

    // MARK: - Codable round-trip

    @Test("FoodItem Codable round-trip preserves data")
    func foodItemCodableRoundTrip() throws {
        let nutrition = NutritionInfo(calories: 150, protein: 5.0)
        let original = FoodItem(
            name: "Granola Bar",
            quantity: "1 bar",
            nutrition: nutrition,
            source: .barcode
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FoodItem.self, from: data)

        #expect(decoded.name == original.name)
        #expect(decoded.quantity == original.quantity)
        #expect(decoded.nutrition.calories == 150)
        #expect(decoded.nutrition.protein == 5.0)
        #expect(decoded.source == .barcode)
    }

    // MARK: - NutritionInfo

    @Test("NutritionInfo default init has all nil values")
    func nutritionInfoDefaults() {
        let info = NutritionInfo()
        #expect(info.calories == nil)
        #expect(info.protein == nil)
        #expect(info.carbs == nil)
        #expect(info.fat == nil)
        #expect(info.fiber == nil)
        #expect(info.sugar == nil)
        #expect(info.sodium == nil)
    }

    // MARK: - FoodInputSource enum

    @Test("FoodInputSource raw values are correct")
    func foodInputSourceRawValues() {
        #expect(FoodInputSource.manual.rawValue == "manual")
        #expect(FoodInputSource.barcode.rawValue == "barcode")
        #expect(FoodInputSource.lidar.rawValue == "lidar")
        #expect(FoodInputSource.ai.rawValue == "ai")
    }
}
