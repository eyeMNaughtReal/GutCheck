//
//  FoodSearchViewModel.swift
//  GutCheck
//
//  Created by Mark Conley on 7/14/25.
//


//
//  FoodSearchViewModel.swift
//  GutCheck
//
//  Created on 7/14/25.
//


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
    private var mealBuilder = MealBuilder.shared
    private let foodSearchService = FoodSearchService()

    // Nutritionix fields to track
    let nutritionFields: [String] = [
        "calories", "total_fat", "saturated_fat", "trans_fatty_acid", "cholesterol", "sodium", "total_carbohydrate", "dietary_fiber", "sugars", "protein", "potassium", "phosphorus", "vitamin_a_dv", "vitamin_c_dv", "calcium_dv", "iron_dv", "monounsaturated_fat", "polyunsaturated_fat", "vitamin_d_mcg", "thiamin_mg", "riboflavin_mg", "niacin_mg", "vitamin_b6_mg", "folate_mcg", "vitamin_b12_mcg", "biotin_mcg", "pantothenic_acid_mg", "phosphorus_mg", "iodine_mcg", "magnesium_mg", "zinc_mg", "selenium_mcg", "copper_mg", "manganese_mg", "chromium_mcg", "molybdenum_mcg", "chloride_mg", "vitamin_e_mg", "vitamin_k_mcg"
    ]

    // Allergen fields to track
    let allergenFields: [String] = [
        "allergen_contains_milk", "allergen_contains_eggs", "allergen_contains_fish", "allergen_contains_shellfish", "allergen_contains_tree_nuts", "allergen_contains_peanuts", "allergen_contains_wheat", "allergen_contains_soybeans", "allergen_contains_gluten"
    ]

    init() {
        // Always load sample data if empty
        if recentSearches.isEmpty {
            recentSearches = ["Oatmeal", "Chicken breast", "Greek yogurt"]
        }
        if recentItems.isEmpty {
            recentItems = [
                FoodItem(name: "Oatmeal", quantity: "1 cup", nutrition: NutritionInfo(calories: 158, protein: 6, carbs: 27, fat: 3)),
                FoodItem(name: "Banana", quantity: "1 medium", nutrition: NutritionInfo(calories: 105, protein: 1, carbs: 27, fat: 0)),
                FoodItem(name: "Greek Yogurt", quantity: "1 cup", nutrition: NutritionInfo(calories: 150, protein: 20, carbs: 9, fat: 4))
            ]
        }
        loadRecentItems()
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
                // Use top-level NutritionixFood properties for main nutrition fields
                let servingQty = nfood.servingQty != nil ? String(format: "%g", nfood.servingQty!) : "N/A"
                let servingUnit = nfood.servingUnit ?? "N/A"
                let servingWeightGrams = nfood.serving_weight_grams != nil ? String(format: "%g", nfood.serving_weight_grams!) : "N/A"

                // Ingredients (from fullData if available, else empty)
                let ingredientString: String = {
                    if let fullData = nfood.fullData, let anyCodable = fullData["ingredients"] {
                        let mirror = Mirror(reflecting: anyCodable)
                        if let str = mirror.children.first?.value as? String {
                            return str
                        }
                    }
                    return "N/A"
                }()
                let ingredientList = ingredientString == "N/A" ? [] : ingredientString.lowercased().split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

                // Build nutrition dictionary for all fields
                var nutritionDict: [String: String] = [:]
                for field in nutritionFields {
                    // Try to get from top-level property if available, else from fullData
                    let value: String? = {
                        switch field {
                        case "calories":
                            if let v = nfood.calories { return String(format: "%g", v) }
                        case "protein":
                            if let v = nfood.protein { return String(format: "%g", v) }
                        case "total_carbohydrate":
                            if let v = nfood.carbs { return String(format: "%g", v) }
                        case "total_fat":
                            if let v = nfood.fat { return String(format: "%g", v) }
                        default:
                            break
                        }
                        if let fullData = nfood.fullData, let anyCodable = fullData["nf_" + field] {
                            let mirror = Mirror(reflecting: anyCodable)
                            if let v = mirror.children.first?.value {
                                return "\(v)"
                            }
                            return "\(anyCodable)"
                        }
                        return nil
                    }()
                    nutritionDict[field] = value ?? "N/A"
                }

                // Infer allergens/triggers (same as before, but add food family)
                var inferredAllergens: [String] = []
                var inferredTriggers: [String] = []
                let allergenKeywords: [(String, [String])] = [
                    ("dairy", ["milk", "cheese", "cream", "butter", "whey", "casein"]),
                    ("gluten", ["wheat", "barley", "rye", "malt", "bread", "bun", "flour"]),
                    ("soy", ["soy", "soya", "soybean"]),
                    ("eggs", ["egg"]),
                    ("nuts", ["almond", "cashew", "walnut", "pecan", "hazelnut", "nut"]),
                    ("peanuts", ["peanut"]),
                    ("fish", ["fish", "salmon", "tuna", "cod", "anchovy"]),
                    ("shellfish", ["shrimp", "crab", "lobster", "shellfish"]),
                    ("sesame", ["sesame"])
                ]
                let triggerKeywords: [(String, [String])] = [
                    ("red meat", ["beef", "steak", "burger", "pork", "bacon", "sausage"]),
                    ("histamine", ["tomato", "cheese", "vinegar", "fermented", "sauerkraut", "cured", "smoked", "spinach", "eggplant"]),
                    ("processed food", ["maltodextrin", "monosodium glutamate", "preservative", "artificial", "color", "flavor", "emulsifier", "high fructose", "corn syrup", "hydrogenated", "additive"])
                ]
                let foodFamilyKeywords: [(String, [String])] = [
                    ("nightshade", ["tomato", "eggplant", "pepper", "potato", "goji", "tomatillo"])
                ]
                for (allergen, keywords) in allergenKeywords {
                    if keywords.contains(where: { ingredientString.contains($0) }) {
                        inferredAllergens.append(allergen)
                    }
                }
                for (trigger, keywords) in triggerKeywords {
                    if keywords.contains(where: { ingredientString.contains($0) }) {
                        inferredTriggers.append(trigger)
                    }
                }
                // Add food family triggers
                for (family, keywords) in foodFamilyKeywords {
                    if keywords.contains(where: { ingredientString.contains($0) || nfood.name.lowercased().contains($0) }) {
                        inferredTriggers.append(family)
                    }
                }
                let nameLower = nfood.name.lowercased()
                if ["beef", "burger", "steak", "pork", "bacon", "sausage"].contains(where: { nameLower.contains($0) }) {
                    if !inferredTriggers.contains("red meat") { inferredTriggers.append("red meat") }
                }
                if ["bread", "bun", "flour"].contains(where: { nameLower.contains($0) }) {
                    if !inferredAllergens.contains("gluten") { inferredAllergens.append("gluten") }
                }
                if ingredientList.count > 3 || inferredTriggers.contains("processed food") {
                    if !inferredTriggers.contains("processed food") { inferredTriggers.append("processed food") }
                }

                // Compose FoodItem with all fields, including nutritionDetails for UI listing
                return FoodItem(
                    id: nfood.id,
                    name: nfood.name,
                    quantity: "\(servingQty) \(servingUnit)",
                    estimatedWeightInGrams: servingWeightGrams == "N/A" ? nil : Double(servingWeightGrams),
                    ingredients: ingredientList,
                    allergens: inferredAllergens,
                    nutrition: NutritionInfo(
                        calories: nutritionDict["calories"] != "N/A" ? Int(nutritionDict["calories"] ?? "0") : nil,
                        protein: nutritionDict["protein"] != "N/A" ? Double(nutritionDict["protein"] ?? "0") : nil,
                        carbs: nutritionDict["total_carbohydrate"] != "N/A" ? Double(nutritionDict["total_carbohydrate"] ?? "0") : nil,
                        fat: nutritionDict["total_fat"] != "N/A" ? Double(nutritionDict["total_fat"] ?? "0") : nil
                    ),
                    source: .manual,
                    isUserEdited: false,
                    nutritionDetails: nutritionDict
                )
            }
            await MainActor.run {
                self.searchResults = foods
                self.isSearching = false
                if !self.recentSearches.contains(self.searchQuery) {
                    self.recentSearches.insert(self.searchQuery, at: 0)
                    if self.recentSearches.count > 5 {
                        self.recentSearches.removeLast()
                    }
                }
            }
        }
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
        if !recentItems.contains(where: { $0.id == foodItem.id }) {
            recentItems.insert(foodItem, at: 0)
            if recentItems.count > 5 {
                recentItems.removeLast()
            }
            saveRecentItems()
        }
        MealBuilder.shared.addFoodItem(foodItem)
    }

    // MARK: - Recent Items Loader
    func loadRecentItems() {
        recentItems = [
            FoodItem(
                name: "Oatmeal",
                quantity: "1 cup",
                estimatedWeightInGrams: 240.0,
                nutrition: NutritionInfo(calories: 158, protein: 6, carbs: 27, fat: 3)
            ),
            FoodItem(
                name: "Banana",
                quantity: "1 medium",
                estimatedWeightInGrams: 118.0,
                nutrition: NutritionInfo(calories: 105, protein: 1, carbs: 27, fat: 0)
            ),
            FoodItem(
                name: "Coffee with Milk",
                quantity: "8 oz",
                estimatedWeightInGrams: 240.0,
                nutrition: NutritionInfo(calories: 40, protein: 2, carbs: 3, fat: 2)
            )
        ]
    }

    private func saveRecentItems() {
        print("Saved \(recentItems.count) recent items")
    }
}


// MARK: - MealBuilder Singleton

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