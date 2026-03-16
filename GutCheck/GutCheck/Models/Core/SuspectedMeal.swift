import Foundation

/// A food item within a SuspectedMeal that has been flagged as a potential trigger.
struct SuspectedFood: Identifiable, Hashable {
    let id: UUID
    let foodItem: FoodItem
    let triggerScore: Int           // 0-100 individual food score
    let compoundRisks: [String]     // e.g. ["Lactose", "Casein"]
    let reason: String              // human-readable explanation
}

/// Represents a meal that was eaten 6-24 hours before a selected symptom,
/// along with its computed trigger likelihood.
struct SuspectedMeal: Identifiable, Hashable {
    let id: UUID
    let meal: Meal
    let timeBefore: Double          // hours before the symptom
    let triggerLikelihood: Int      // 0-100 composite score
    let suspectedFoods: [SuspectedFood]

    /// Human-readable time gap, e.g. "8.2 hours before"
    var timeBeforeFormatted: String {
        String(format: "%.1f hours before", timeBefore)
    }
}
