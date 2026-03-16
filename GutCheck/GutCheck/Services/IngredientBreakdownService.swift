//
//  IngredientBreakdownService.swift
//  GutCheck
//
//  AI-powered ingredient breakdown service that analyzes food names
//  to infer ingredients, detect allergens, and generate dietary tags

import Foundation

class IngredientBreakdownService {
    static let shared = IngredientBreakdownService()
    
    private let compoundDatabase = FoodCompoundDatabase.shared
    
    private init() {}
    
    // MARK: - Core Analysis
    
    /// Analyzes a food name to produce a full ingredient breakdown
    /// - Parameters:
    ///   - name: The food name to analyze
    ///   - existingIngredients: Any already-known ingredients to include
    /// - Returns: An IngredientBreakdown with inferred data
    func analyzeFood(name: String, existingIngredients: [String] = []) -> IngredientBreakdown {
        // 1. Get all known/inferred ingredients
        let allIngredients = compoundDatabase.getIngredientsForFood(
            name: name,
            providedIngredients: existingIngredients
        )
        
        // 2. Get compounds for the food
        let compounds = compoundDatabase.getCompoundsForFood(
            name: name,
            ingredients: allIngredients
        )
        
        // 3. Derive allergens from compounds
        let allergens = deriveAllergens(from: compounds, ingredients: allIngredients, name: name)
        
        // 4. Generate dietary tags
        let tags = generateDietaryTags(compounds: compounds, ingredients: allIngredients, name: name)
        
        // 5. Get food description
        let description = compoundDatabase.getFoodDescription(name: name)
        
        // 6. Determine confidence
        let confidence = determineConfidence(
            name: name,
            existingIngredients: existingIngredients,
            inferredIngredients: allIngredients,
            compounds: compounds
        )
        
        return IngredientBreakdown(
            inferredIngredients: allIngredients,
            detectedAllergens: allergens,
            dietaryTags: tags,
            flaggedCompounds: compounds,
            confidence: confidence,
            foodDescription: description
        )
    }
    
    // MARK: - Food Item Enrichment
    
    /// Enriches a FoodItem with inferred ingredients, allergens, and tags
    /// - Parameter item: The food item to enrich
    /// - Returns: A new FoodItem with merged ingredient/allergen data
    func enrichFoodItem(_ item: FoodItem) -> FoodItem {
        let breakdown = analyzeFood(
            name: item.name,
            existingIngredients: item.ingredients
        )
        
        guard breakdown.confidence != .none else {
            return item
        }
        
        var enriched = item
        
        // Merge ingredients: keep existing, add new inferred ones
        if item.ingredients.isEmpty {
            enriched.ingredients = breakdown.inferredIngredients
        } else {
            let existingSet = Set(item.ingredients.map { $0.lowercased() })
            let newIngredients = breakdown.inferredIngredients.filter {
                !existingSet.contains($0.lowercased())
            }
            enriched.ingredients = item.ingredients + newIngredients
        }
        
        // Merge allergens: union of existing + detected, deduplicated
        let existingAllergens = Set(item.allergens.map { $0.lowercased() })
        let newAllergens = breakdown.detectedAllergens.filter {
            !existingAllergens.contains($0.lowercased())
        }
        enriched.allergens = item.allergens + newAllergens
        
        return enriched
    }
    
    // MARK: - Allergen Detection
    
    private func deriveAllergens(from compounds: [FoodCompound], ingredients: [String], name: String) -> [String] {
        var allergens = Set<String>()
        
        for compound in compounds {
            switch compound.name {
            case "Gluten":
                allergens.insert("Gluten")
            case "Casein", "Lactose":
                allergens.insert("Dairy")
            case "Ovalbumin":
                allergens.insert("Eggs")
            case "Shellfish Allergens":
                allergens.insert("Shellfish")
            default:
                break
            }
        }
        
        // Check ingredients for additional allergens
        let ingredientText = (ingredients + [name]).joined(separator: " ").lowercased()
        
        let allergenKeywords: [(String, [String])] = [
            ("Dairy", ["milk", "cheese", "cream", "butter", "whey", "yogurt", "ice cream"]),
            ("Gluten", ["wheat", "flour", "bread", "pasta", "barley", "rye", "oats"]),
            ("Soy", ["soy", "soya", "tofu", "tempeh", "edamame"]),
            ("Eggs", ["egg", "eggs", "albumin", "mayonnaise"]),
            ("Tree Nuts", ["almond", "cashew", "walnut", "pecan", "hazelnut", "pistachio", "macadamia"]),
            ("Peanuts", ["peanut", "peanuts", "groundnut"]),
            ("Fish", ["fish", "salmon", "tuna", "cod", "anchovy", "sardine"]),
            ("Shellfish", ["shrimp", "crab", "lobster", "prawn", "crawfish"]),
            ("Sesame", ["sesame", "tahini"])
        ]
        
        for (allergen, keywords) in allergenKeywords {
            if keywords.contains(where: { ingredientText.contains($0) }) {
                allergens.insert(allergen)
            }
        }
        
        return Array(allergens).sorted()
    }
    
