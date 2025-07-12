import Foundation
import SwiftUI
import Combine

final class DashboardDataStore: ObservableObject {
    // MARK: - Published Properties

    @Published var todaysMeals: [Meal] = []
    @Published var todaysSymptoms: [Symptom] = []
    @Published var triggerAlerts: [String] = []
    @Published var insightMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        load()
    }

    // MARK: - Public Methods

    func refresh() {
        load()
    }

    // MARK: - Private Load Logic (Replace this with real data fetch later)

    private func load() {
        // Temporary mock data — replace with Firebase/CoreData
        loadMockData()
    }

    private func loadMockData() {
        self.todaysMeals = [
            Meal(
                name: "Impossible Whopper",
                date: Date(),
                type: .lunch,
                source: .manual,
                foodItems: [],
                notes: "Ate quickly, might be cause of bloating",
                tags: ["fast food", "processed", "gluten"],
                createdBy: "mockUser123"
            ),
            Meal(
                name: "Oatmeal with Banana",
                date: Date(),
                type: .breakfast,
                source: .manual,
                foodItems: [],
                notes: nil,
                tags: ["high fiber", "low fat"],
                createdBy: "mockUser123"
            )
        ]

        self.todaysSymptoms = [
            Symptom(
                date: Date(),
                stoolType: .type4,
                painLevel: .moderate,
                urgencyLevel: .moderate,
                notes: "Felt bloated after lunch",
                tags: ["bloating", "mild discomfort"],
                createdBy: "mockUser123"
            )
        ]

        self.triggerAlerts = [
            "Gluten may be causing your bloating",
            "High saturated fat meals appear before symptoms 2× this week"
        ]

        self.insightMessage = "Fiber intake low today. Consider adding more whole grains or vegetables."
    }
}
