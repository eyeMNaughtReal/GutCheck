//
//  FoodDetailService.swift  
//  GutCheck
//
//  Unified service for food detail presentation across the app

import SwiftUI

/// Unified service managing food detail presentation modes and configurations
@MainActor
class FoodDetailService: ObservableObject {
    static let shared = FoodDetailService()
    
    /// Current food item being viewed
    @Published var currentFoodItem: FoodItem?
    
    /// Navigation state for food detail flows
    @Published var showingFoodDetail = false
    @Published var showingNutritionDetails = false
    @Published var showingIngredients = false
    @Published var showingAllergens = false
    
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
}

/// Configuration for food detail presentation
struct FoodDetailConfig {
    let style: FoodDetailStyle
    let showAddToMeal: Bool
    let allowEditing: Bool
    let showServingControls: Bool
    let showDetailedSections: Bool
    
    static func config(for style: FoodDetailStyle) -> FoodDetailConfig {
        switch style {
        case .compact:
            return FoodDetailConfig(
                style: .compact,
                showAddToMeal: false,
                allowEditing: false,
                showServingControls: false,
                showDetailedSections: false
            )
        case .standard:
            return FoodDetailConfig(
                style: .standard,
                showAddToMeal: true,
                allowEditing: false,
                showServingControls: true,
                showDetailedSections: true
            )
        case .full:
            return FoodDetailConfig(
                style: .full,
                showAddToMeal: true,
                allowEditing: true,
                showServingControls: true,
                showDetailedSections: true
            )
        case .nutrition:
            return FoodDetailConfig(
                style: .nutrition,
                showAddToMeal: false,
                allowEditing: false,
                showServingControls: false,
                showDetailedSections: false
            )
        }
    }
}
