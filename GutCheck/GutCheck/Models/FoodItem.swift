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
    
    // MARK: - Dictionary Conversion for Firestore
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "quantity": quantity,
            "ingredients": ingredients,
            "allergens": allergens,
            "source": source.rawValue,
            "isUserEdited": isUserEdited,
            "nutritionDetails": nutritionDetails
        ]
        
        if let estimatedWeightInGrams = estimatedWeightInGrams {
            dict["estimatedWeightInGrams"] = estimatedWeightInGrams
        }
        
        if let barcodeValue = barcodeValue {
            dict["barcodeValue"] = barcodeValue
        }
        
        // Convert nutrition to dictionary
        var nutritionDict: [String: Any] = [:]
        if let calories = nutrition.calories { nutritionDict["calories"] = calories }
        if let protein = nutrition.protein { nutritionDict["protein"] = protein }
        if let carbs = nutrition.carbs { nutritionDict["carbs"] = carbs }
        if let fat = nutrition.fat { nutritionDict["fat"] = fat }
        if let fiber = nutrition.fiber { nutritionDict["fiber"] = fiber }
        if let sugar = nutrition.sugar { nutritionDict["sugar"] = sugar }
        if let sodium = nutrition.sodium { nutritionDict["sodium"] = sodium }
        
        if !nutritionDict.isEmpty {
            dict["nutrition"] = nutritionDict
        }
        
        return dict
    }
    
    // MARK: - FirestoreModel Conformance
    
    func toFirestoreData() -> [String: Any] {
        return toDictionary()
    }
    
    static func fromDictionary(_ dict: [String: Any]) throws -> FoodItem {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let quantity = dict["quantity"] as? String else {
            throw NSError(domain: "FoodItemError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
        }
        
        let estimatedWeightInGrams = dict["estimatedWeightInGrams"] as? Double
        let ingredients = dict["ingredients"] as? [String] ?? []
        let allergens = dict["allergens"] as? [String] ?? []
        let barcodeValue = dict["barcodeValue"] as? String
        let isUserEdited = dict["isUserEdited"] as? Bool ?? false
        let nutritionDetails = dict["nutritionDetails"] as? [String: String] ?? [:]
        
        let sourceString = dict["source"] as? String ?? "manual"
        let source = FoodInputSource(rawValue: sourceString) ?? .manual
        
        // Convert nutrition dictionary back to NutritionInfo
        var nutrition = NutritionInfo()
        if let nutritionDict = dict["nutrition"] as? [String: Any] {
            nutrition.calories = nutritionDict["calories"] as? Int
            nutrition.protein = nutritionDict["protein"] as? Double
            nutrition.carbs = nutritionDict["carbs"] as? Double
            nutrition.fat = nutritionDict["fat"] as? Double
            nutrition.fiber = nutritionDict["fiber"] as? Double
            nutrition.sugar = nutritionDict["sugar"] as? Double
            nutrition.sodium = nutritionDict["sodium"] as? Double
        }
        
        return FoodItem(
            id: id,
            name: name,
            quantity: quantity,
            estimatedWeightInGrams: estimatedWeightInGrams,
            ingredients: ingredients,
            allergens: allergens,
            nutrition: nutrition,
            source: source,
            barcodeValue: barcodeValue,
            isUserEdited: isUserEdited,
            nutritionDetails: nutritionDetails
        )
    }
}
