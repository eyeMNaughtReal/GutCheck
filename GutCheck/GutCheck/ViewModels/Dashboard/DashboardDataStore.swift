//
//  DashboardDataStore.swift
//  GutCheck
//
//  Data store for dashboard-specific information including:
//  - Daily health insights (score, focus, avoidance tips)
//  - Meal and symptom data for selected dates
//  - Real-time health score calculation
//  - Pattern-based recommendation generation
//
//  Created by Mark Conley on 7/12/25.
//

import Foundation
import SwiftUI
import Combine

/// Central data store for dashboard functionality
/// Manages all dashboard-related data including health insights, meal/symptom data,
/// and real-time calculations for health scoring and recommendations.
final class DashboardDataStore: ObservableObject {
    // MARK: - Published Properties
    
    /// Today's meals for the selected date
    @Published var todaysMeals: [Meal] = []
    
    /// Today's symptoms for the selected date
    @Published var todaysSymptoms: [Symptom] = []
    
    /// Active trigger alerts that require immediate attention
    @Published var triggerAlerts: [String] = []
    
    /// Legacy insight message (deprecated - replaced by structured insights)
    @Published var insightMessage: String? = nil
    
    /// Current health score (1-10) calculated from symptoms and meals
    @Published var todaysHealthScore: Int = 7
    
    /// Personalized health focus recommendation for the selected day
    @Published var todaysFocus: String = "Stay hydrated and eat fiber-rich foods like berries, chia seeds, and whole grains"
    
    /// Smart avoidance tip based on recent symptom patterns
    @Published var avoidanceTip: String = "Avoid spicy foods (like hot sauce, chili peppers) today - they've triggered symptoms twice this week"
    
    /// Currently selected date for dashboard data display
    @Published var selectedDate: Date = Date()
    
    // MARK: - Private Properties
    
    /// Combine cancellables for proper memory management
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize the dashboard data store
    /// - Parameter preview: If true, loads mock data for SwiftUI previews
    init(preview: Bool = false) {
        if preview {
            loadPreviewData()
        } else {
            load()
        }
    }
    
    // MARK: - Public Methods
    
    /// Refresh all dashboard data
    func refresh() {
        load()
    }
    
    /// Load data specifically for the currently selected date
    /// This method is called when the user changes the date in the WeekSelector
    func loadDataForSelectedDate() {
        // Clear existing data first
        todaysMeals = []
        todaysSymptoms = []
        
        // Load data for the selected date
        loadMockData()
        
        // Recalculate health score and insights for the new date
        todaysHealthScore = calculateHealthScore()
        generateInsights()
    }
    
    // MARK: - Private Methods
    
    /// Calculate health score based on current symptoms and meals
    /// Score ranges from 1-10 with the following logic:
    /// - Base score: 7 (neutral)
    /// - No symptoms: +2 points
    /// - Symptom severity: -1 to -4 points based on pain/urgency levels
    /// - Meal frequency: +1 point for 2+ meals
    /// - Final score clamped to 1-10 range
    private func calculateHealthScore() -> Int {
        // Base score starts at 7 (neutral)
        var score = 7
        
        // Adjust based on symptoms
        if todaysSymptoms.isEmpty {
            score += 2 // No symptoms today
        } else {
            // Reduce score based on symptom severity
            let totalSeverity = todaysSymptoms.reduce(0) { total, symptom in
                total + (symptom.painLevel.rawValue + symptom.urgencyLevel.rawValue)
            }
            score -= min(totalSeverity, 4) // Max reduction of 4 points
        }
        
        // Adjust based on meals
        if todaysMeals.count >= 2 {
            score += 1 // Good meal frequency
        }
        
        // Ensure score stays within 1-10 range
        return max(1, min(10, score))
    }
    
    /// Generate personalized insights based on current data
    /// Creates actionable focus tips and avoidance warnings based on:
    /// - Current symptom patterns (pain, urgency, frequency)
    /// - Recent symptom history and correlations
    /// - Known food triggers and patterns
    private func generateInsights() {
        // Generate today's focus based on symptoms
        if todaysSymptoms.isEmpty {
            todaysFocus = "Great day! Keep up your healthy habits"
        } else {
            let hasPain = todaysSymptoms.contains { $0.painLevel != .none }
            let hasUrgency = todaysSymptoms.contains { $0.urgencyLevel != .none }
            
            if hasPain && hasUrgency {
                todaysFocus = "Focus on gentle foods and stress management. Try oatmeal, bananas, and chamomile tea."
            } else if hasPain {
                todaysFocus = "Try anti-inflammatory foods like ginger tea, turmeric in smoothies, and omega-3 rich salmon."
            } else if hasUrgency {
                todaysFocus = "Add fiber gradually: try berries, chia seeds, or a small apple with breakfast."
            } else {
                todaysFocus = "Monitor your food triggers and stay hydrated. Aim for 8 glasses of water today."
            }
        }
        
        // Generate avoidance tip based on recent patterns
        if todaysSymptoms.count >= 2 {
            avoidanceTip = "Skip spicy foods (like hot sauce, chili) and dairy (milk, cheese, yogurt) today - they've triggered symptoms recently."
        } else if todaysSymptoms.count == 1 {
            avoidanceTip = "Avoid processed foods and focus on whole foods like grilled chicken, steamed vegetables, and brown rice."
        } else {
            avoidanceTip = "You're doing great! Keep avoiding your known triggers and maintain your healthy routine."
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
        self.todaysHealthScore = 8
        self.todaysFocus = "Focus on eating slowly and mindfully today. Try setting your fork down between bites."
        self.avoidanceTip = "Skip dairy products (milk, cheese, ice cream) - they've caused bloating 3 times this week"
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
                
                // Load today's meals (we'll need to get this from the auth service)
                let meals: [Meal] = []
                // TODO: Get meals when we have access to user ID
                // let meals = try await MealRepository.shared.fetchMealsForDate(selectedDate, userId: userId)
                print("📊 Dashboard: Loaded \(meals.count) meals")
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.todaysSymptoms = symptoms
                    self.todaysMeals = meals
                    print("📊 Dashboard: Updated UI with \(self.todaysSymptoms.count) symptoms and \(self.todaysMeals.count) meals")
                    
                    // Calculate health score based on actual data
                    self.todaysHealthScore = self.calculateHealthScore()
                    
                    // Generate focus and avoidance tips based on data
                    self.generateInsights()
                    
                    // Clear other mock data for now
                    self.triggerAlerts = []
                    self.insightMessage = nil
                }
            } catch {
                print("❌ Dashboard: Error loading dashboard data: \(error)")
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.todaysSymptoms = []
                    self.todaysMeals = []
                    self.triggerAlerts = []
                    self.insightMessage = nil
                }
            }
        }
    }
}
