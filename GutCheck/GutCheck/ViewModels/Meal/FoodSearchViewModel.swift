//
//  Enhanced FoodSearchViewModel.swift
//  GutCheck
//
//  Updated to properly populate comprehensive nutrition data

import Foundation
import Combine

@MainActor
@Observable class FoodSearchViewModel {
    // Search state
    var searchQuery: String = ""
    var isSearching: Bool = false
    var hasSearched: Bool = false
    var searchResults: [FoodItem] = []
    var selectedFoodItem: FoodItem?
    var recentSearches: [String] = ["Oatmeal", "Chicken breast", "Greek yogurt"]
    var recentItems: [FoodItem] = []
    
    let foodCategories = [
        "Fruits", "Vegetables", "Meat", "Dairy",
        "Grains", "Beverages", "Snacks", "Fast Food"
    ]
    
    private var cancellables = Set<AnyCancellable>()
    private let foodSearchService = FoodSearchService()

    init() {
        // Load sample data if empty
        if recentSearches.isEmpty {
            recentSearches = ["Oatmeal", "Chicken breast", "Greek yogurt"]
        }
        if recentItems.isEmpty {
            loadSampleRecentItems()
        }
        loadRecentItems()
        
        // Removed automatic debounced search - now only searches on button press
    }

    func search() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            hasSearched = false
            isSearching = false
            return
        }
        
        isSearching = true
        hasSearched = true
        
        Task {
            await foodSearchService.searchFoods(query: searchQuery)
            
            let foods = foodSearchService.results.map { nfood in
                return createEnhancedFoodItem(from: nfood)
            }
            
            self.searchResults = foods
            self.isSearching = false
            
            // Add to recent searches
            if !self.recentSearches.contains(self.searchQuery) {
                self.recentSearches.insert(self.searchQuery, at: 0)
                if self.recentSearches.count > 5 {
                    self.recentSearches.removeLast()
                }
            }
        }
    }
    
    private func createEnhancedFoodItem(from nfood: FoodSearchResult) -> FoodItem {
        // Extract serving information
        let servingQty = nfood.servingQty ?? 1.0
        let servingUnit = nfood.servingUnit ?? "serving"
        let servingWeightGrams = nfood.servingWeight
        
        // Create quantity string
        let quantityString = "\(servingQty.formatted(.number)) \(servingUnit)"
        
        // Parse ingredients from Nutritionix ingredients string  
        let ingredientList: [String] = parseIngredients(from: nfood.ingredients)
        
        // Build comprehensive nutrition dictionary from enhanced data
        var nutritionDict: [String: String] = [:]
        
        // Add brand information
        if let brand = nfood.brand {
            nutritionDict["brand"] = brand
        }
        
        // Add basic nutrition values
        if let calories = nfood.calories {
            nutritionDict["calories"] = calories.formatted(.number.precision(.fractionLength(1)))
        }
        if let protein = nfood.protein {
            nutritionDict["protein"] = protein.formatted(.number.precision(.fractionLength(1)))
        }
        if let carbs = nfood.carbs {
            nutritionDict["total_carbohydrate"] = carbs.formatted(.number.precision(.fractionLength(1)))
        }
        if let fat = nfood.fat {
            nutritionDict["total_fat"] = fat.formatted(.number.precision(.fractionLength(1)))
        }
        if let fiber = nfood.fiber {
            nutritionDict["dietary_fiber"] = fiber.formatted(.number.precision(.fractionLength(1)))
        }
        if let sugar = nfood.sugar {
            nutritionDict["sugars"] = sugar.formatted(.number.precision(.fractionLength(1)))
        }
        if let sodium = nfood.sodium {
            nutritionDict["sodium"] = sodium.formatted(.number.precision(.fractionLength(1)))
        }
        
        // Add detailed nutrition from the specific properties
        if let saturatedFat = nfood.saturatedFat {
            nutritionDict["saturated_fat"] = saturatedFat.formatted(.number.precision(.fractionLength(1)))
        }
        if let cholesterol = nfood.cholesterol {
            nutritionDict["cholesterol"] = cholesterol.formatted(.number.precision(.fractionLength(1)))
        }
        if let potassium = nfood.potassium {
            nutritionDict["potassium"] = potassium.formatted(.number.precision(.fractionLength(1)))
        }
        if let vitaminA = nfood.vitaminA {
            nutritionDict["vitamin_a_dv"] = vitaminA.formatted(.number.precision(.fractionLength(0)))
        }
        if let vitaminC = nfood.vitaminC {
            nutritionDict["vitamin_c_dv"] = vitaminC.formatted(.number.precision(.fractionLength(0)))
        }
        if let calcium = nfood.calcium {
            nutritionDict["calcium_dv"] = calcium.formatted(.number.precision(.fractionLength(0)))
        }
        if let iron = nfood.iron {
            nutritionDict["iron_dv"] = iron.formatted(.number.precision(.fractionLength(0)))
        }
        
        // Extract allergens with enhanced detection
        let allergens = detectAllergens(from: nfood.name, brand: nfood.brand, ingredients: ingredientList)
        
        // Create main nutrition info for easy access
        let nutrition = NutritionInfo(
            calories: nfood.calories.map { Int($0) },
            protein: nfood.protein,
            carbs: nfood.carbs,
            fat: nfood.fat,
            fiber: nfood.fiber,
            sugar: nfood.sugar,
            sodium: nfood.sodium
        )
        
        return FoodItem(
            id: nfood.id,
            name: nfood.name,
            quantity: quantityString,
            estimatedWeightInGrams: servingWeightGrams,
            ingredients: ingredientList,
            allergens: allergens,
            nutrition: nutrition,
            source: .manual,
            isUserEdited: false,
            nutritionDetails: nutritionDict
        )
    }
    
    private func detectAllergens(from foodName: String, brand: String?, ingredients: [String]) -> [String] {
        var allergens: [String] = []
        
        let allergenKeywords: [(String, [String])] = [
            ("Dairy", ["milk", "cheese", "cream", "butter", "whey", "casein", "lactose", "yogurt"]),
            ("Gluten", ["wheat", "barley", "rye", "malt", "bread", "flour", "gluten", "oats"]),
            ("Soy", ["soy", "soya", "soybean", "tofu", "tempeh", "lecithin"]),
            ("Eggs", ["egg", "albumin", "mayonnaise", "meringue"]),
            ("Tree Nuts", ["almond", "cashew", "walnut", "pecan", "hazelnut", "pistachio", "macadamia", "brazil nut"]),
            ("Peanuts", ["peanut", "groundnut", "arachis"]),
            ("Fish", ["fish", "salmon", "tuna", "cod", "anchovy", "sardine", "herring"]),
            ("Shellfish", ["shrimp", "crab", "lobster", "shellfish", "prawn", "crawfish", "mollusc"]),
            ("Sesame", ["sesame", "tahini", "benne"])
        ]
        
        // Combine all text sources for searching
        let searchTexts = [foodName, brand ?? "", ingredients.joined(separator: " ")].joined(separator: " ").lowercased()
        
        for (allergen, keywords) in allergenKeywords {
            if keywords.contains(where: { searchTexts.contains($0) }) {
                allergens.append(allergen)
            }
        }
        
        return allergens
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        hasSearched = false
    }

    func selectFoodItem(_ item: FoodItem) {
        selectedFoodItem = item
    }
    
    func enhanceFoodItemWithIngredients(_ foodItem: FoodItem) async -> FoodItem {
        return await foodSearchService.enhanceFoodItemWithIngredients(foodItem)
    }


    func createCustomFoodItem() {
        let customItem = FoodItem(
            name: searchQuery.isEmpty ? "New Food Item" : searchQuery,
            quantity: "1 serving",
            nutrition: NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0)
        )
        selectedFoodItem = customItem
    }

    func addToMeal(_ foodItem: FoodItem) {
        // Add to recent items
        if !recentItems.contains(where: { $0.id == foodItem.id }) {
            recentItems.insert(foodItem, at: 0)
            if recentItems.count > 10 {
                recentItems.removeLast()
            }
            saveRecentItems()
        }
        
        // Add to unified meal builder service
        MealBuilderService.shared.addFoodItem(foodItem)
    }

    // MARK: - Ingredient Parsing
    
    private func parseIngredients(from ingredientsString: String?) -> [String] {
        guard let ingredientsString = ingredientsString, !ingredientsString.isEmpty else {
            return []
        }
        
        // Clean up the ingredients string and split by common separators
        let cleanedString = ingredientsString
            .replacingOccurrences(of: ".", with: "") // Remove periods
            .replacingOccurrences(of: ";", with: ",") // Normalize separators
            .replacingOccurrences(of: " and ", with: ", ") // Handle "and" separators
            .replacingOccurrences(of: " & ", with: ", ") // Handle "&" separators
        
        // Split by commas and clean up each ingredient
        let ingredients = cleanedString
            .components(separatedBy: ",")
            .map { ingredient in
                ingredient
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }
            .filter { !$0.isEmpty }
        
        return ingredients
    }
    
    // MARK: - Recent Items Management
    
    func loadRecentItems() {
        // In a real app, load from UserDefaults or Core Data
        // For now, use sample data
        loadSampleRecentItems()
    }
    
    private func loadSampleRecentItems() {
        recentItems = [
            FoodItem(
                name: "Steel Cut Oatmeal",
                quantity: "1 cup cooked",
                estimatedWeightInGrams: 240.0,
                ingredients: ["steel cut oats", "water"],
                allergens: ["Gluten"],
                nutrition: NutritionInfo(
                    calories: 158,
                    protein: 6.0,
                    carbs: 27.0,
                    fat: 3.0,
                    fiber: 4.0,
                    sugar: 1.0,
                    sodium: 9.0
                ),
                nutritionDetails: [
                    "calories": "158",
                    "protein": "6.0",
                    "total_carbohydrate": "27.0",
                    "total_fat": "3.0",
                    "dietary_fiber": "4.0",
                    "sugars": "1.0",
                    "sodium": "9.0",
                    "iron_dv": "10",
                    "magnesium_mg": "63"
                ]
            ),
            FoodItem(
                name: "Organic Free-Range Chicken Breast",
                quantity: "6 oz",
                estimatedWeightInGrams: 170.0,
                ingredients: ["chicken breast"],
                allergens: [],
                nutrition: NutritionInfo(
                    calories: 280,
                    protein: 54.0,
                    carbs: 0.0,
                    fat: 6.0,
                    fiber: 0.0,
                    sugar: 0.0,
                    sodium: 126.0
                ),
                nutritionDetails: [
                    "calories": "280",
                    "protein": "54.0",
                    "total_carbohydrate": "0.0",
                    "total_fat": "6.0",
                    "sodium": "126.0",
                    "vitamin_b6_mg": "1.6",
                    "niacin_mg": "22.6",
                    "phosphorus_mg": "259"
                ]
            ),
            FoodItem(
                name: "Plain Greek Yogurt",
                quantity: "1 cup",
                estimatedWeightInGrams: 245.0,
                ingredients: ["cultured pasteurized nonfat milk", "live active cultures"],
                allergens: ["Dairy"],
                nutrition: NutritionInfo(
                    calories: 150,
                    protein: 20.0,
                    carbs: 9.0,
                    fat: 4.0,
                    fiber: 0.0,
                    sugar: 9.0,
                    sodium: 65.0
                ),
                nutritionDetails: [
                    "calories": "150",
                    "protein": "20.0",
                    "total_carbohydrate": "9.0",
                    "total_fat": "4.0",
                    "sugars": "9.0",
                    "sodium": "65.0",
                    "calcium_dv": "25",
                    "vitamin_b12_mcg": "1.4"
                ]
            )
        ]
    }

    private func saveRecentItems() {
        // In a real app, save to UserDefaults or Core Data
    }
}
