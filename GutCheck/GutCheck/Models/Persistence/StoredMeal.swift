//
//  StoredMeal.swift
//  GutCheck
//
//  SwiftData entity backing the `Meal` domain struct.
//

import Foundation
import SwiftData

@Model
final class StoredMeal {
    /// Matches `Meal.id`. Unique so a re-save of the same meal updates the row
    /// rather than inserting a duplicate.
    @Attribute(.unique) var id: String

    var name: String
    var date: Date

    /// Enum raw values are stored rather than the enums themselves so
    /// `#Predicate` can filter on them and an unrecognised value from an older
    /// build degrades to a default instead of failing to load the row.
    var typeRawValue: String
    var sourceRawValue: String

    var notes: String?
    var tags: [String]
    var createdBy: String

    /// When the record was written, as distinct from `date` (when the meal was
    /// eaten).
    var createdAt: Date
    var updatedAt: Date

    /// JSON-encoded `[FoodItem]`. Held externally because a meal with a long
    /// ingredient breakdown can run to several kilobytes.
    @Attribute(.externalStorage) var foodItemsData: Data

    init(
        id: String,
        name: String,
        date: Date,
        typeRawValue: String,
        sourceRawValue: String,
        notes: String?,
        tags: [String],
        createdBy: String,
        createdAt: Date,
        updatedAt: Date,
        foodItemsData: Data
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.typeRawValue = typeRawValue
        self.sourceRawValue = sourceRawValue
        self.notes = notes
        self.tags = tags
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.foodItemsData = foodItemsData
    }
}

// MARK: - Domain mapping

extension StoredMeal {
    convenience init(_ meal: Meal) {
        self.init(
            id: meal.id,
            name: meal.name,
            date: meal.date,
            typeRawValue: meal.type.rawValue,
            sourceRawValue: meal.source.rawValue,
            notes: meal.notes,
            tags: meal.tags,
            createdBy: meal.createdBy,
            createdAt: meal.createdAt,
            updatedAt: meal.updatedAt,
            foodItemsData: PersistenceCoding.encode(meal.foodItems)
        )
    }

    /// Applies an edited meal onto the existing row.
    ///
    /// `createdAt` is deliberately not overwritten — it records when the meal
    /// was first logged, and an edit should not rewrite that.
    func apply(_ meal: Meal) {
        name = meal.name
        date = meal.date
        typeRawValue = meal.type.rawValue
        sourceRawValue = meal.source.rawValue
        notes = meal.notes
        tags = meal.tags
        createdBy = meal.createdBy
        updatedAt = Date.now
        foodItemsData = PersistenceCoding.encode(meal.foodItems)
    }

    var domainModel: Meal {
        var meal = Meal(
            id: id,
            name: name,
            date: date,
            type: MealType(rawValue: typeRawValue) ?? .lunch,
            source: MealSource(rawValue: sourceRawValue) ?? .manual,
            foodItems: PersistenceCoding.decode([FoodItem].self, from: foodItemsData) ?? [],
            notes: notes,
            tags: tags,
            createdBy: createdBy
        )
        meal.createdAt = createdAt
        meal.updatedAt = updatedAt
        return meal
    }
}
