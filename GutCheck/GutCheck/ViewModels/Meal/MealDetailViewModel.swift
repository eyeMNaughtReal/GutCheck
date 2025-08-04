//
//  MealDetailViewModel.swift
//  GutCheck
//
//  Created by Mark Conley on 7/14/25.
//

import Foundation
import FirebaseFirestore
import SwiftUI

@MainActor
class MealDetailViewModel: ObservableObject {
    @Published var meal: Meal
    @Published var notes: String
    @Published var isEditing = false
    @Published var isSaving = false
    @Published var editingFoodItem: FoodItem?
    @Published var showingDeleteConfirmation = false
    @Published var showingErrorAlert = false
    @Published var errorMessage = ""
    @Published var shouldDismiss = false
    
    // Repository dependency
    private let mealRepository: MealRepository
    
    // Using DateFormattingService instead of local formatters
    
    init(meal: Meal, mealRepository: MealRepository = MealRepository.shared) {
        self.meal = meal
        self.notes = meal.notes ?? ""
        self.mealRepository = mealRepository
    }
    
    // Computed properties using DateFormattingService
    var formattedDateTime: String {
        meal.date.formattedDateTime
    }
    
    var formattedDate: String {
        meal.date.formattedDate
    }
    
    var sourceDescription: String {
        switch meal.source {
        case .manual: return "Manual Entry"
        case .barcode: return "Barcode Scan"
        case .lidar: return "LiDAR Scan"
        case .ai: return "AI Recognition"
        }
    }
    
    var totalNutrition: NutritionInfo {
        var total = NutritionInfo()
        
        for item in meal.foodItems {
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
    
    // MARK: - Methods (Simplified using Repository)
    
    func startEditing() {
        isEditing = true
    }
    
    func cancelEditing() {
        isEditing = false
        notes = meal.notes ?? ""
    }
    
    func editFoodItem(_ item: FoodItem) {
        editingFoodItem = item
    }
    
    func updateFoodItem(_ updatedItem: FoodItem) {
        if let index = meal.foodItems.firstIndex(where: { $0.id == updatedItem.id }) {
            meal.foodItems[index] = updatedItem
        }
    }
    
    func removeFoodItem(_ item: FoodItem) {
        meal.foodItems.removeAll { $0.id == item.id }
    }
    
    func addNewFoodItem() {
        let newItem = FoodItem(
            name: "New Food Item",
            quantity: "1 serving",
            nutrition: NutritionInfo()
        )
        
        editingFoodItem = newItem
    }
    
    // MARK: - Save Method (Refactored)
    
    func saveMeal() {
        isSaving = true
        errorMessage = ""
        
        meal.notes = notes.isEmpty ? nil : notes
        
        Task {
            do {
                try await mealRepository.save(meal)
                
                await MainActor.run {
                    self.isSaving = false
                    self.isEditing = false
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.errorMessage = error.localizedDescription
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - Delete Method (Refactored)
    
    func confirmDelete() {
        showingDeleteConfirmation = true
    }
    
    func deleteMeal() async {
        do {
            try await mealRepository.delete(id: meal.id)
            shouldDismiss = true
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
    
    func shareAsPDF() {
        errorMessage = "PDF sharing is not implemented yet"
        showingErrorAlert = true
    }
}
