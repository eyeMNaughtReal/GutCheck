//
//  FoodDetailService.swift  
//  GutCheck
//
//  Unified service for food detail presentation across the app

import SwiftUI

/// Unified service managing food detail presentation modes and configurations
@MainActor
@Observable class FoodDetailService {
    static let shared = FoodDetailService()
    
    /// Current food item being viewed
    var currentFoodItem: FoodItem?
    
    /// Navigation state for food detail flows
    var showingFoodDetail = false
    var showingNutritionDetails = false
    var showingIngredients = false
    var showingAllergens = false
    
    private init() {}
    
    /// Present food item in appropriate detail view
    func presentFoodDetail(_ foodItem: FoodItem, style: FoodDetailStyle = .full) {
        currentFoodItem = foodItem
        showingFoodDetail = true
    }
    
    /// Clear current food detail state
    func clearFoodDetail() {
        currentFoodItem = nil
        showingFoodDetail = false
        showingNutritionDetails = false
        showingIngredients = false
        showingAllergens = false
    }
}

/// Different presentation styles for food details
enum FoodDetailStyle {
    case compact        // Simple row for lists
    case standard       // Standard detail view
    case full          // Full detail with editing capabilities
    case nutrition     // Focus on nutrition information
    case readOnly      // Full detail for an already-logged item: look, don't touch
}

/// Configuration for food detail presentation
struct FoodDetailConfig {
    let style: FoodDetailStyle
    let showAddToMeal: Bool
    let allowEditing: Bool
    let showServingControls: Bool
    let showDetailedSections: Bool
    let showCancelButton: Bool  // Add this property
    
    static func config(for style: FoodDetailStyle) -> FoodDetailConfig {
        switch style {
        case .compact:
            return FoodDetailConfig(
                style: .compact,
                showAddToMeal: false,
                allowEditing: false,
                showServingControls: false,
                showDetailedSections: false,
                showCancelButton: false  // Compact views in navigation shouldn't show cancel
            )
        case .standard:
            return FoodDetailConfig(
                style: .standard,
                showAddToMeal: true,
                allowEditing: false,
                showServingControls: true,
                showDetailedSections: true,
                showCancelButton: false  // Standard views in navigation shouldn't show cancel
            )
        case .full:
            return FoodDetailConfig(
                style: .full,
                showAddToMeal: true,
                allowEditing: true,
                showServingControls: true,
                showDetailedSections: true,
                showCancelButton: true  // Full views might be presented modally
            )
        case .nutrition:
            return FoodDetailConfig(
                style: .nutrition,
                showAddToMeal: false,
                allowEditing: false,
                showServingControls: false,
                showDetailedSections: false,
                showCancelButton: false  // Nutrition views typically in navigation
            )
        case .readOnly:
            // Viewing an item on a meal already in history. Ingredients and
            // allergens are the point of opening it, so the detail sections
            // stay; adding it to the meal being built, or re-scaling a serving
            // that was already eaten, are not offered.
            return FoodDetailConfig(
                style: .readOnly,
                showAddToMeal: false,
                allowEditing: false,
                showServingControls: false,
                showDetailedSections: true,
                showCancelButton: true  // Presented as a sheet from meal details
            )
        }
    }
}
