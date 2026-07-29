import Testing
import Foundation
@testable import GutCheck

/// Covers the scoring rules shared by the dashboard, App Intents and the
/// widgets, plus the App Group snapshot they are delivered through.
struct HealthScoreAndWidgetTests {

    // MARK: - Helpers

    private func makeMeal(
        id: String = UUID().uuidString,
        name: String = "Test Meal",
        date: Date = Date.now
    ) -> Meal {
        Meal(id: id, name: name, date: date, type: .lunch, source: .manual, foodItems: [])
    }

    private func makeSymptom(
        painLevel: PainLevel = .none,
        urgencyLevel: UrgencyLevel = .none
    ) -> Symptom {
        Symptom(
            date: Date.now,
            stoolType: .type4,
            painLevel: painLevel,
            urgencyLevel: urgencyLevel,
            createdBy: "test-user"
        )
    }

    // MARK: - Calculator

    @Test("No symptoms and no meals scores 9")
    func scoreNoSymptomsNoMeals() {
        #expect(HealthScoreCalculator.score(meals: [], symptoms: []) == 9)
    }

    @Test("No symptoms with two meals scores 10")
    func scoreNoSymptomsTwoMeals() {
        let meals = [makeMeal(), makeMeal()]
        #expect(HealthScoreCalculator.score(meals: meals, symptoms: []) == 10)
    }

    @Test("Severe symptom drops the score")
    func scoreSevereSymptom() {
        // pain 3 + urgency 3 = 6 average → -3 from the base 7
        let symptoms = [makeSymptom(painLevel: .severe, urgencyLevel: .urgent)]
        #expect(HealthScoreCalculator.score(meals: [], symptoms: symptoms) == 4)
    }

    @Test("Mild symptom with meals scores 7")
    func scoreMildSymptom() {
        let meals = [makeMeal(), makeMeal()]
        let symptoms = [makeSymptom(painLevel: .mild)]
        #expect(HealthScoreCalculator.score(meals: meals, symptoms: symptoms) == 7)
    }

    @Test("Descriptors band the 1-10 range")
    func descriptorBanding() {
        #expect(HealthScoreCalculator.descriptor(for: 10) == "great")
        #expect(HealthScoreCalculator.descriptor(for: 7) == "good")
        #expect(HealthScoreCalculator.descriptor(for: 5) == "fair")
        #expect(HealthScoreCalculator.descriptor(for: 1) == "rough")
    }

    // MARK: - Snapshot

    @Test("Snapshot clamps out-of-range scores")
    func snapshotClampsScore() {
        #expect(WidgetSnapshot(healthScore: 42).healthScore == 10)
        #expect(WidgetSnapshot(healthScore: -3).healthScore == 1)
    }

    @Test("Trend compares against the previous score")
    func snapshotTrend() {
        #expect(WidgetSnapshot(healthScore: 8, previousScore: 6).trend == .up)
        #expect(WidgetSnapshot(healthScore: 5, previousScore: 7).trend == .down)
        #expect(WidgetSnapshot(healthScore: 7, previousScore: 7).trend == .steady)
        // Nothing to compare against yet
        #expect(WidgetSnapshot(healthScore: 7).trend == .steady)
    }

    @Test("Score fraction maps to the gauge range")
    func snapshotFraction() {
        #expect(WidgetSnapshot(healthScore: 10).scoreFraction == 1.0)
        #expect(WidgetSnapshot(healthScore: 5).scoreFraction == 0.5)
    }

    // MARK: - Store

    @Test("Snapshot survives a save/load round trip")
    func storeRoundTrip() throws {
        let suiteName = "com.gutcheck.tests.widgets.\(UUID().uuidString)"
        let store = WidgetDataStore(suiteName: suiteName)
        defer {
            store.clear()
            UserDefaults().removePersistentDomain(forName: suiteName)
        }

        let snapshot = WidgetSnapshot(
            healthScore: 8,
            previousScore: 6,
            lastMealName: "Oatmeal",
            lastMealDate: Date(timeIntervalSince1970: 1_700_000_000),
            nextReminderTitle: "Lunch",
            nextReminderDate: Date(timeIntervalSince1970: 1_700_010_000)
        )
        store.save(snapshot)

        let loaded = try #require(store.load())
        #expect(loaded.healthScore == 8)
        #expect(loaded.previousScore == 6)
        #expect(loaded.lastMealName == "Oatmeal")
        #expect(loaded.nextReminderTitle == "Lunch")
        #expect(loaded.trend == .up)
    }

    @Test("Clearing removes the stored snapshot")
    func storeClear() {
        let suiteName = "com.gutcheck.tests.widgets.\(UUID().uuidString)"
        let store = WidgetDataStore(suiteName: suiteName)
        defer { UserDefaults().removePersistentDomain(forName: suiteName) }

        store.save(WidgetSnapshot(healthScore: 9))
        store.clear()

        #expect(store.load() == nil)
    }
}
