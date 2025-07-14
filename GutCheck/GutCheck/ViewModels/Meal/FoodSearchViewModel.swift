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
    
    // Selected food item
    @Published var selectedFoodItem: FoodItem?
    
    // Suggestions
    @Published var recentSearches: [String] = ["Oatmeal", "Chicken breast", "Greek yogurt"]
    @Published var recentItems: [FoodItem] = []
    
    // Common food categories
    let foodCategories = [
        "Fruits", "Vegetables", "Meat", "Dairy", 
        "Grains", "Beverages", "Snacks", "Fast Food"
    ]
    
    // Firestore reference
    private let db = Firestore.firestore()
    
    // Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // Meal building state
    private var mealBuilder = MealBuilder.shared
    
    init() {
        // Load recent items
        loadRecentItems()
        
        // Set up search debounce
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
        
        // In a real app, we would search a database or API
        // For now, we'll create mock results
        
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Generate mock results
            let mockResults = createMockSearchResults(for: searchQuery)
            
            // Update on main thread
            await MainActor.run {
                self.searchResults = mockResults
                self.isSearching = false
                
                // Add to recent searches if not already there
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
        // Create a new empty food item
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
            if recentItems.count > 5 {
                recentItems.removeLast()
            }
            
            // Save recent items to UserDefaults
            saveRecentItems()
        }
        
        // Add to meal builder
        MealBuilder.shared.addFoodItem(foodItem)
    }
    
    // MARK: - Private helpers
    
    private func loadRecentItems() {
        // In a real app, we would load from UserDefaults or database
        // For now, we'll create mock items
        recentItems = [
            FoodItem(
                name: "Oatmeal",
                quantity: "1 cup",
                estimatedWeightInGrams: 240,
                nutrition: NutritionInfo(calories: 158, protein: 6, carbs: 27, fat: 3)
            ),
            FoodItem(
                name: "Banana",
                quantity: "1 medium",
                estimatedWeightInGrams: 118,
                nutrition: NutritionInfo(calories: 105, protein: 1, carbs: 27, fat: 0)
            ),
            FoodItem(
                name: "Coffee with Milk",
                quantity: "8 oz",
                estimatedWeightInGrams: 240,
                nutrition: NutritionInfo(calories: 40, protein: 2, carbs: 3, fat: 2)
            )
        ]
    }
    
    private func saveRecentItems() {
        // In a real app, we would save to UserDefaults or database
        // For now, we'll just print
        print("Saved \(recentItems.count) recent items")
    }
    
    private func createMockSearchResults(for query: String) -> [FoodItem] {
        // Create mock search results based on the query
        let lowercasedQuery = query.lowercased()
        
        // Common food items that might match the query
        let foodOptions: [(name: String, calories: Int, protein: Double, carbs: Double, fat: Double)] = [
            ("Apple", 95, 0.5, 25.0, 0.3),
            ("Banana", 105, 1.3, 27.0, 0.4),
            ("Orange", 62, 1.2, 15.0, 0.2),
            ("Chicken Breast", 165, 31.0, 0.0, 3.6),
            ("Ground Beef", 250, 26.0, 0.0, 17.0),
            ("Salmon", 206, 22.0, 0.0, 13.0),
            ("White Rice", 205, 4.3, 45.0, 0.4),
            ("Brown Rice", 216, 5.0, 45.0, 1.8),
            ("Quinoa", 222, 8.0, 39.0, 3.6),
            ("Greek Yogurt", 120, 22.0, 9.0, 0.5),
            ("Cheddar Cheese", 113, 7.0, 0.4, 9.0),
            ("Milk", 122, 8.0, 12.0, 5.0),
            ("Spinach", 23, 2.9, 3.6, 0.4),
            ("Broccoli", 55, 3.7, 11.2, 0.6),
            ("Oatmeal", 158, 6.0, 27.0, 3.0),
            ("Egg", 72, 6.3, 0.6, 5.0),
            ("Avocado", 240, 3.0, 12.0, 22.0),
            ("Sweet Potato", 180, 4.0, 41.0, 0.0),
            ("Almonds", 164, 6.0, 6.0, 14.0),
            ("Chocolate", 535, 7.8, 59.0, 30.0)
        ]
        
        // Filter options by query
        let filteredOptions = foodOptions.filter { $0.name.lowercased().contains(lowercasedQuery) }
        
        // Convert to FoodItem objects
        return filteredOptions.map { option in
            FoodItem(
                name: option.name,
                quantity: "1 serving",
                estimatedWeightInGrams: 100,
                nutrition: NutritionInfo(
                    calories: option.calories,
                    protein: option.protein,
                    carbs: option.carbs,
                    fat: option.fat
                )
            )
        }
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