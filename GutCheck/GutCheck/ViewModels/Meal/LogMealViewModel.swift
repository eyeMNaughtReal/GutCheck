import Foundation
import SwiftUI
import Combine

final class LogMealViewModel: ObservableObject, HasLoadingState {
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

    @Published private(set) var userID: String?
    
    let loadingState = LoadingStateManager()

    // MARK: - Save Function
    @MainActor
    func saveMeal() async throws {
        loadingState.startSaving()
        
        guard let userId = AuthenticationManager.shared.currentUserId else {
            loadingState.setError("User not authenticated")
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

        do {
            // Save to Firebase via MealRepository
            try await MealRepository.shared.save(newMeal)
            print("✅ LogMealViewModel: Successfully saved meal to Firebase")
            
            // Write to HealthKit if nutrition data is available
            await writeToHealthKit(newMeal)
            
            // Trigger dashboard refresh after successful save
            DataSyncManager.shared.triggerRefreshAfterSave(operation: "Meal save", dataType: .meals)
            
            loadingState.clearError()
            self.reset()
        } catch {
            print("❌ LogMealViewModel: Error saving meal: \(error)")
            loadingState.setError(error.localizedDescription)
            throw error
        }
        
        loadingState.stopSaving()
    }
    
    // MARK: - HealthKit Integration
    private func writeToHealthKit(_ meal: Meal) async {
        await HealthKitAsyncWrapper.shared.writeMealWithLogging(meal)
    }

    // MARK: - Reset form after save
    @MainActor
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
        loadingState.reset()
    }
}
