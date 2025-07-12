import Foundation

enum MealType: String, Codable, CaseIterable {
    case breakfast, lunch, dinner, snack, drink
}

enum MealSource: String, Codable {
    case manual, barcode, lidar, ai
}

struct Meal: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var date: Date
    var type: MealType
    var source: MealSource
    var foodItems: [FoodItem]
    var notes: String?
    var tags: [String] = []
    var createdBy: String  // Firebase UID
}
