//
//  MealRiskSnapshot.swift
//  GutCheck
//
//  Persisted record of the risk assessment a meal was given when it was logged.
//

import Foundation

// MARK: - Meal Risk Snapshot

/// What the app told the user about a meal's risk at the moment they saved it.
///
/// This is deliberately a *snapshot* rather than something recomputed when the
/// meal is read back. Both inputs to the assessment move underneath us: the
/// compound database grows with every release, and the user's trigger patterns
/// shift as they log more symptoms. Recomputing would silently rewrite history —
/// a meal the user was warned about could later read as safe, which is precisely
/// the record you want intact when correlating meals against symptoms.
///
/// `schemaVersion` is the escape hatch. It marks which assessment the snapshot
/// came from, so a future release that wants to re-score old meals can tell
/// stale snapshots from current ones instead of guessing.
///
/// The domain types (`TriggerPattern`, `FoodCompound`) are intentionally *not*
/// stored wholesale. They are live analysis models and change shape freely; a
/// historical record that decodes only while those types stand still is not a
/// record. Everything needed to redraw the assessment is flattened out here.
struct MealRiskSnapshot: Codable, Hashable {

    /// Bump when the meaning of a stored field changes, not merely when a field
    /// is added — added fields decode as nil on old records already.
    static let currentSchemaVersion = 1

    let schemaVersion: Int

    /// `nil` when nothing in the meal could be assessed. Following the same rule
    /// as `Meal.nutrition`: absence of data is stored as absence, never as a
    /// zero, so a meal the app knew nothing about can't read back as a safe 0.
    let overallRiskScore: Int?

    /// Stored raw so an unrecognised value from a newer build degrades to
    /// `.unknown` rather than failing the whole decode — matching how
    /// `StoredMeal` keeps `typeRawValue`.
    let overallRiskLevelRawValue: String

    let overallExplanation: String
    let assessedAt: Date
    let hasHistoricalData: Bool
    let foodItemRisks: [FoodItemRiskSnapshot]

    var overallRiskLevel: MealRiskLevel {
        // Unknown, not low. An unreadable level means we don't know what the
        // user was told, which is not the same as having told them it was fine.
        MealRiskLevel(rawValue: overallRiskLevelRawValue) ?? .unknown
    }
}

// MARK: - Food Item Risk Snapshot

/// The persisted form of a single `FoodItemRiskDetail`.
struct FoodItemRiskSnapshot: Codable, Hashable {
    /// Carried over from the live detail so re-rendering the same snapshot
    /// keeps stable `ForEach` identity instead of churning on every read.
    let id: UUID

    let foodName: String

    /// `nil` when the item could not be assessed. See `MealRiskSnapshot`.
    let riskScore: Int?

    let riskLevelRawValue: String
    let explanation: String
    let dataSourceRawValue: String

    /// Names only. The full `FoodCompound` records live in a database that is
    /// edited between releases; the names are what the user actually read.
    let flaggedCompoundNames: [String]

    /// The food whose history matched, when the score came from the user's own
    /// data. Nil for compound-only or unassessed items.
    let matchedTriggerFoodName: String?

    var riskLevel: MealRiskLevel {
        MealRiskLevel(rawValue: riskLevelRawValue) ?? .unknown
    }

    var dataSource: RiskDataSource {
        // An unreadable source means we can't claim an analysis ran.
        RiskDataSource(rawValue: dataSourceRawValue) ?? .insufficientData
    }
}

// MARK: - Capture

extension FoodItemRiskSnapshot {
    init(_ detail: FoodItemRiskDetail) {
        self.init(
            id: detail.id,
            foodName: detail.foodName,
            // The live model represents "unassessed" as score 0 with level
            // `.unknown`; the stored form drops the 0 so the distinction does
            // not depend on a reader remembering to check the level first.
            riskScore: detail.riskLevel == .unknown ? nil : detail.riskScore,
            riskLevelRawValue: detail.riskLevel.rawValue,
            explanation: detail.explanation,
            dataSourceRawValue: detail.dataSource.rawValue,
            flaggedCompoundNames: detail.flaggedCompounds.map(\.name),
            matchedTriggerFoodName: detail.matchedTriggerPattern?.foodName
        )
    }
}

extension MealRiskSnapshot {
    init(_ assessment: MealRiskAssessment) {
        self.init(
            schemaVersion: Self.currentSchemaVersion,
            overallRiskScore: assessment.overallRiskLevel == .unknown ? nil : assessment.overallRiskScore,
            overallRiskLevelRawValue: assessment.overallRiskLevel.rawValue,
            overallExplanation: assessment.overallExplanation,
            assessedAt: assessment.assessedAt,
            hasHistoricalData: assessment.hasHistoricalData,
            foodItemRisks: assessment.foodItemRisks.map(FoodItemRiskSnapshot.init)
        )
    }
}

// MARK: - Replay

extension MealRiskSnapshot {
    /// Rebuilds the assessment for display, so meal history renders through the
    /// same `MealRiskAssessmentCard` the meal builder uses.
    ///
    /// `matchedTriggerPattern` comes back nil: the full pattern is not stored,
    /// and reconstructing one from today's history would be exactly the silent
    /// rewrite this type exists to prevent. The card reads `dataSource` to
    /// decide whether to show the "from your history" marker, so nothing in the
    /// rendering depends on the pattern itself.
    var assessment: MealRiskAssessment {
        MealRiskAssessment(
            overallRiskScore: overallRiskScore ?? 0,
            overallRiskLevel: overallRiskLevel,
            foodItemRisks: foodItemRisks.map { snapshot in
                FoodItemRiskDetail(
                    id: snapshot.id,
                    foodName: snapshot.foodName,
                    riskScore: snapshot.riskScore ?? 0,
                    riskLevel: snapshot.riskLevel,
                    explanation: snapshot.explanation,
                    matchedTriggerPattern: nil,
                    flaggedCompounds: [],
                    dataSource: snapshot.dataSource
                )
            },
            overallExplanation: overallExplanation,
            assessedAt: assessedAt,
            hasHistoricalData: hasHistoricalData
        )
    }
}
