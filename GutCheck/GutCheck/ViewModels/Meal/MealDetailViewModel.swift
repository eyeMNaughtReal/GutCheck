import Foundation
import FirebaseFirestore
import SwiftUI

@MainActor
class MealDetailViewModel: ObservableObject {
    @Published var meal: Meal
    @Published var mealId: String?
    @Published var notes: String = ""
    @Published var isEditing = false
    @Published var isSaving = false
    @Published var isLoading = false
    @Published var editingFoodItem: FoodItem?
    @Published var showingDeleteConfirmation = false
    @Published var showingErrorAlert = false
    @Published var errorMessage = ""
    @Published var shouldDismiss = false
    
    // Repository dependency
    private let mealRepository: MealRepository
    
    // Initialize with a Meal object
    init(meal: Meal, mealRepository: MealRepository = MealRepository.shared) {
        self.meal = meal
        self.mealId = meal.id
        self.notes = meal.notes ?? ""
        self.mealRepository = mealRepository
    }
    
    // Initialize with a meal ID
    init(mealId: String, mealRepository: MealRepository = MealRepository.shared) {
        self.mealId = mealId
        self.meal = Meal.emptyMeal()
        self.mealRepository = mealRepository
        self.isLoading = true
    }
    
    // Load meal by ID
    func loadMeal() async {
        guard let id = mealId else { return }
        
        isLoading = true
        
        do {
            if let loadedMeal = try await mealRepository.fetch(id: id) {
                self.meal = loadedMeal
                self.notes = loadedMeal.notes ?? ""
                
                print("✅ Meal loaded successfully: \(loadedMeal.name)")
            } else {
                self.errorMessage = "Could not find the meal"
                self.showingErrorAlert = true
                print("⚠️ No meal found with ID: \(id)")
            }
        } catch {
            self.errorMessage = "Error loading meal: \(error.localizedDescription)"
            self.showingErrorAlert = true
            print("❌ Error loading meal: \(error)")
        }
        
        isLoading = false
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
    
    func updateNotes() {
        meal.notes = notes.isEmpty ? nil : notes
    }
    
    func saveMeal() async -> Bool {
        isSaving = true
        
        // Update the notes before saving
        updateNotes()
        
        do {
            try await mealRepository.save(meal)
            isSaving = false
            isEditing = false
            return true
        } catch {
            errorMessage = "Failed to save meal: \(error.localizedDescription)"
            showingErrorAlert = true
            isSaving = false
            return false
        }
    }
    
    func deleteMeal() async -> Bool {
        do {
            try await mealRepository.delete(id: meal.id)
            return true
        } catch {
            errorMessage = "Failed to delete meal: \(error.localizedDescription)"
            showingErrorAlert = true
            return false
        }
    }
    
    func updateFoodItem(_ foodItem: FoodItem) {
        if let index = meal.foodItems.firstIndex(where: { $0.id == foodItem.id }) {
            meal.foodItems[index] = foodItem
        }
    }
    
    func removeFoodItem(_ foodItem: FoodItem) {
        meal.foodItems.removeAll { $0.id == foodItem.id }
    }
}

// Extension on Meal to provide an empty meal for initialization
extension Meal {
    static func emptyMeal() -> Meal {
        return Meal(
            id: "",
            name: "Loading...",
            date: Date(),
            type: .breakfast,
            source: .manual,
            foodItems: []
        )
    }
    
    static var sampleMeal: Meal {
        return Meal(
            id: UUID().uuidString,
            name: "Sample Lunch",
            date: Date(),
            type: .lunch,
            source: .manual,
            foodItems: [
                FoodItem(
                    name: "Salad", 
                    quantity: "1 serving",
                    nutrition: NutritionInfo(calories: 250)
                ),
                FoodItem(
                    name: "Chicken", 
                    quantity: "3 oz",
                    nutrition: NutritionInfo(calories: 350)
                )
            ],
            notes: "This is a sample meal"
        )
    }
}