//
//  MealBuilderTests.swift
//  GutCheckTests
//
//  Tests for MealBuilder functionality to validate cart-like interface
//

import Testing
@testable import GutCheck

struct MealBuilderTests {
    
    // Test data
    private let sampleFoodItem1 = FoodItem(
        name: "Grilled Chicken",
        quantity: "1 breast (6 oz)",
        nutrition: NutritionInfo(calories: 230, protein: 43.0, carbs: 0.0, fat: 5.0)
    )
    
    private let sampleFoodItem2 = FoodItem(
        name: "Brown Rice",
        quantity: "1 cup cooked",
        nutrition: NutritionInfo(calories: 216, protein: 5.0, carbs: 45.0, fat: 1.8)
    )
    
    @Test @MainActor func testMealBuilderServiceAddFoodItem() async throws {
        let service = MealBuilderService()
        
        // Initially empty
        #expect(service.currentMeal.isEmpty)
        #expect(service.isBuilding == false)
        
        // Add first item
        service.addFoodItem(sampleFoodItem1)
        #expect(service.currentMeal.count == 1)
        #expect(service.isBuilding == true)
        #expect(service.currentMeal.first?.name == "Grilled Chicken")
        
        // Add second item
        service.addFoodItem(sampleFoodItem2)
        #expect(service.currentMeal.count == 2)
        #expect(service.isBuilding == true)
    }
    
    @Test @MainActor func testMealBuilderServiceRemoveFoodItem() async throws {
        let service = MealBuilderService()
        
        // Add items first
        service.addFoodItem(sampleFoodItem1)
        service.addFoodItem(sampleFoodItem2)
        #expect(service.currentMeal.count == 2)
        
        // Remove first item
        service.removeFoodItem(sampleFoodItem1)
        #expect(service.currentMeal.count == 1)
        #expect(service.currentMeal.first?.name == "Brown Rice")
        #expect(service.isBuilding == true)
        
        // Remove last item
        service.removeFoodItem(sampleFoodItem2)
        #expect(service.currentMeal.isEmpty)
        #expect(service.isBuilding == false)
    }
    
    @Test @MainActor func testMealBuilderServiceUpdateFoodItem() async throws {
        let service = MealBuilderService()
        
        // Add item
        service.addFoodItem(sampleFoodItem1)
        #expect(service.currentMeal.count == 1)
        
        // Update item
        var updatedItem = sampleFoodItem1
        updatedItem.quantity = "2 breasts (12 oz)"
        updatedItem.nutrition.calories = 460
        
        service.updateFoodItem(updatedItem)
        #expect(service.currentMeal.count == 1)
        #expect(service.currentMeal.first?.quantity == "2 breasts (12 oz)")
        #expect(service.currentMeal.first?.nutrition.calories == 460)
    }
    
    @Test @MainActor func testMealBuilderServiceNutritionTotals() async throws {
        let service = MealBuilderService()
        
        // Add items
        service.addFoodItem(sampleFoodItem1)
        service.addFoodItem(sampleFoodItem2)
        
        let totals = service.totalNutrition
        
        // Verify totals are calculated correctly
        #expect(totals.calories == 446) // 230 + 216
        #expect(totals.protein == 48.0) // 43.0 + 5.0
        #expect(totals.carbs == 45.0)   // 0.0 + 45.0  
        #expect(totals.fat == 6.8)      // 5.0 + 1.8
    }
    
    @Test @MainActor func testMealBuilderServiceClearMeal() async throws {
        let service = MealBuilderService()
        
        // Add items and set some properties
        service.addFoodItem(sampleFoodItem1)
        service.mealName = "Test Meal"
        service.notes = "Test Notes"
        
        #expect(service.currentMeal.count == 1)
        #expect(service.isBuilding == true)
        #expect(service.mealName == "Test Meal")
        #expect(service.notes == "Test Notes")
        
        // Clear meal
        service.clearMeal()
        
        #expect(service.currentMeal.isEmpty)
        #expect(service.isBuilding == false)
        #expect(service.mealName.isEmpty)
        #expect(service.notes.isEmpty)
    }
    
    @Test @MainActor func testMealBuilderServiceHasUnsavedChanges() async throws {
        let service = MealBuilderService()
        
        // Initially no changes
        #expect(service.hasUnsavedChanges == false)
        
        // Add food item
        service.addFoodItem(sampleFoodItem1)
        #expect(service.hasUnsavedChanges == true)
        
        // Clear and add name only
        service.clearMeal()
        service.mealName = "Test"
        #expect(service.hasUnsavedChanges == true)
        
        // Clear and add notes only
        service.clearMeal()
        service.notes = "Test note"
        #expect(service.hasUnsavedChanges == true)
    }
    
    @Test @MainActor func testCartLikeInterface() async throws {
        let service = MealBuilderService()
        
        // Test cart-like functionality
        #expect(service.currentMeal.isEmpty, "Cart should start empty")
        
        // Add items to cart
        service.addFoodItem(sampleFoodItem1)
        service.addFoodItem(sampleFoodItem2)
        
        // Verify cart state
        #expect(service.currentMeal.count == 2, "Cart should contain 2 items")
        #expect(service.hasUnsavedChanges, "Cart should have unsaved changes")
        
        // Test nutrition summary (like cart totals)
        let nutrition = service.totalNutrition
        #expect(nutrition.calories == 446, "Cart should show total calories")
        
        // Test remove from cart
        service.removeFoodItem(sampleFoodItem1)
        #expect(service.currentMeal.count == 1, "Cart should have 1 item after removal")
        
        // Test clear cart
        service.clearMeal()
        #expect(service.currentMeal.isEmpty, "Cart should be empty after clearing")
        #expect(!service.hasUnsavedChanges, "Cart should have no unsaved changes after clearing")
    }
}