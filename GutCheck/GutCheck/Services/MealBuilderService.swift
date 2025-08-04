//
//  MealBuilderService.swift
//  GutCheck
//
//  Unified service for all meal building operations across the app
//  Replaces inconsistent patterns with single source of truth
//

import Foundation
import SwiftUI
import Combine

@MainActor
class MealBuilderService: ObservableObject {
    static let shared = MealBuilderService()
    
    // MARK: - Published Properties
    @Published var currentMeal: [FoodItem] = []
    @Published var mealType: MealType = .lunch
    @Published var mealDate: Date = Date()
    @Published var mealName: String = ""
    @Published var notes: String = ""
    @Published var isBuilding: Bool = false
    
    // Navigation state
    @Published var shouldNavigateToBuilder: Bool = false
    @Published var shouldDismissModal: Bool = false
    
    private let mealRepository: MealRepository
    
    private init(mealRepository: MealRepository = MealRepository.shared) {
        self.mealRepository = mealRepository
    }
    
    // MARK: - Core Food Item Operations
    
    /// Add a food item to the current meal being built
    func addFoodItem(_ item: FoodItem) {
        Swift.print("📝 MealBuilderService: Adding food item '\(item.name)' to meal")
        currentMeal.append(item)
        isBuilding = true
        
        // Trigger navigation to meal builder if not already there
        if !shouldNavigateToBuilder {
            shouldNavigateToBuilder = true
        }
        
        // Signal that modals should dismiss
        shouldDismissModal = true
    }
    
    /// Remove a food item from the current meal
    func removeFoodItem(_ item: FoodItem) {
        Swift.print("🗑️ MealBuilderService: Removing food item '\(item.name)' from meal")
        currentMeal.removeAll { $0.id == item.id }
        
        if currentMeal.isEmpty {
            isBuilding = false
        }
    }
    
    /// Update an existing food item in the current meal
    func updateFoodItem(_ item: FoodItem) {
        Swift.print("✏️ MealBuilderService: Updating food item '\(item.name)'")
        if let index = currentMeal.firstIndex(where: { $0.id == item.id }) {
            currentMeal[index] = item
        }
    }
    
    /// Replace all food items in the current meal
    func setFoodItems(_ items: [FoodItem]) {
        Swift.print("📋 MealBuilderService: Setting \(items.count) food items")
        currentMeal = items
        isBuilding = !items.isEmpty
    }
    
    // MARK: - Meal Operations
    
    /// Start building a new meal (clears current state)
    func startNewMeal(type: MealType = .lunch) {
        Swift.print("🆕 MealBuilderService: Starting new \(type.rawValue) meal")
        clearMeal()
        mealType = type
        mealDate = Date()
        isBuilding = false
    }
    
    /// Clear the current meal being built
    func clearMeal() {
        Swift.print("🧹 MealBuilderService: Clearing current meal")
        currentMeal.removeAll()
        mealName = ""
        notes = ""
        mealDate = Date()
        isBuilding = false
        shouldNavigateToBuilder = false
        shouldDismissModal = false
    }
    
    /// Save the current meal to the repository
    func saveMeal() async throws -> Meal {
        guard !currentMeal.isEmpty else {
            throw MealBuilderError.noFoodItems
        }
        
        guard let userId = FirebaseManager.shared.currentUser?.uid else {
            throw MealBuilderError.notAuthenticated
        }
        
        // Generate meal name if empty
        let finalMealName = mealName.isEmpty ? generateDefaultMealName() : mealName
        
        let meal = Meal(
            name: finalMealName,
            date: mealDate,
            type: mealType,
            source: .manual,
            foodItems: currentMeal,
            notes: notes.isEmpty ? nil : notes,
            tags: extractTags(),
            createdBy: userId
        )
        
        Swift.print("💾 MealBuilderService: Saving meal '\(meal.name)' with \(meal.foodItems.count) items")
        
        try await mealRepository.save(meal)
        
        // Trigger dashboard refresh after successful save
        await MainActor.run {
            NavigationCoordinator.shared.refreshDashboard()
        }
        
        // Clear after successful save
        clearMeal()
        
        return meal
    }
    
    // MARK: - Computed Properties
    
    var totalNutrition: NutritionInfo {
        var total = NutritionInfo()
        
        for item in currentMeal {
            if let itemCalories = item.nutrition.calories {
                total.calories = (total.calories ?? 0) + itemCalories
            }
            if let itemProtein = item.nutrition.protein {
                total.protein = (total.protein ?? 0) + itemProtein
            }
            if let itemCarbs = item.nutrition.carbs {
                total.carbs = (total.carbs ?? 0) + itemCarbs
            }
            if let itemFat = item.nutrition.fat {
                total.fat = (total.fat ?? 0) + itemFat
            }
            if let itemFiber = item.nutrition.fiber {
                total.fiber = (total.fiber ?? 0) + itemFiber
            }
            if let itemSugar = item.nutrition.sugar {
                total.sugar = (total.sugar ?? 0) + itemSugar
            }
            if let itemSodium = item.nutrition.sodium {
                total.sodium = (total.sodium ?? 0) + itemSodium
            }
        }
        
        return total
    }
    
    var formattedDateTime: String {
        mealDate.formattedDateTime
    }
    
    var isEmpty: Bool {
        currentMeal.isEmpty
    }
    
    // MARK: - Helper Methods
    
    private func generateDefaultMealName() -> String {
        return "\(mealType.rawValue.capitalized) \(formattedDateTime)"
    }
    
    private func extractTags() -> [String] {
        var tags: Set<String> = []
        
        // Add meal type as a tag
        tags.insert(mealType.rawValue.lowercased())
        
        // Extract tags from allergens and ingredients
        for item in currentMeal {
            tags = tags.union(item.allergens.map { $0.lowercased() })
            tags = tags.union(item.ingredients.map { $0.lowercased() })
        }
        
        return Array(tags)
    }
    
    // MARK: - Navigation Helpers
    
    /// Reset navigation state (call after navigation completes)
    func resetNavigationState() {
        shouldNavigateToBuilder = false
        shouldDismissModal = false
    }
    
    /// Check if there are unsaved changes
    var hasUnsavedChanges: Bool {
        return !currentMeal.isEmpty || !mealName.isEmpty || !notes.isEmpty
    }
}

// MARK: - Error Types

enum MealBuilderError: LocalizedError {
    case noFoodItems
    case notAuthenticated
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noFoodItems:
            return "You need to add at least one food item to save the meal."
        case .notAuthenticated:
            return "You must be logged in to save meals."
        case .saveFailed(let message):
            return "Failed to save meal: \(message)"
        }
    }
}

// MARK: - Protocol for Consistent "Add to Meal" Behavior

protocol FoodItemAddable {
    func addToMeal(_ foodItem: FoodItem)
}

extension FoodItemAddable {
    @MainActor
    func addToMeal(_ foodItem: FoodItem) {
        MealBuilderService.shared.addFoodItem(foodItem)
    }
}
