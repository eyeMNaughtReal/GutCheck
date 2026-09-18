import Testing
import Foundation
@testable import GutCheck

/// Tests for the dashboard's derived state: health score, focus message,
/// avoidance tip, trigger alerts and the AI insight summary.
///
/// These previously drove the store through `loadDataForSelectedDate()`, which
/// clears `todaysMeals`/`todaysSymptoms` and starts an async reload before it
/// computes anything. Every test that populated data and called it was really
/// asserting against an empty store, so nine of them could never pass. They now
/// set the data and call `recomputeDerivedState()`, which is the derivation step
/// on its own.
@MainActor
struct DashboardDataStoreTests {

    // MARK: - Test Helpers

    private func makeMeal(
        id: String = UUID().uuidString,
        name: String = "Test Meal",
        date: Date = Date.now,
        type: MealType = .lunch,
        foodItems: [FoodItem] = []
    ) -> Meal {
        Meal(id: id, name: name, date: date, type: type, source: .manual, foodItems: foodItems)
    }

    private func makeSymptom(
        id: String = UUID().uuidString,
        date: Date = Date.now,
        stoolType: StoolType = .type4,
        painLevel: PainLevel = .none,
        urgencyLevel: UrgencyLevel = .none
    ) -> Symptom {
        Symptom(id: id, date: date, stoolType: stoolType, painLevel: painLevel, urgencyLevel: urgencyLevel, createdBy: "test-user")
    }

    /// A store with no repository access, seeded with the given data.
    ///
    /// `preview: true` keeps the initializer from hitting the real repositories
    /// and suppresses on-device narration, so `aiInsightSummary` stays at the
    /// deterministic value under test.
    private func makeStore(
        meals: [Meal] = [],
        symptoms: [Symptom] = []
    ) -> DashboardDataStore {
        let store = DashboardDataStore(preview: true)
        store.todaysMeals = meals
        store.todaysSymptoms = symptoms
        return store
    }

    // MARK: - Preview Initialization

    @Test("Preview init loads mock data")
    func previewInitLoadsMockData() {
        let store = DashboardDataStore(preview: true)

        #expect(store.todaysMeals.count == 2)
        #expect(store.todaysSymptoms.isEmpty)
        #expect(store.todaysHealthScore == 8)
        #expect(!store.todaysFocus.isEmpty)
        #expect(!store.avoidanceTip.isEmpty)
    }

    // MARK: - Health Score Calculation
    //
    // Score = base 7, +2 if no symptoms (else a penalty by average severity),
    // +1 for 2 or more meals, clamped to 1...10. Severity per symptom is
    // painLevel.rawValue + urgencyLevel.rawValue, each 0...3.

    @Test("Health score is 9 with no symptoms and fewer than 2 meals")
    func healthScoreNoSymptomsFewMeals() {
        let store = makeStore(meals: [], symptoms: [])

        store.recomputeDerivedState()

        // 7 base + 2 (no symptoms) = 9
        #expect(store.todaysHealthScore == 9)
    }

    @Test("Health score is 10 with no symptoms and 2+ meals")
    func healthScoreNoSymptomsWithMeals() {
        let store = makeStore(meals: [makeMeal(), makeMeal()], symptoms: [])

        store.recomputeDerivedState()

        // 7 base + 2 (no symptoms) + 1 (2+ meals) = 10
        #expect(store.todaysHealthScore == 10)
    }

    @Test("Health score decreases with symptoms")
    func healthScoreWithSymptoms() {
        let store = makeStore(
            meals: [],
            symptoms: [makeSymptom(painLevel: .severe, urgencyLevel: .urgent)]
        )

        store.recomputeDerivedState()

        // severity 3 + 3 = 6, average 6 → -3. 7 base - 3 = 4
        #expect(store.todaysHealthScore == 4)
    }

    @Test("Health score with mild symptoms")
    func healthScoreMildSymptoms() {
        let store = makeStore(
            meals: [makeMeal(), makeMeal()],
            symptoms: [makeSymptom(painLevel: .mild, urgencyLevel: .none)]
        )

        store.recomputeDerivedState()

        // severity 1 + 0 = 1, average 1 → -1. 7 base - 1 + 1 (2+ meals) = 7
        #expect(store.todaysHealthScore == 7)
    }

    // MARK: - Insights Generation

    @Test("Generates positive focus with no symptoms and meals")
    func positiveInsightsNoSymptoms() {
        let store = makeStore(meals: [makeMeal(), makeMeal()], symptoms: [])

        store.recomputeDerivedState()

        #expect(store.todaysFocus.contains("Great day"))
    }