    // MARK: - Dietary Tag Generation
    
    func generateDietaryTags(compounds: [FoodCompound], ingredients: [String], name: String) -> [DietaryTag] {
        var tags = Set<DietaryTag>()
        let ingredientText = (ingredients + [name]).joined(separator: " ").lowercased()
        
        // Compound-based tags
        for compound in compounds {
            switch compound.name {
            case "Gluten":
                tags.insert(.gluten)
            case "Casein", "Lactose":
                tags.insert(.dairy)
            case "Capsaicin":
                tags.insert(.spicy)
            case "Caffeine":
                tags.insert(.caffeine)
            case "Shellfish Allergens":
                tags.insert(.shellfish)
            case "Ovalbumin":
                tags.insert(.eggs)
            case "Solanine", "α-Tomatine", "α-Chaconine":
                tags.insert(.nightshade)
            case "Sodium":
                tags.insert(.highSodium)
            default:
                break
            }
        }
        
        // Ingredient-based tags
        let nutKeywords = ["almond", "cashew", "walnut", "pecan", "hazelnut", "pistachio",
                          "macadamia", "peanut", "pine nut"]
        if nutKeywords.contains(where: { ingredientText.contains($0) }) {
            tags.insert(.nuts)
        }
        
        let soyKeywords = ["soy", "soya", "tofu", "tempeh", "edamame"]
        if soyKeywords.contains(where: { ingredientText.contains($0) }) {
            tags.insert(.soy)
        }
        
        let fermentedKeywords = ["vinegar", "wine", "beer", "sauerkraut", "kimchi",
                                "pickled", "fermented", "kombucha", "kefir"]
        if fermentedKeywords.contains(where: { ingredientText.contains($0) }) {
            tags.insert(.fermented)
        }
        
        let nightshadeKeywords = ["tomato", "potato", "pepper", "eggplant", "paprika",
                                  "chili", "jalapeño", "cayenne"]
        if nightshadeKeywords.contains(where: { ingredientText.contains($0) }) {
            tags.insert(.nightshade)
        }
        
        let spicyKeywords = ["chili", "jalapeño", "habanero", "cayenne", "hot sauce",
                            "sriracha", "wasabi", "horseradish"]
        if spicyKeywords.contains(where: { ingredientText.contains($0) }) {
            tags.insert(.spicy)
        }
        
        let highFatKeywords = ["fried", "deep fried", "fatty", "bacon", "butter",
                              "cream", "lard", "shortening"]
        if highFatKeywords.contains(where: { ingredientText.contains($0) }) {
            tags.insert(.highFat)
        }
        
        let sugarKeywords = ["sugar", "syrup", "honey", "candy", "caramel",
                            "chocolate", "sweetened", "frosting"]
        if sugarKeywords.contains(where: { ingredientText.contains($0) }) {
            tags.insert(.highSugar)
        }
        
        let sodiumKeywords = ["salt", "soy sauce", "miso", "pickle", "cured",
                             "processed meat", "bacon", "ham"]
        if sodiumKeywords.contains(where: { ingredientText.contains($0) }) {
            tags.insert(.highSodium)
        }
        
        let fiberKeywords = ["oats", "beans", "lentils", "chickpeas", "broccoli",
                            "quinoa", "chia", "flax", "bran"]
        if fiberKeywords.contains(where: { ingredientText.contains($0) }) {
            tags.insert(.highFiber)
        }
        
        let eggKeywords = ["egg", "eggs", "omelette", "quiche", "frittata"]
        if eggKeywords.contains(where: { ingredientText.contains($0) }) {
            tags.insert(.eggs)
        }
        
        let dairyKeywords = ["milk", "cheese", "cream", "butter", "yogurt", "ice cream"]
        if dairyKeywords.contains(where: { ingredientText.contains($0) }) {
            tags.insert(.dairy)
        }
        
        let caffeineKeywords = ["coffee", "espresso", "tea", "matcha", "energy drink"]
        if caffeineKeywords.contains(where: { ingredientText.contains($0) }) {
            tags.insert(.caffeine)
        }
        
        return Array(tags).sorted { $0.displayName < $1.displayName }
    }
    
    // MARK: - Confidence Determination
    
    private func determineConfidence(
        name: String,
        existingIngredients: [String],
        inferredIngredients: [String],
        compounds: [FoodCompound]
    ) -> BreakdownConfidence {
        let hasExistingIngredients = !existingIngredients.isEmpty
        let hasCompositeMatch = compoundDatabase.getFoodDescription(name: name) != nil
        let hasInferredIngredients = !inferredIngredients.isEmpty
        let hasCompounds = !compounds.isEmpty
        
        if hasExistingIngredients && hasCompositeMatch {
            return .high
        } else if hasCompositeMatch || (hasExistingIngredients && hasCompounds) {
            return .medium
        } else if hasInferredIngredients || hasCompounds {
            return .low
        } else {
            return .none
        }
    }
}
