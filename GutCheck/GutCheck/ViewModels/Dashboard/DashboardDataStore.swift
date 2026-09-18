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

/// Severity level for AI-generated insight messages
enum AIInsightSeverity {
    case positive
    case neutral
    case warning
    
    var color: Color {
        switch self {
        case .positive: return ColorTheme.success
        case .neutral: return ColorTheme.info
        case .warning: return ColorTheme.warning
        }
    }
    
    var icon: String {
        switch self {
        case .positive: return "checkmark.seal.fill"
        case .neutral: return "sparkles"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
}

/// Central data store for dashboard functionality
/// Manages all dashboard-related data including health insights, meal/symptom data,
/// and real-time calculations for health scoring and recommendations.
@Observable final class DashboardDataStore {
    // MARK: - Published Properties
    
    /// Today's meals for the selected date
    var todaysMeals: [Meal] = []
    
    /// Today's symptoms for the selected date
    var todaysSymptoms: [Symptom] = []
    
    /// Active trigger alerts that require immediate attention
    var triggerAlerts: [String] = []
    
    /// Legacy insight message (deprecated - replaced by structured insights)
    var insightMessage: String? = nil
    
    /// Current health score (1-10) calculated from symptoms and meals
    var todaysHealthScore: Int = 7
    
    /// Personalized health focus recommendation for the selected day
    var todaysFocus: String = ""
    
    /// Smart avoidance tip based on recent symptom patterns
    var avoidanceTip: String = ""
    
    /// AI-generated insight summary for the selected day
    var aiInsightSummary: String = ""
    
    /// Severity level of the current AI insight
    var aiInsightSeverity: AIInsightSeverity = .neutral
    
    /// Currently selected date for dashboard data display
    var selectedDate: Date = Date.now
    
    // MARK: - Private Properties
    
    /// In-flight on-device narration of `aiInsightSummary`, cancelled when the
    /// selected date changes so a stale reply can't land on the new day's data.
    private var narrationTask: Task<Void, Never>?

    /// Authentication service for getting current user ID
    private var userService: LocalUserService?
    
    /// Repository dependencies
    private let mealRepository: any MealRepositoryProtocol
    private let symptomRepository: any SymptomRepositoryProtocol

    /// Suppresses on-device narration for preview and test stores.
    ///
    /// SwiftUI previews and unit tests shouldn't reach for the language model:
    /// previews would stall on it, and tests need `aiInsightSummary` to stay at
    /// the deterministic value they assert against.
    private let isPreview: Bool

    // MARK: - Initialization

    /// Initialize the dashboard data store
    /// - Parameter preview: If true, loads mock data for SwiftUI previews
    init(preview: Bool = false,
         mealRepository: any MealRepositoryProtocol = MealRepository.shared,
         symptomRepository: any SymptomRepositoryProtocol = SymptomRepository.shared) {
        self.mealRepository = mealRepository
        self.symptomRepository = symptomRepository
        self.isPreview = preview
        if preview {
            loadPreviewData()
        } else {
            Task { @MainActor in
                userService = LocalUserService.shared
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
        recomputeDerivedState()
    }

    /// Recomputes health score, focus, tips and alerts from whatever is
    /// currently in `todaysMeals` and `todaysSymptoms`.
    ///
    /// Separated from `loadDataForSelectedDate()` so the derivation can be
    /// exercised against known data. That method clears both arrays and kicks
    /// off an async reload before computing, so anything set on the store
    /// beforehand is gone by the time the score is calculated — which is why
    /// the dashboard tests were all asserting against an empty store.
    func recomputeDerivedState() {
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
            let highPainSymptoms = todaysSymptoms.filter { $0.painLevel >= .moderate }
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
        if todaysSymptoms.contains(where: { $0.painLevel == .severe }) {
            triggerAlerts.append("High pain level detected - consider consulting healthcare provider")
        }
        
        // Generate AI insight summary
        generateAIInsight()
    }
    
    /// Generate AI insight based on current meal and symptom data
    /// Uses placeholder logic; future versions will integrate with AIAnalysisService
    private func generateAIInsight() {
        if todaysSymptoms.isEmpty && todaysMeals.count >= 2 {
            aiInsightSummary = "No triggers detected today. Your digestion looks healthy!"
            aiInsightSeverity = .positive
        } else if todaysSymptoms.isEmpty && todaysMeals.isEmpty {
            aiInsightSummary = "Start logging meals to get personalized insights about your gut health."
            aiInsightSeverity = .neutral
        } else if todaysSymptoms.isEmpty {
            aiInsightSummary = "Looking good so far. Keep logging meals for better insights."
            aiInsightSeverity = .neutral
        } else if todaysSymptoms.contains(where: { $0.painLevel >= .moderate }) {
            aiInsightSummary = "Elevated symptoms detected. Consider gentle, easy-to-digest foods."
            aiInsightSeverity = .warning
        } else if !todaysSymptoms.isEmpty && !todaysMeals.isEmpty {
            let recentMealName = todaysMeals.last?.name ?? "your recent meal"
            aiInsightSummary = "Possible trigger: \(recentMealName). Symptoms appeared after eating."
            aiInsightSeverity = .warning
        } else {
            aiInsightSummary = "Keep logging to help identify patterns."
            aiInsightSeverity = .neutral
        }

        // The deterministic summary above is now set and displayable. Narration
        // only rewrites its wording, so severity stays as computed here.
        narrateAIInsight(fallback: aiInsightSummary)
    }

    /// Rewrites `aiInsightSummary` in natural prose using the on-device model.
    ///
    /// Fire-and-forget: the deterministic string is already on screen, and this
    /// replaces it a beat later if the model produces something. Nothing waits
    /// on it and nothing breaks when it fails.
    private func narrateAIInsight(fallback: String) {
        // Cancel any in-flight narration first. The user can page through dates
        // faster than the model responds, and a late reply from a previous date
        // would otherwise overwrite the current one.
        narrationTask?.cancel()

        // Previews and tests keep the deterministic wording.
        guard !isPreview else { return }

        let painLevels = todaysSymptoms.map { $0.painLevel.rawValue }
        let peakPain = painLevels.max().flatMap { PainLevel(rawValue: $0) }
        // Unwrapped inside the closure so `.none` reads as PainLevel.none
        // rather than Optional.none.
        let peakPainDescription: String? = peakPain.flatMap { level -> String? in
            switch level {
            case .none: nil
            case .mild: "mild"
            case .moderate: "moderate"
            case .severe: "severe"
            }
        }

        let facts = InsightFacts(
            mealCount: todaysMeals.count,
            symptomCount: todaysSymptoms.count,
            peakPainDescription: peakPainDescription,
            // Left empty on purpose. A food only belongs here once
            // PatternRecognitionService has actually correlated it; the
            // "last meal eaten" heuristic this view model uses elsewhere is not
            // a measured association and must not be narrated as one.
            flaggedFoods: [],
            averageOnsetHours: nil
        )

        narrationTask = Task { @MainActor [weak self] in
            guard InsightNarrationService.shared.isAvailable else { return }
            let narrated = await InsightNarrationService.shared.narrate(facts, fallback: fallback)
            guard !Task.isCancelled else { return }
            self?.aiInsightSummary = narrated
        }
    }
    
    // MARK: - Preview Support
    
    private func loadPreviewData() {
        self.todaysMeals = [
            Meal(
                id: "preview-1",
                name: "Breakfast",
                date: Date.now.addingTimeInterval(-3600 * 3),
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
                date: Date.now,
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
        self.aiInsightSummary = "No triggers detected today. Your digestion looks healthy!"
        self.aiInsightSeverity = .positive
    }
    
    // MARK: - Private Load Logic
    
    private func load() {
        // Only load if not in preview mode
        guard todaysMeals.isEmpty && todaysSymptoms.isEmpty else { return }
        
        // Load real data from repositories
        Task {
            do {
                // Load today's symptoms
                let symptoms = try await symptomRepository.getSymptoms(for: selectedDate)
                
                // Load today's meals using the current user ID
                if let currentUser = await userService?.currentUser {
                    let userMeals = try await mealRepository.fetchMealsForDate(
                        selectedDate,
                        userId: currentUser.id
                    )
                    await MainActor.run { [weak self] in
                        self?.todaysMeals = userMeals
                    }
                } else {
                }
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.todaysSymptoms = symptoms

                    // Score and insights from the data that just arrived
                    self.recomputeDerivedState()

                    // Discard the preview placeholder. `triggerAlerts` is not
                    // cleared here: `recomputeDerivedState()` has just populated
                    // it from the real data, and this line used to wipe that —
                    // which is why the "High pain level" and "Multiple symptoms"
                    // alerts never appeared in the app.
                    self.insightMessage = nil
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.todaysSymptoms = []
                    self.todaysMeals = []
                    self.triggerAlerts = []
                    self.insightMessage = nil
                    self.todaysFocus = "Unable to load data. Please try again."
                    self.avoidanceTip = "Check your connection and try refreshing."
                    self.aiInsightSummary = "Unable to generate insights right now."
                    self.aiInsightSeverity = .neutral
                }
            }
        }
    }
}
