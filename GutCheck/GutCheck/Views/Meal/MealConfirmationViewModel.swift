import SwiftUI

class MealConfirmationViewModel: ObservableObject {
    @Published private(set) var totalNutrition: NutritionInfo?
    @Published private(set) var aiAnalysis: MealAnalysis?
    @Published private(set) var errorMessage: String?
    @Published var showError = false
    @Published var isSaving = false
    
    @MainActor
    func analyzeMeal(_ meal: Meal) async {
        // Calculate total nutrition
        totalNutrition = calculateTotalNutrition(from: meal.foodItems)
        
        do {
            // Get AI analysis from service
            let analysis = try await AIAnalysisService.shared.analyzeFoodItems(meal.foodItems)
            // Convert AIAnalysisResult to MealAnalysis
            aiAnalysis = MealAnalysis(
                insights: analysis.insights,
                warnings: analysis.recommendations
            )
        } catch {
            errorMessage = "Failed to analyze meal: \(error.localizedDescription)"
            showError = true
        }
    }
    
    @MainActor
    func saveMeal(_ meal: Meal) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        
        do {
            // Save to Firebase via MealRepository
            try await MealRepository.shared.save(meal)
            
            // Trigger dashboard refresh after successful save
            NavigationCoordinator.shared.refreshDashboard()
            
            // Additional sync can be added here in the future
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }
    
    private func calculateTotalNutrition(from foodItems: [FoodItem]) -> NutritionInfo {
        foodItems.reduce(NutritionInfo()) { total, item in
            var newTotal = total
            if let calories = item.nutrition.calories {
                newTotal.calories = (total.calories ?? 0) + calories
            }
            if let protein = item.nutrition.protein {
                newTotal.protein = (total.protein ?? 0) + protein
            }
            if let carbs = item.nutrition.carbs {
                newTotal.carbs = (total.carbs ?? 0) + carbs
            }
            if let fat = item.nutrition.fat {
                newTotal.fat = (total.fat ?? 0) + fat
            }
            if let fiber = item.nutrition.fiber {
                newTotal.fiber = (total.fiber ?? 0) + fiber
            }
            if let sugar = item.nutrition.sugar {
                newTotal.sugar = (total.sugar ?? 0) + sugar
            }
            return newTotal
        }
    }
}