    @Test("Generates gentle focus message with symptoms")
    func warningInsightsWithSymptoms() {
        let store = makeStore(meals: [makeMeal()], symptoms: [makeSymptom(painLevel: .moderate)])

        store.recomputeDerivedState()

        #expect(store.todaysFocus.contains("gentle foods"))
    }

    @Test("Generates no-meals focus when no symptoms and no meals")
    func noMealsFocus() {
        let store = makeStore(meals: [], symptoms: [])

        store.recomputeDerivedState()

        #expect(store.todaysFocus.contains("feeling good"))
    }

    // MARK: - AI Insight Generation

    @Test("AI insight is positive when no symptoms and meals present")
    func aiInsightPositive() {
        let store = makeStore(meals: [makeMeal(), makeMeal()], symptoms: [])

        store.recomputeDerivedState()

        #expect(store.aiInsightSeverity == .positive)
        #expect(store.aiInsightSummary.contains("No triggers"))
    }

    @Test("AI insight flags elevated symptoms at moderate pain or worse")
    func aiInsightWarningHighPain() {
        let store = makeStore(meals: [makeMeal()], symptoms: [makeSymptom(painLevel: .severe)])

        store.recomputeDerivedState()

        // The elevated-symptom branch compares against PainLevel cases. It used
        // to test `painLevel.rawValue >= 7` against a 0...3 enum, so it was
        // unreachable and severe pain fell through to the generic
        // "possible trigger" message instead.
        #expect(store.aiInsightSeverity == .warning)
        #expect(store.aiInsightSummary.contains("Elevated symptoms"))
    }

    @Test("Mild pain does not reach the elevated-symptom branch")
    func aiInsightMildPainIsNotElevated() {
        let store = makeStore(meals: [makeMeal()], symptoms: [makeSymptom(painLevel: .mild)])

        store.recomputeDerivedState()

        #expect(store.aiInsightSeverity == .warning)
        #expect(store.aiInsightSummary.contains("Possible trigger"))
    }

    @Test("AI insight is neutral when no data")
    func aiInsightNeutralNoData() {
        let store = makeStore(meals: [], symptoms: [])

        store.recomputeDerivedState()

        #expect(store.aiInsightSeverity == .neutral)
    }

    // MARK: - Trigger Alerts

    @Test("Trigger alert for 3+ symptoms")
    func triggerAlertMultipleSymptoms() {
        let store = makeStore(
            meals: [],
            symptoms: [
                makeSymptom(painLevel: .mild),
                makeSymptom(painLevel: .moderate),
                makeSymptom(painLevel: .severe)
            ]
        )

        store.recomputeDerivedState()

        #expect(store.triggerAlerts.contains(where: { $0.contains("Multiple symptoms") }))
    }

    @Test("Severe pain raises the healthcare provider alert")
    func triggerAlertSeverePain() {
        let store = makeStore(meals: [], symptoms: [makeSymptom(painLevel: .severe)])

        store.recomputeDerivedState()

        #expect(store.triggerAlerts.contains(where: { $0.contains("High pain level") }))
    }

    @Test("Moderate pain does not raise the healthcare provider alert")
    func noSevereAlertForModeratePain() {
        let store = makeStore(meals: [], symptoms: [makeSymptom(painLevel: .moderate)])

        store.recomputeDerivedState()

        #expect(!store.triggerAlerts.contains(where: { $0.contains("High pain level") }))
    }

    @Test("Avoidance tip set when symptoms present")
    func avoidanceTipWithSymptoms() {
        let store = makeStore(meals: [], symptoms: [makeSymptom(painLevel: .mild)])

        store.recomputeDerivedState()

        #expect(!store.avoidanceTip.isEmpty)
        #expect(store.avoidanceTip.contains("Monitor"))
    }

    @Test("Moderate pain or worse gets the high-pain avoidance tip")
    func avoidanceTipHighPain() {
        let store = makeStore(meals: [], symptoms: [makeSymptom(painLevel: .moderate)])

        store.recomputeDerivedState()

        #expect(store.avoidanceTip.contains("high pain levels"))
    }

    @Test("No trigger alerts when few symptoms")
    func noTriggerAlertsWithFewSymptoms() {
        let store = makeStore(meals: [], symptoms: [makeSymptom(painLevel: .mild)])

        store.recomputeDerivedState()

        #expect(!store.triggerAlerts.contains(where: { $0.contains("Multiple symptoms") }))
    }
}
