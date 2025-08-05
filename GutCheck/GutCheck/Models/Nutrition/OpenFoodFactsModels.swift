import Foundation

// MARK: - OpenFoodFacts API Models

struct OpenFoodFactsResponse: Codable {
    let products: [OpenFoodFactsProduct]?
    let count: Int?
    
    private enum CodingKeys: String, CodingKey {
        case products, count
    }
}

struct OpenFoodFactsProduct: Codable, Identifiable {
    let id: String
    let productName: String?
    let brands: String?
    let nutriments: OpenFoodFactsNutriments?
    let ingredients: [OpenFoodFactsIngredient]?
    let ingredientsText: String?
    let servingSize: String?
    let allergens: String?
    let traces: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "code"
        case productName = "product_name"
        case brands
        case nutriments
        case ingredients
        case ingredientsText = "ingredients_text"
        case servingSize = "serving_size"
        case allergens
        case traces
    }
}

struct OpenFoodFactsNutriments: Codable {
    // Energy and macronutrients (per 100g)
    let energyKcal100g: Double?
    let fat100g: Double?
    let saturatedFat100g: Double?
    let carbohydrates100g: Double?
    let sugars100g: Double?
    let fiber100g: Double?
    let proteins100g: Double?
    let salt100g: Double?
    let sodium100g: Double?
    
    // Minerals (per 100g)
    let calcium100g: Double?
    let iron100g: Double?
    let magnesium100g: Double?
    let phosphorus100g: Double?
    let potassium100g: Double?
    let zinc100g: Double?
    
    // Vitamins (per 100g)
    let vitaminA100g: Double?
    let vitaminC100g: Double?
    let vitaminD100g: Double?
    let vitaminE100g: Double?
    let vitaminK100g: Double?
    let vitaminB1100g: Double? // Thiamin
    let vitaminB2100g: Double? // Riboflavin
    let vitaminB3100g: Double? // Niacin
    let vitaminB6100g: Double?
    let vitaminB12100g: Double?
    let folates100g: Double?
    
    private enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case fat100g = "fat_100g"
        case saturatedFat100g = "saturated-fat_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case sugars100g = "sugars_100g"
        case fiber100g = "fiber_100g"
        case proteins100g = "proteins_100g"
        case salt100g = "salt_100g"
        case sodium100g = "sodium_100g"
        case calcium100g = "calcium_100g"
        case iron100g = "iron_100g"
        case magnesium100g = "magnesium_100g"
        case phosphorus100g = "phosphorus_100g"
        case potassium100g = "potassium_100g"
        case zinc100g = "zinc_100g"
        case vitaminA100g = "vitamin-a_100g"
        case vitaminC100g = "vitamin-c_100g"
        case vitaminD100g = "vitamin-d_100g"
        case vitaminE100g = "vitamin-e_100g"
        case vitaminK100g = "vitamin-k_100g"
        case vitaminB1100g = "vitamin-b1_100g"
        case vitaminB2100g = "vitamin-b2_100g"
        case vitaminB3100g = "vitamin-b3_100g"
        case vitaminB6100g = "vitamin-b6_100g"
        case vitaminB12100g = "vitamin-b12_100g"
        case folates100g = "folates_100g"
    }
}

struct OpenFoodFactsIngredient: Codable {
    let id: String?
    let text: String
    let rank: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id, text, rank
    }
}

// MARK: - Search Response

struct OpenFoodFactsSearchResponse: Codable {
    let products: [OpenFoodFactsProduct]
    let count: Int
    let page: Int
    let pageCount: Int
    let pageSize: Int
    
    private enum CodingKeys: String, CodingKey {
        case products, count, page
        case pageCount = "page_count"
        case pageSize = "page_size"
    }
}