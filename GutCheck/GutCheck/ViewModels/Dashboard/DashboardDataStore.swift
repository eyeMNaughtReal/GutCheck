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
    @Published var todaysFocus: String = ""
    
    /// Smart avoidance tip based on recent symptom patterns
    @Published var avoidanceTip: String = ""
    
    /// Currently selected date for dashboard data display
    @Published var selectedDate: Date = Date()
    
    // MARK: - Private Properties
    
    /// Combine cancellables for proper memory management
    private var cancellables = Set<AnyCancellable>()
    
    /// Authentication service for getting current user ID
    private var authService: AuthService?
    
    // MARK: - Initialization
    
    /// Initialize the dashboard data store
    /// - Parameter preview: If true, loads mock data for SwiftUI previews
    init(preview: Bool = false) {
        if preview {
            loadPreviewData()
        } else {
            Task { @MainActor in
                authService = AuthService()
                load()
            }
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
        load()
        
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
        var score = 7 // Base neutral score
        
        // Bonus for no symptoms
        if todaysSymptoms.isEmpty {
            score += 2
        } else {
            // Penalty based on symptom severity
            let totalSeverity = todaysSymptoms.reduce(0) { total, symptom in
                total + symptom.painLevel.rawValue + symptom.urgencyLevel.rawValue
            }
            let averageSeverity = totalSeverity / max(todaysSymptoms.count, 1)
            
            if averageSeverity >= 8 {
                score -= 4
            } else if averageSeverity >= 6 {
                score -= 3
            } else if averageSeverity >= 4 {
                score -= 2
            } else {
                score -= 1
            }
        }
        
        // Bonus for regular meals
        if todaysMeals.count >= 2 {
            score += 1
        }
        
        // Clamp score to 1-10 range
        return max(1, min(10, score))
    }
    
    /// Generate insights based on current data
    private func generateInsights() {
        // Generate focus message based on current data
        if todaysSymptoms.isEmpty && todaysMeals.count >= 2 {
            todaysFocus = "Great day! You're eating regularly and feeling well. Keep up the healthy habits."
        } else if todaysSymptoms.isEmpty {
            todaysFocus = "You're feeling good today. Consider adding a meal if you haven't eaten recently."
        } else {
            todaysFocus = "Focus on gentle foods and staying hydrated. Listen to your body's signals."
        }
        
        // Generate avoidance tip based on symptoms
        if !todaysSymptoms.isEmpty {
            let highPainSymptoms = todaysSymptoms.filter { $0.painLevel.rawValue >= 7 }
            if !highPainSymptoms.isEmpty {
                avoidanceTip = "You're experiencing high pain levels. Avoid spicy, fatty, or hard-to-digest foods today."
            } else {
                avoidanceTip = "Monitor your symptoms and avoid any foods that seem to make them worse."
            }
        } else {
            avoidanceTip = "No specific triggers detected today. Continue with your usual diet."
        }
        
        // Generate trigger alerts if needed
        triggerAlerts = []
        if todaysSymptoms.count >= 3 {
            triggerAlerts.append("Multiple symptoms today - consider reviewing recent meals")
        }
        if todaysSymptoms.contains(where: { $0.painLevel.rawValue >= 8 }) {
            triggerAlerts.append("High pain level detected - consider consulting healthcare provider")
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
    
    // MARK: - Private Load Logic
    
    private func load() {
        // Only load if not in preview mode
        guard todaysMeals.isEmpty && todaysSymptoms.isEmpty else { return }
        
        // Load real data from repositories
        print("📱 Dashboard: Loading symptoms for date: \(selectedDate)")
        Task {
            do {
                // Load today's symptoms
                let symptoms = try await SymptomRepository.shared.getSymptoms(for: selectedDate)
                print("📊 Dashboard: Loaded \(symptoms.count) symptoms")
                
                // Load today's meals using the current user ID
                if let currentUser = await authService?.currentUser {
                    let userMeals = try await MealRepository.shared.fetchMealsForDate(
                        selectedDate,
                        userId: currentUser.id
                    )
                    print("📊 Dashboard: Loaded \(userMeals.count) meals for user \(currentUser.id)")
                    await MainActor.run { [weak self] in
                        self?.todaysMeals = userMeals
                    }
                } else {
                    print("⚠️ Dashboard: No authenticated user found, skipping meal loading")
                }
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.todaysSymptoms = symptoms
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
                    self.todaysFocus = "Unable to load data. Please try again."
                    self.avoidanceTip = "Check your connection and try refreshing."
                }
            }
        }
    }
}
