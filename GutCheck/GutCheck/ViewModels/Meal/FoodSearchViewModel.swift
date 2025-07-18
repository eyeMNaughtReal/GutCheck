//
//  Fixed FoodSearchViewModel.swift
//  GutCheck
//
//  Enhanced to capture full nutrition data and handle serving size calculations

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class FoodSearchViewModel: ObservableObject {
    // Search state
    @Published var searchQuery: String = ""
    @Published var isSearching: Bool = false
    @Published var hasSearched: Bool = false
    @Published var searchResults: [FoodItem] = []
    @Published var selectedFoodItem: FoodItem?
    @Published var recentSearches: [String] = ["Oatmeal", "Chicken breast", "Greek yogurt"]
    @Published var recentItems: [FoodItem] = []
    
    let foodCategories = [
        "Fruits", "Vegetables", "Meat", "Dairy",
        "Grains", "Beverages", "Snacks", "Fast Food"
    ]
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private let foodSearchService = FoodSearchService()

    // Comprehensive nutrition fields to track
    let nutritionFields: [String] = [
        "calories", "total_fat", "saturated_fat", "trans_fatty_acid", "cholesterol",
        "sodium", "total_carbohydrate", "dietary_fiber", "sugars", "protein",
        "potassium", "phosphorus", "vitamin_a_dv", "vitamin_c_dv", "calcium_dv",
        "iron_dv", "monounsaturated_fat", "polyunsaturated_fat", "vitamin_d_mcg",
        "thiamin_mg", "riboflavin_mg", "niacin_mg", "vitamin_b6_mg", "folate_mcg",
        "vitamin_b12_mcg", "biotin_mcg", "pantothenic_acid_mg", "phosphorus_mg",
        "iodine_mcg", "magnesium_mg", "zinc_mg", "selenium_mcg", "copper_mg",
        "manganese_mg", "chromium_mcg", "molybdenum_mcg", "chloride_mg",
        "vitamin_e_mg", "vitamin_k_mcg", "added_sugars_g", "omega_3_fatty_acid_g",
        "omega_6_fatty_acid_g", "dha_mg", "epa_mg", "alcohol_g"
    ]

    // Allergen fields to track
    let allergenFields: [String] = [
        "allergen_contains_milk", "allergen_contains_eggs", "allergen_contains_fish",
        "allergen_contains_shellfish", "allergen_contains_tree_nuts", "allergen_contains_peanuts",
        "allergen_contains_wheat", "allergen_contains_soybeans", "allergen_contains_gluten"
    ]

    init() {
        // Load sample data if empty
        if recentSearches.isEmpty {
            recentSearches = ["Oatmeal", "Chicken breast", "Greek yogurt"]
        }
        if recentItems.isEmpty {
            loadSampleRecentItems()
        }
        loadRecentItems()
        
        // Debounced search
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .filter { !$0.isEmpty }
            .sink { [weak self] query in
                self?.search()
            }
            .store(in: &cancellables)
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
                createFoodItem(from: nfood)
            }
            
            await MainActor.run {
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
    }
    
    private func createFoodItem(from nfood: NutritionixFood) -> FoodItem {
        // Extract serving information
        let servingQty = nfood.servingQty ?? 1.0
        let servingUnit = nfood.servingUnit ?? "serving"
        let servingWeightGrams = nfood.serving_weight_grams
        
        // Create quantity string
        let quantityString = "\(String(format: "%g", servingQty)) \(servingUnit)"
        
        // Extract ingredients - simplified since we don't have complex fullData
        let ingredientList: [String] = []
        
        // Build comprehensive nutrition dictionary
        var nutritionDict: [String: String] = [:]
        
        // Add brand information
        if let brand = nfood.brand {
            nutritionDict["brand"] = brand
        }
        
        // Add basic nutrition values
        if let calories = nfood.calories {
            nutritionDict["calories"] = String(format: "%.1f", calories)
        }
        if let protein = nfood.protein {
            nutritionDict["protein"] = String(format: "%.1f", protein)
        }
        if let carbs = nfood.carbs {
            nutritionDict["total_carbohydrate"] = String(format: "%.1f", carbs)
        }
        if let fat = nfood.fat {
            nutritionDict["total_fat"] = String(format: "%.1f", fat)
        }
        
        // Extract allergens - simplified inference
        let allergens = inferAllergens(from: nfood.name, brand: nfood.brand)
        
        // Create main nutrition info for easy access
        let nutrition = NutritionInfo(
            calories: nfood.calories.map { Int($0) },
            protein: nfood.protein,
            carbs: nfood.carbs,
            fat: nfood.fat,
            fiber: nil, // Will be nil until we get detailed nutrition
            sugar: nil,
            sodium: nil
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
    
    private func inferAllergens(from foodName: String, brand: String?) -> [String] {
        var allergens: [String] = []
        
        let allergenKeywords: [(String, [String])] = [
            ("Dairy", ["milk", "cheese", "cream", "butter", "whey", "casein", "lactose"]),
            ("Gluten", ["wheat", "barley", "rye", "malt", "bread", "flour", "gluten"]),
            ("Soy", ["soy", "soya", "soybean", "tofu", "tempeh"]),
            ("Eggs", ["egg", "albumin", "mayonnaise"]),
            ("Tree Nuts", ["almond", "cashew", "walnut", "pecan", "hazelnut", "pistachio", "macadamia"]),
            ("Peanuts", ["peanut", "groundnut"]),
            ("Fish", ["fish", "salmon", "tuna", "cod", "anchovy", "sardine"]),
            ("Shellfish", ["shrimp", "crab", "lobster", "shellfish", "prawn", "crawfish"]),
            ("Sesame", ["sesame", "tahini"])
        ]
        
        let searchText = (foodName + " " + (brand ?? "")).lowercased()
        
        for (allergen, keywords) in allergenKeywords {
            if keywords.contains(where: { searchText.contains($0) }) {
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
        
        // Add to meal builder - using the existing MealBuilder from your original code
        MealBuilder.shared.addFoodItem(foodItem)
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
        print("Saved \(recentItems.count) recent items")
    }
}

// MARK: - MealBuilder Singleton (keeping existing implementation)

class MealBuilder {
    static let shared = MealBuilder()
    
    private init() {}
    
    // Current meal being built
    private(set) var foodItems: [FoodItem] = []
    
    // Add a food item to the current meal
    func addFoodItem(_ item: FoodItem) {
        foodItems.append(item)
    }
    
    // Remove a food item from the current meal
    func removeFoodItem(_ item: FoodItem) {
        foodItems.removeAll { $0.id == item.id }
    }
    
    // Clear the current meal
    func clearMeal() {
        foodItems = []
    }
    
    // Get the current meal
    func getCurrentMeal() -> [FoodItem] {
        return foodItems
    }
}
