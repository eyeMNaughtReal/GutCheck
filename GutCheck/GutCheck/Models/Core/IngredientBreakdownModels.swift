//
//  IngredientBreakdownModels.swift
//  GutCheck
//
//  Models for AI-powered ingredient breakdown from food names

import Foundation
import SwiftUI

// MARK: - Dietary Tag

/// Tags that categorize dietary properties of a food item
enum DietaryTag: String, CaseIterable, Codable, Hashable {
    case gluten
    case dairy
    case highFat
    case highSugar
    case highSodium
    case nightshade
    case fermented
    case caffeine
    case nuts
    case shellfish
    case eggs
    case soy
    case highFiber
    case spicy
    
    var displayName: String {
        switch self {
        case .gluten: return "Gluten"
        case .dairy: return "Dairy"
        case .highFat: return "High Fat"
        case .highSugar: return "High Sugar"
        case .highSodium: return "High Sodium"
        case .nightshade: return "Nightshade"
        case .fermented: return "Fermented"
        case .caffeine: return "Caffeine"
        case .nuts: return "Nuts"
        case .shellfish: return "Shellfish"
        case .eggs: return "Eggs"
        case .soy: return "Soy"
        case .highFiber: return "High Fiber"
        case .spicy: return "Spicy"
        }
    }
    
    var icon: String {
        switch self {
        case .gluten: return "allergens"
        case .dairy: return "drop.fill"
        case .highFat: return "drop.circle.fill"
        case .highSugar: return "drop.triangle.fill"
        case .highSodium: return "bolt.fill"
        case .nightshade: return "leaf.fill"
        case .fermented: return "bubbles.and.sparkles.fill"
        case .caffeine: return "cup.and.saucer.fill"
        case .nuts: return "allergens"
        case .shellfish: return "allergens"
        case .eggs: return "allergens"
        case .soy: return "leaf.fill"
        case .highFiber: return "leaf.arrow.circlepath"
        case .spicy: return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .gluten: return .orange
        case .dairy: return .blue
        case .highFat: return .purple
        case .highSugar: return .pink
        case .highSodium: return .indigo
        case .nightshade: return .red
        case .fermented: return .teal
        case .caffeine: return .brown
        case .nuts: return .orange
        case .shellfish: return .red
        case .eggs: return .yellow
        case .soy: return .green
        case .highFiber: return .mint
        case .spicy: return .red
        }
    }
}

// MARK: - Breakdown Confidence

/// How confident the analysis is in its ingredient breakdown
enum BreakdownConfidence: String, Hashable, Comparable {
    case high       // Composite food match + API ingredients
    case medium     // Composite food or ingredient mapping match
    case low        // Name inference only
    case none       // No data found
    
    private var sortOrder: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        case .none: return 0
        }
    }
    
    static func < (lhs: BreakdownConfidence, rhs: BreakdownConfidence) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Ingredient Breakdown

/// Result of analyzing a food name for its ingredients, allergens, and dietary tags
struct IngredientBreakdown: Hashable {
    let inferredIngredients: [String]
    let detectedAllergens: [String]
    let dietaryTags: [DietaryTag]
    let flaggedCompounds: [FoodCompound]
    let confidence: BreakdownConfidence
    let foodDescription: String?
    
    static let empty = IngredientBreakdown(
        inferredIngredients: [],
        detectedAllergens: [],
        dietaryTags: [],
        flaggedCompounds: [],
        confidence: .none,
        foodDescription: nil
    )
}
