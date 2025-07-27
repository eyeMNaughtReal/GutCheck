import Foundation
import SwiftUI
import Combine

final class LogMealViewModel: ObservableObject {
    // MARK: - Input Properties (bound to UI)
    @Published var mealName: String = ""
    @Published var mealType: MealType = .lunch
    @Published var showFoodSearch: Bool = false
    @Published var foodItems: [FoodItem] = [
        FoodItem(
            name: "",
            quantity: "",
            estimatedWeightInGrams: nil,
            ingredients: [],
            allergens: [],
            nutrition: NutritionInfo(),
            isUserEdited: true
        )
    ]
    @Published var notes: String = ""
    @Published var isSaving: Bool = false

    @Published private(set) var userID: String?

    // MARK: - Save Function
    @MainActor
    func saveMeal() async throws {
        isSaving = true
        
        guard let userId = FirebaseManager.shared.currentUser?.uid else {
            throw FirebaseError.notAuthenticated
        }
        
        if userID != userId {
            userID = userId
        }
        
        let newMeal = Meal(
            name: self.mealName,
            date: Date(),
            type: self.mealType,
            source: .manual,
            foodItems: self.foodItems,
            notes: self.notes.isEmpty ? nil : self.notes,
            tags: [],
            createdBy: userId
        )

            // TODO: Save to Firebase/Core Data
            print("Saved meal: \(newMeal)")
            self.reset()
    }

    // MARK: - Reset form after save
    func reset() {
        mealName = ""
        mealType = .lunch
        foodItems = [
            FoodItem(
                name: "",
                quantity: "",
                estimatedWeightInGrams: nil,
                ingredients: [],
                allergens: [],
                nutrition: NutritionInfo(),
                isUserEdited: true
            )
        ]
        notes = ""
        isSaving = false
    }
}
