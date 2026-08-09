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

    /// JSON-encoded `MealRiskSnapshot`, or nil when the meal carries no
    /// assessment.
    ///
    /// Optional on purpose. Every row written before this property existed has
    /// no value for it, and SwiftData's lightweight migration can only add a new
    /// attribute without a rewrite if it is optional — a non-optional `Data`
    /// would need a default that then reads back as "an assessment happened and
    /// found nothing", which is the confusion this whole feature is fixing.
    var riskSnapshotData: Data?

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
        foodItemsData: Data,
        riskSnapshotData: Data? = nil
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
        self.riskSnapshotData = riskSnapshotData
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
            foodItemsData: PersistenceCoding.encode(meal.foodItems),
            riskSnapshotData: meal.riskSnapshot.map(PersistenceCoding.encode)
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
        // Overwritten rather than merged: the snapshot describes a specific set
        // of food items, and an edit that changed them would leave a retained
        // old snapshot explaining food the meal no longer contains. Callers that
        // edit a meal recompute; callers that round-trip one carry it through.
        riskSnapshotData = meal.riskSnapshot.map(PersistenceCoding.encode)
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
            createdBy: createdBy,
            // Stays nil for meals logged before risk was recorded, and for a
            // snapshot that no longer decodes — both mean "no assessment on
            // file", which the UI shows as such rather than as a clean bill.
            riskSnapshot: riskSnapshotData.flatMap {
                PersistenceCoding.decode(MealRiskSnapshot.self, from: $0)
            }
        )
        meal.createdAt = createdAt
        meal.updatedAt = updatedAt
        return meal
    }
}
