import Foundation

struct NutritionInfo: Codable {
    var calories: Int?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var fiber: Double?
    var sugar: Double?
    var sodium: Double?
}

struct FoodItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var quantity: String  // "1 cup", "3 oz", etc.
    var estimatedWeightInGrams: Double?
    var ingredients: [String] = []
    var allergens: [String] = [] // e.g., ["dairy", "gluten"]
    var nutrition: NutritionInfo
    var isUserEdited: Bool = false
}
