import Foundation
import SwiftUI
import Combine

final class DashboardDataStore: ObservableObject {
    // MARK: - Published Properties
    
    @Published var todaysMeals: [Meal] = []
    @Published var todaysSymptoms: [Symptom] = []
    @Published var triggerAlerts: [String] = []
    @Published var insightMessage: String? = nil
    @Published var selectedDate: Date = Date()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(preview: Bool = false) {
        if preview {
            loadPreviewData()
        } else {
            load()
        }
    }
    
    // MARK: - Preview Support
    
    private func loadPreviewData() {
        self.todaysMeals = [
            Meal(
                id: "preview-1",
                name: "Breakfast",
                date: Date().addingTimeInterval(-3600 * 3),
                type: .breakfast,
                source: .manual,
                foodItems: [],
                notes: "Preview breakfast",
                tags: ["preview"],
                createdBy: "preview-user"
            ),
            Meal(
                id: "preview-2",
                name: "Lunch",
                date: Date(),
                type: .lunch,
                source: .manual,
                foodItems: [],
                notes: "Preview lunch",
                tags: ["preview"],
                createdBy: "preview-user"
            )
        ]
        self.todaysSymptoms = [
            Symptom(
                id: "preview-1",
                date: Date().addingTimeInterval(-3600 * 2),
                stoolType: .type4,
                painLevel: .moderate,
                urgencyLevel: .mild,
                notes: "Preview symptom 1",
                tags: ["preview"],
                createdBy: "preview-user"
            ),
            Symptom(
                id: "preview-2",
                date: Date(),
                stoolType: .type3,
                painLevel: .mild,
                urgencyLevel: .none,
                notes: "Preview symptom 2",
                tags: ["preview"],
                createdBy: "preview-user"
            )
        ]
        self.triggerAlerts = ["High stress levels detected", "Consider spacing out meals"]
        self.insightMessage = "Your symptoms tend to improve when you eat smaller meals more frequently throughout the day."
    }
    
    // MARK: - Public Methods
    
    func refresh() {
        load()
    }
    
    // MARK: - Private Load Logic (Replace this with real data fetch later)
    
    private func load() {
        // Only load if not in preview mode
        guard todaysMeals.isEmpty && todaysSymptoms.isEmpty else { return }
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
