import Foundation

// MARK: - Nutrition Info
struct NutritionInfo: Codable, Hashable, Equatable {
    var calories: Int? = nil
    var protein: Double? = nil     // grams
    var carbs: Double? = nil       // grams
    var fat: Double? = nil         // grams
    var fiber: Double? = nil       // grams
    var sugar: Double? = nil       // grams
    var sodium: Double? = nil      // milligrams
}

// MARK: - Food Input Source
enum FoodInputSource: String, Codable {
    case manual
    case barcode
    case lidar
    case ai
}

// MARK: - Food Item
struct FoodItem: Identifiable, Codable, Hashable, Equatable {
    var nutritionDetails: [String: String] = [:]
    var id: String = UUID().uuidString
    var name: String
    var quantity: String                  // e.g., "1 cup", "3 oz"
    var estimatedWeightInGrams: Double?  // Optional for LiDAR or estimation
    var ingredients: [String] = []       // Optional parsed or entered
    var allergens: [String] = []         // e.g., ["dairy", "gluten"]
    var nutrition: NutritionInfo = NutritionInfo()
    var source: FoodInputSource = .manual
    var barcodeValue: String? = nil      // If scanned via barcode
    var isUserEdited: Bool = false       // Indicates manual override
    
    init(
        id: String = UUID().uuidString,
        name: String,
        quantity: String,
        estimatedWeightInGrams: Double? = nil,
        ingredients: [String] = [],
        allergens: [String] = [],
        nutrition: NutritionInfo = NutritionInfo(),
        source: FoodInputSource = .manual,
        barcodeValue: String? = nil,
        isUserEdited: Bool = false,
        nutritionDetails: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.estimatedWeightInGrams = estimatedWeightInGrams
        self.ingredients = ingredients
        self.allergens = allergens
        self.nutrition = nutrition
        self.source = source
        self.barcodeValue = barcodeValue
        self.isUserEdited = isUserEdited
        self.nutritionDetails = nutritionDetails
    }
}
