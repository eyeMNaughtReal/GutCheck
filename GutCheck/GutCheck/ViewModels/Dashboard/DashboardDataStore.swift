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
        self.todaysSymptoms = []
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
        // Load real data from repositories
        print("📱 Dashboard: Loading symptoms for date: \(selectedDate)")
        Task {
            do {
                // Load today's symptoms
                let symptoms = try await SymptomRepository.shared.getSymptoms(for: selectedDate)
                print("📊 Dashboard: Loaded \(symptoms.count) symptoms")
                
                await MainActor.run {
                    self.todaysSymptoms = symptoms
                    print("📊 Dashboard: Updated UI with \(self.todaysSymptoms.count) symptoms")
                    
                    // Clear other mock data for now
                    self.triggerAlerts = []
                    self.insightMessage = nil
                }
            } catch {
                print("❌ Dashboard: Error loading dashboard data: \(error)")
                await MainActor.run {
                    self.todaysSymptoms = []
                    self.triggerAlerts = []
                    self.insightMessage = nil
                }
            }
        }
    }
}
