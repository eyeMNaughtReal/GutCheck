//
//  MealBuilderViewModel.swift
//  GutCheck
//
//  Fixed guard statement issues
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class MealBuilderViewModel: ObservableObject {
    // Meal properties
    @Published var mealName: String = ""
    @Published var mealType: MealType = .lunch
    @Published var mealDate: Date = Date()
    @Published var notes: String = ""
    @Published var foodItems: [FoodItem] = []
    @Published var isSaving: Bool = false
    
    // Error state
    @Published var errorMessage: String?
    
    // Food item being edited
    @Published var editingFoodItem: FoodItem?
    
    // Repository dependency
    private let mealRepository: MealRepository
    
    // Dependency injection for easier testing
    init(mealRepository: MealRepository = MealRepository.shared) {
        self.mealRepository = mealRepository
    }
    
    // Computed properties
    var formattedDateTime: String {
        mealDate.formattedDateTime
    }
    
    var totalNutrition: NutritionInfo {
        var total = NutritionInfo()
        
        // Sum up all nutrition values
        for item in foodItems {
            // Calories
            if let itemCalories = item.nutrition.calories {
                total.calories = (total.calories ?? 0) + itemCalories
            }
            
            // Protein
            if let itemProtein = item.nutrition.protein {
                total.protein = (total.protein ?? 0) + itemProtein
            }
            
            // Carbs
            if let itemCarbs = item.nutrition.carbs {
                total.carbs = (total.carbs ?? 0) + itemCarbs
            }
            
            // Fat
            if let itemFat = item.nutrition.fat {
                total.fat = (total.fat ?? 0) + itemFat
            }
            
            // Fiber
            if let itemFiber = item.nutrition.fiber {
                total.fiber = (total.fiber ?? 0) + itemFiber
            }
            
            // Sugar
            if let itemSugar = item.nutrition.sugar {
                total.sugar = (total.sugar ?? 0) + itemSugar
            }
            
            // Sodium
            if let itemSodium = item.nutrition.sodium {
                total.sodium = (total.sodium ?? 0) + itemSodium
            }
        }
        
        return total
    }
    
    // MARK: - Methods
    
    func addFoodItem() {
        // This would typically show a modal to add a food item
        // For now, we'll add a placeholder item
        let newItem = FoodItem(
            name: "New Food Item \(foodItems.count + 1)",
            quantity: "1 serving",
            estimatedWeightInGrams: 100,
            nutrition: NutritionInfo(
                calories: 250,
                protein: 10,
                carbs: 30,
                fat: 10,
                fiber: 2,
                sugar: 5,
                sodium: 200
            )
        )
        
        foodItems.append(newItem)
    }
    
    func editFoodItem(_ item: FoodItem) {
        // This would typically show a modal to edit the food item
        // For now, we'll just set the editing item
        editingFoodItem = item
    }
    
    func removeFoodItem(_ item: FoodItem) {
        foodItems.removeAll { $0.id == item.id }
    }
    
    func updateFoodItem(_ updatedItem: FoodItem) {
        if let index = foodItems.firstIndex(where: { $0.id == updatedItem.id }) {
            foodItems[index] = updatedItem
        }
        editingFoodItem = nil
    }
    
    func saveMeal() {
        // FIXED: Added proper return statements to guard clauses
        guard !foodItems.isEmpty else {
            errorMessage = "You need to add at least one food item"
            return  // <-- This was missing
        }
        
        if mealName.isEmpty {
            // Generate a default name if empty
            mealName = "\(mealType.rawValue.capitalized) \(formattedDateTime)"
        }
        
        // ✅ Execution continues normally
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                // Ensure user is authenticated
                guard let userId = Auth.auth().currentUser?.uid else {
                    await MainActor.run {
                        self.errorMessage = "User not authenticated"
                        self.isSaving = false
                    }
                    return  // <-- Exit the Task
                }
                
                // Create the meal object
                let meal = Meal(
                    name: mealName,
                    date: mealDate,
                    type: mealType,
                    source: .manual,
                    foodItems: foodItems,
                    notes: notes.isEmpty ? nil : notes,
                    tags: extractTags(),
                    createdBy: userId
                )
                
                // Save to repository (using the new repository pattern)
                try await mealRepository.saveWithFoodItems(meal)
                
                // Update UI
                await MainActor.run {
                    self.isSaving = false
                    self.resetForm()
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save meal: \(error.localizedDescription)"
                    self.isSaving = false
                }
            }
        }
    }
    
    private func extractTags() -> [String] {
        // Extract tags from food items for easier searching/filtering
        var tags: Set<String> = []
        
        // Add meal type as a tag
        tags.insert(mealType.rawValue.lowercased())
        
        // Extract tags from allergens and ingredients
        for item in foodItems {
            // Add allergens as tags
            tags = tags.union(item.allergens.map { $0.lowercased() })
            
            // Add key ingredients as tags
            tags = tags.union(item.ingredients.map { $0.lowercased() })
        }
        
        return Array(tags)
    }
    
    private func resetForm() {
        mealName = ""
        mealType = .lunch
        mealDate = Date()
        notes = ""
        foodItems = []
        editingFoodItem = nil
        errorMessage = nil
    }
}
