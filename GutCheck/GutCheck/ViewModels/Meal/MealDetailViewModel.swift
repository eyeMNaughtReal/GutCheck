//
//  MealDetailViewModel.swift
//  GutCheck
//
//  Created by Mark Conley on 7/14/25.
//


//
//  MealDetailViewModel.swift
//  GutCheck
//
//  Created on 7/14/25.
//

import Foundation
import FirebaseFirestore
import SwiftUI

@MainActor
class MealDetailViewModel: ObservableObject {
    // Meal data
    @Published var meal: Meal
    @Published var notes: String
    
    // Editing state
    @Published var isEditing = false
    @Published var isSaving = false
    @Published var editingFoodItem: FoodItem?
    
    // Alerts
    @Published var showingDeleteConfirmation = false
    @Published var showingErrorAlert = false
    @Published var errorMessage = ""
    
    // Navigation
    @Published var shouldDismiss = false
    
    // Firestore reference
    private let db = Firestore.firestore()
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // Initialization
    init(meal: Meal) {
        self.meal = meal
        self.notes = meal.notes ?? ""
    }
    
    // MARK: - Computed Properties
    
    var formattedDateTime: String {
        return dateFormatter.string(from: meal.date)
    }
    
    var formattedDate: String {
        return dateOnlyFormatter.string(from: meal.date)
    }
    
    var sourceDescription: String {
        switch meal.source {
        case .manual:
            return "Manual Entry"
        case .barcode:
            return "Barcode Scan"
        case .lidar:
            return "LiDAR Scan"
        case .ai:
            return "AI Recognition"
        }
    }
    
    var totalNutrition: NutritionInfo {
        var total = NutritionInfo()
        
        // Sum up all nutrition values
        for item in meal.foodItems {
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
    
    // MARK: - Editing Methods
    
    func startEditing() {
        isEditing = true
    }
    
    func cancelEditing() {
        isEditing = false
        // Reset any changes
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
    
    // MARK: - Save/Delete Methods
    
    func saveMeal() {
        isSaving = true
        
        // Update notes from editing field
        meal.notes = notes.isEmpty ? nil : notes
        
        Task {
            do {
                try await saveMealToFirestore()
                
                await MainActor.run {
                    isSaving = false
                    isEditing = false
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save meal: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func saveMealToFirestore() async throws {
        // Convert the meal to Firestore data
        let mealData = meal.toFirestoreData()
        
        // Save the meal document
        let mealRef = db.collection("meals").document(meal.id)
        try await mealRef.setData(mealData)
        
        // Delete old food items subcollection
        let foodItemsSnapshot = try await mealRef.collection("foodItems").getDocuments()
        for document in foodItemsSnapshot.documents {
            try await document.reference.delete()
        }
        
        // Save each food item as a subcollection
        for foodItem in meal.foodItems {
            let foodItemData: [String: Any] = [
                "id": foodItem.id,
                "name": foodItem.name,
                "quantity": foodItem.quantity,
                "estimatedWeightInGrams": foodItem.estimatedWeightInGrams as Any,
                "ingredients": foodItem.ingredients,
                "allergens": foodItem.allergens,
                "source": foodItem.source.rawValue,
                "isUserEdited": foodItem.isUserEdited,
                "barcodeValue": foodItem.barcodeValue as Any,
                // Nutrition data
                "nutrition": [
                    "calories": foodItem.nutrition.calories as Any,
                    "protein": foodItem.nutrition.protein as Any,
                    "carbs": foodItem.nutrition.carbs as Any,
                    "fat": foodItem.nutrition.fat as Any,
                    "fiber": foodItem.nutrition.fiber as Any,
                    "sugar": foodItem.nutrition.sugar as Any,
                    "sodium": foodItem.nutrition.sodium as Any
                ]
            ]
            
            try await mealRef.collection("foodItems").document(foodItem.id).setData(foodItemData)
        }
    }
    
    func confirmDelete() {
        showingDeleteConfirmation = true
    }
    
    func deleteMeal() async {
        do {
            try await db.collection("meals").document(meal.id).delete()
            
            // Navigate back after deletion
            shouldDismiss = true
        } catch {
            errorMessage = "Failed to delete meal: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
    
    // MARK: - Sharing
    
    func shareAsPDF() {
        // In a real app, we would generate a PDF here
        // For now, we'll just show a message
        errorMessage = "PDF sharing is not implemented yet"
        showingErrorAlert = true
    }
}