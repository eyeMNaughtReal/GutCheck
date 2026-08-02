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
    /// English ingredient text where the contributor supplied one. The plain
    /// `ingredients_text` field is in the product's own language, which for a
    /// French-registered Big Mac means a French list.
    let ingredientsTextEn: String?
    let servingSize: String?
    let allergens: String?
    let traces: String?
    /// Structured allergen identifiers, e.g. `["en:gluten", "en:milk"]`.
    ///
    /// Prefer these over the free-text `allergens` field: they carry an `en:`
    /// prefix regardless of the product's language, so a French record still
    /// reports `en:milk` rather than `Lait`.
    let allergensTags: [String]?
    let tracesTags: [String]?

    private enum CodingKeys: String, CodingKey {
        case id = "code"
        case productName = "product_name"
        case brands
        case nutriments
        case ingredients
        case ingredientsText = "ingredients_text"
        case ingredientsTextEn = "ingredients_text_en"
        case servingSize = "serving_size"
        case allergens
        case traces
        case allergensTags = "allergens_tags"
        case tracesTags = "traces_tags"
    }

    /// Ingredient text in English when available, falling back to whatever
    /// language the record is written in.
    var bestIngredientsText: String? {
        if let english = ingredientsTextEn, !english.trimmingCharacters(in: .whitespaces).isEmpty {
            return english
        }
        return ingredientsText
    }

    /// Allergens and traces normalised to the app's vocabulary.
    ///
    /// OpenFoodFacts tags look like `en:milk` or, on records a contributor
    /// entered in another language, `fr:lait`. Only the `en:` namespace is
    /// mapped — a locale-prefixed tag is data we cannot reliably interpret, and
    /// guessing would be worse than falling through to keyword detection.
    var normalizedAllergens: [String] {
        let tags = (allergensTags ?? []) + (tracesTags ?? [])
        let mapped = tags.compactMap { Self.allergenNames[$0.lowercased()] }
        return Array(Set(mapped)).sorted()
    }

    /// Maps OpenFoodFacts allergen tags onto the labels the app already uses
    /// elsewhere, so tag-derived and keyword-derived allergens read the same.
    private static let allergenNames: [String: String] = [
        "en:milk": "Dairy",
        "en:gluten": "Gluten",
        "en:soybeans": "Soy",
        "en:eggs": "Eggs",
        "en:nuts": "Tree Nuts",
        "en:tree-nuts": "Tree Nuts",
        "en:almonds": "Tree Nuts",
        "en:hazelnuts": "Tree Nuts",
        "en:walnuts": "Tree Nuts",
        "en:cashew-nuts": "Tree Nuts",
        "en:pistachio-nuts": "Tree Nuts",
        "en:macadamia-nuts": "Tree Nuts",
        "en:pecan-nuts": "Tree Nuts",
        "en:brazil-nuts": "Tree Nuts",
        "en:peanuts": "Peanuts",
        "en:fish": "Fish",
        "en:crustaceans": "Shellfish",
        "en:molluscs": "Shellfish",
        "en:sesame-seeds": "Sesame",
        "en:mustard": "Mustard",
        "en:celery": "Celery",
        "en:lupin": "Lupin",
        "en:sulphur-dioxide-and-sulphites": "Sulphites"
    ]
}

struct OpenFoodFactsNutriments: Codable {
    // Energy and macronutrients (per 100g)
    let energyKcal100g: Double?
    let fat100g: Double?
    let saturatedFat100g: Double?
    let transFat100g: Double?
    let carbohydrates100g: Double?
    let sugars100g: Double?
    let fiber100g: Double?
    let proteins100g: Double?
    let salt100g: Double?
    let sodium100g: Double?
    let cholesterol100g: Double?
    
    // Minerals (per 100g)
    let calcium100g: Double?
    let iron100g: Double?
    let magnesium100g: Double?
    let phosphorus100g: Double?
    let potassium100g: Double?
    let zinc100g: Double?
    let copper100g: Double?
    let manganese100g: Double?
    let selenium100g: Double?
    
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
    let biotin100g: Double?
    let pantothenicAcid100g: Double?
    
    private enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case fat100g = "fat_100g"
        case saturatedFat100g = "saturated-fat_100g"
        case transFat100g = "trans-fat_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case sugars100g = "sugars_100g"
        case fiber100g = "fiber_100g"
        case proteins100g = "proteins_100g"
        case salt100g = "salt_100g"
        case sodium100g = "sodium_100g"
        case cholesterol100g = "cholesterol_100g"
        case calcium100g = "calcium_100g"
        case iron100g = "iron_100g"
        case magnesium100g = "magnesium_100g"
        case phosphorus100g = "phosphorus_100g"
        case potassium100g = "potassium_100g"
        case zinc100g = "zinc_100g"
        case copper100g = "copper_100g"
        case manganese100g = "manganese_100g"
        case selenium100g = "selenium_100g"
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
        case biotin100g = "biotin_100g"
        case pantothenicAcid100g = "pantothenic-acid_100g"
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