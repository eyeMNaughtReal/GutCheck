import Foundation

/// Ranked item for display in summary cards
struct RankedItem: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

@MainActor
class InsightsViewModel: ObservableObject {
    @Published var recentInsights: [HealthInsight] = []
    @Published var patterns: [HealthPattern] = []
    @Published var recommendations: [HealthRecommendation] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Weekly Summary Data

    @Published var weeklyMealCount: Int = 0
    @Published var weeklySymptomCount: Int = 0
    @Published var topSymptoms: [RankedItem] = []
    @Published var topTriggerFoods: [RankedItem] = []
    @Published var bestDays: [RankedItem] = []

    private let insightsService = InsightsService.shared
    private let mealRepository = MealRepository.shared
    private let symptomRepository = SymptomRepository.shared
    private let healthKitManager = HealthKitManager.shared
    private let authService = AuthService()
    
    func loadInsights() async {
        isLoading = true
        error = nil
        
        do {
            // Get current user ID
            let userId = getCurrentUserId()
            
            // Calculate time range for last 30 days
            let endDate = Date.now
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
            let timeRange = DateInterval(start: startDate, end: endDate)
            
            // Fetch real data
            let meals = try await mealRepository.fetchMealsForDateRange(
                startDate: startDate,
                endDate: endDate,
                userId: userId
            )
            
            let symptoms = try await symptomRepository.fetchSymptomsForDateRange(
                startDate: startDate,
                endDate: endDate,
                userId: userId
            )
            
            // Fetch health data if available
            let healthData = await fetchHealthData(for: timeRange)
            
            // Generate real insights using the service
            await insightsService.generateInsights(
                timeRange: timeRange,
                meals: meals,
                symptoms: symptoms,
                healthData: healthData
            )
            
            // Get insights from the service
            recentInsights = insightsService.recentInsights
            
            // Convert insights to patterns and recommendations
            patterns = convertInsightsToPatterns(recentInsights)
            recommendations = convertInsightsToRecommendations(recentInsights)

            // Compute weekly summary cards
            computeWeeklySummaries(meals: meals, symptoms: symptoms)

        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func fetchHealthData(for timeRange: DateInterval) async -> GutHealthData? {
        return await withCheckedContinuation { continuation in
            healthKitManager.fetchGutHealthData(
                from: timeRange.start,
                to: timeRange.end
            ) { healthData in
                continuation.resume(returning: healthData)
            }
        }
    }
    
    private func convertInsightsToPatterns(_ insights: [HealthInsight]) -> [HealthPattern] {
        return insights.compactMap { insight -> HealthPattern? in
            // Convert insights to patterns based on their content
            let confidence = Double(insight.confidenceLevel) / 100.0
            
            return HealthPattern(
                title: insight.title,
                description: insight.summary,
                iconName: insight.iconName,
                confidence: confidence,
                dateRange: insight.dateRange,
                supportingData: [insight.detailedDescription ?? ""],
                recommendations: insight.recommendations
            )
        }
    }
    
    private func convertInsightsToRecommendations(_ insights: [HealthInsight]) -> [HealthRecommendation] {
        return insights.compactMap { insight -> HealthRecommendation? in
            // Determine priority based on confidence level
            let priority: HealthRecommendation.RecommendationPriority
            if insight.confidenceLevel >= 80 {
                priority = .high
            } else if insight.confidenceLevel >= 60 {
                priority = .medium
            } else {
                priority = .low
            }
            
            return HealthRecommendation(
                title: insight.title,
                description: insight.summary,
                iconName: insight.iconName,
                priority: priority,
                actionItems: insight.recommendations,
                source: "AI Analysis",
                dateCreated: Date.now
            )
        }
    }
    
    private func getCurrentUserId() -> String {
        if let currentUser = authService.currentUser {
            return currentUser.id
        } else {
            return "default_user"
        }
    }

    // MARK: - Weekly Summary Computation

    private func computeWeeklySummaries(meals: [Meal], symptoms: [Symptom]) {
        let calendar = Calendar.current
        let now = Date.now
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        let weekMeals = meals.filter { $0.date >= weekAgo }
        let weekSymptoms = symptoms.filter { $0.date >= weekAgo }

        weeklyMealCount = weekMeals.count
        weeklySymptomCount = weekSymptoms.count

        computeTopSymptoms(from: weekSymptoms)
        computeTriggerFoods(meals: meals, symptoms: symptoms)
        computeBestDays(symptoms: symptoms)
    }

    /// Rank symptom characteristics by frequency this week
    private func computeTopSymptoms(from symptoms: [Symptom]) {
        var counts: [String: Int] = [:]

        for symptom in symptoms {
            if symptom.painLevel != .none {
                let label: String
                switch symptom.painLevel {
                case .mild: label = "Mild Pain"
                case .moderate: label = "Moderate Pain"
                case .severe: label = "Severe Pain"
                case .none: continue
                }
                counts[label, default: 0] += 1
            }

            if symptom.urgencyLevel != .none {
                let label: String
                switch symptom.urgencyLevel {
                case .mild: label = "Mild Urgency"
                case .moderate: label = "Moderate Urgency"
                case .urgent: label = "High Urgency"
                case .none: continue
                }
                counts[label, default: 0] += 1
            }

            // Count abnormal stool types (Bristol 1-2 = constipation, 6-7 = diarrhea)
            switch symptom.stoolType {
            case .type1, .type2:
                counts["Constipation", default: 0] += 1
            case .type6, .type7:
                counts["Loose Stool", default: 0] += 1
            default:
                break
            }
        }

        topSymptoms = counts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { RankedItem(name: $0.key, count: $0.value) }
    }

    /// Find foods eaten 2-8 hours before symptoms, rank by frequency
    private func computeTriggerFoods(meals: [Meal], symptoms: [Symptom]) {
        var foodCounts: [String: Int] = [:]

        for symptom in symptoms {
            // Only consider symptoms with actual issues
            guard symptom.painLevel != .none || symptom.urgencyLevel != .none
                    || symptom.stoolType == .type1 || symptom.stoolType == .type2
                    || symptom.stoolType == .type6 || symptom.stoolType == .type7 else {
                continue
            }

            // Find meals eaten 2-8 hours before this symptom
            let windowStart = symptom.date.addingTimeInterval(-8 * 3600)
            let windowEnd = symptom.date.addingTimeInterval(-2 * 3600)

            let precedingMeals = meals.filter { $0.date >= windowStart && $0.date <= windowEnd }

            for meal in precedingMeals {
                for item in meal.foodItems {
                    foodCounts[item.name, default: 0] += 1
                }
            }
        }

        topTriggerFoods = foodCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { RankedItem(name: $0.key, count: $0.value) }
    }

    /// Rank days of the week by lowest symptom count (last 30 days)
    private func computeBestDays(symptoms: [Symptom]) {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let dayNames = formatter.weekdaySymbols ?? ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        // Count symptoms per weekday
        var dayCounts: [Int: Int] = [:]  // weekday (1=Sun..7=Sat) → count
        var dayOccurrences: [Int: Int] = [:]  // how many of each weekday are in the 30-day range

        let now = Date.now
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        // Count occurrences of each weekday in the range
        var cursor = thirtyDaysAgo
        while cursor <= now {
            let weekday = calendar.component(.weekday, from: cursor)
            dayOccurrences[weekday, default: 0] += 1
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? now.addingTimeInterval(86400)
        }

        for symptom in symptoms {
            let weekday = calendar.component(.weekday, from: symptom.date)
            dayCounts[weekday, default: 0] += 1
        }

        // Rank by lowest average symptoms per day occurrence
        bestDays = (1...7)
            .map { weekday -> (String, Double) in
                let count = Double(dayCounts[weekday] ?? 0)
                let occurrences = Double(dayOccurrences[weekday] ?? 1)
                let avg = occurrences > 0 ? count / occurrences : 0
                return (dayNames[weekday - 1], avg)
            }
            .sorted { $0.1 < $1.1 }
            .prefix(3)
            .map { RankedItem(name: $0.0, count: Int($0.1 * 10)) }  // Store avg * 10 for display precision
    }
}
