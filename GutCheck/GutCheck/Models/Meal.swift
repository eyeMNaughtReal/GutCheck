//
//  Meal.swift
//  GutCheck
//

import Foundation

enum MealType: String, Codable, CaseIterable {
    case breakfast, lunch, dinner, snack, drink
}

enum MealSource: String, Codable {
    case manual, barcode, lidar, ai
}

// MARK: - Per-Meal Nutrition
extension Meal {
    /// Nutrition summed across this meal's food items.
    /// Fields stay nil when nothing contributed, so the UI can tell
    /// "no data" apart from a genuine zero.
    var nutrition: NutritionInfo {
        var calories = 0
        var protein = 0.0, carbs = 0.0, fat = 0.0
        var fiber = 0.0, sugar = 0.0, sodium = 0.0

        for item in foodItems {
            calories += item.nutrition.calories ?? 0
            protein  += item.nutrition.protein  ?? 0
            carbs    += item.nutrition.carbs    ?? 0
            fat      += item.nutrition.fat      ?? 0
            fiber    += item.nutrition.fiber    ?? 0
            sugar    += item.nutrition.sugar    ?? 0
            sodium   += item.nutrition.sodium   ?? 0
        }

        return NutritionInfo(
            calories: calories > 0 ? calories : nil,
            protein:  protein  > 0 ? protein  : nil,
            carbs:    carbs    > 0 ? carbs    : nil,
            fat:      fat      > 0 ? fat      : nil,
            fiber:    fiber    > 0 ? fiber    : nil,
            sugar:    sugar    > 0 ? sugar    : nil,
            sodium:   sodium   > 0 ? sodium   : nil
        )
    }
}

struct Meal: Identifiable, Codable, Hashable, Equatable, LocalRecord {
    var id: String = UUID().uuidString
    var name: String
    var date: Date
    var type: MealType
    var source: MealSource
    var foodItems: [FoodItem]
    var notes: String?
    var tags: [String] = []
    var createdBy: String = ""

    /// When the record was written, as distinct from `date` (when the meal was
    /// eaten). Sync conflict resolution orders on these, matching Symptom.
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    // MARK: - Privacy Classification

    /// How sensitive this meal is. Everything is stored on-device, so this no
    /// longer decides *where* the record goes — it marks which entries carry
    /// free-text or personal detail, which the healthcare export uses to decide
    /// what may leave the device.
    var privacyLevel: DataPrivacyLevel {
        // Personal notes and detailed observations are private
        if let notes = notes, !notes.isEmpty {
            return .private
        }
        
        // Location-based meals are private
        if tags.contains("location") || tags.contains("personal") {
            return .private
        }
        
        // Basic meal structure and nutrition is non-private
        return .public
    }

    // MARK: - Initializers
    
    init(id: String = UUID().uuidString,
         name: String,
         date: Date,
         type: MealType,
         source: MealSource,
         foodItems: [FoodItem],
         notes: String? = nil,
         tags: [String] = [],
         createdBy: String = "") {
        self.id = id
        self.name = name
        self.date = date
        self.type = type
        self.source = source
        self.foodItems = foodItems
        self.notes = notes
        self.tags = tags
        self.createdBy = createdBy
    }
}

