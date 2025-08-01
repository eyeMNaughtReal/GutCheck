import Foundation

// MARK: - Nutritionix API Models
struct NutritionixResponse: Codable {
    let foods: [NutritionixFood]?  // For detailed nutrition queries
    let common: [NutritionixCommonFood]?  // For instant search
    let branded: [NutritionixBrandedFood]?  // For instant search
}

struct NutritionixFood: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String?
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let servingUnit: String?
    let servingQty: Double?
    let servingWeight: Double?
    
    // Additional nutrition data
    let saturatedFat: Double?
    let cholesterol: Double?
    let potassium: Double?
    let vitaminA: Double?
    let vitaminC: Double?
    let calcium: Double?
    let iron: Double?
    
    private enum CodingKeys: String, CodingKey {
        case id = "nix_item_id"
        case name = "food_name"
        case brand = "brand_name"
        case calories = "nf_calories"
        case protein = "nf_protein"
        case carbs = "nf_total_carbohydrate"
        case fat = "nf_total_fat"
        case fiber = "nf_dietary_fiber"
        case sugar = "nf_sugars"
        case sodium = "nf_sodium"
        case servingWeight = "serving_weight_grams"
        case servingUnit = "serving_unit"
        case servingQty = "serving_qty"
        case saturatedFat = "nf_saturated_fat"
        case cholesterol = "nf_cholesterol"
        case potassium = "nf_potassium"
        case vitaminA = "nf_vitamin_a_dv"
        case vitaminC = "nf_vitamin_c_dv"
        case calcium = "nf_calcium_dv"
        case iron = "nf_iron_dv"
    }
    
    init(id: String, name: String, brand: String? = nil, calories: Double? = nil,
         protein: Double? = nil, carbs: Double? = nil, fat: Double? = nil,
         fiber: Double? = nil, sugar: Double? = nil, sodium: Double? = nil,
         servingUnit: String? = nil, servingQty: Double? = nil,
         servingWeight: Double? = nil, saturatedFat: Double? = nil,
         cholesterol: Double? = nil, potassium: Double? = nil,
         vitaminA: Double? = nil, vitaminC: Double? = nil,
         calcium: Double? = nil, iron: Double? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.servingUnit = servingUnit
        self.servingQty = servingQty
        self.servingWeight = servingWeight
        self.saturatedFat = saturatedFat
        self.cholesterol = cholesterol
        self.potassium = potassium
        self.vitaminA = vitaminA
        self.vitaminC = vitaminC
        self.calcium = calcium
        self.iron = iron
    }
}

struct NutritionixCommonFood: Codable, Identifiable {
    let id = UUID().uuidString // Common foods don't have IDs from API
    let name: String
    let servingUnit: String
    let servingQty: Double
    let photo: NutritionixPhoto?
    
    private enum CodingKeys: String, CodingKey {
        case name = "food_name"
        case servingUnit = "serving_unit"
        case servingQty = "serving_qty"
        case photo
    }
    
    func toNutritionixFood() -> NutritionixFood {
        return NutritionixFood(
            id: id,
            name: name,
            servingUnit: servingUnit,
            servingQty: servingQty
        )
    }
}

struct NutritionixBrandedFood: Codable, Identifiable {
    let id: String
    let name: String
    let brand: String
    let servingUnit: String
    let servingQty: Double
    let calories: Double?
    
    private enum CodingKeys: String, CodingKey {
        case id = "nix_item_id"
        case name = "food_name"
        case brand = "brand_name"
        case servingUnit = "serving_unit"
        case servingQty = "serving_qty"
        case calories = "nf_calories"
    }
    
    func toNutritionixFood() -> NutritionixFood {
        return NutritionixFood(
            id: id,
            name: name,
            brand: brand,
            calories: calories,
            servingUnit: servingUnit,
            servingQty: servingQty
        )
    }
}

struct NutritionixPhoto: Codable {
    let thumb: String?
}
