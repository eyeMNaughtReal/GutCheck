import Foundation
import Combine

/// Service for generating and managing health insights
class InsightsService: ObservableObject {
    static let shared = InsightsService()
    
    @Published var recentInsights: [HealthInsight] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let patternService = PatternRecognitionService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Main Methods
    
    /// Generates comprehensive insights for a given time range
    func generateInsights(
        timeRange: DateInterval,
        meals: [Meal],
        symptoms: [Symptom],
        healthData: GutHealthData?
    ) async {
        isLoading = true
        error = nil
        
        // Analyze patterns using the pattern recognition service
        let patternResult = await patternService.analyzePatterns(
            meals: meals,
            symptoms: symptoms,
            healthData: healthData,
            timeRange: timeRange
        )
        
        // Convert pattern results to HealthInsight objects
        let insights = await convertPatternsToInsights(patternResult)
        
        // Update published properties on main thread
        await MainActor.run {
            self.recentInsights = insights
            self.isLoading = false
        }
    }
    
    /// Generates insights for the last 30 days
    func generateRecentInsights() async {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        let timeRange = DateInterval(start: startDate, end: endDate)
        
        // Fetch data for the time range
        let meals = await fetchMeals(for: timeRange)
        let symptoms = await fetchSymptoms(for: timeRange)
        let healthData = await fetchHealthData(for: timeRange)
        
        await generateInsights(
            timeRange: timeRange,
            meals: meals,
            symptoms: symptoms,
            healthData: healthData
        )
    }
    
    /// Generates insights for a specific date
    func generateInsightsForDate(_ date: Date) async {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let timeRange = DateInterval(start: startOfDay, end: endOfDay)
        
        let meals = await fetchMeals(for: timeRange)
        let symptoms = await fetchSymptoms(for: timeRange)
        let healthData = await fetchHealthData(for: timeRange)
        
        await generateInsights(
            timeRange: timeRange,
            meals: meals,
            symptoms: symptoms,
            healthData: healthData
        )
    }
    
    // MARK: - Data Fetching
    
    private func fetchMeals(for timeRange: DateInterval) async -> [Meal] {
        do {
            guard let userId = AuthenticationManager.shared.currentUserId else {
                print("❌ Error fetching meals for insights: No authenticated user")
                return []
            }
            
            // Use the date range extension method
            return try await MealRepository.shared.fetchMealsForDateRange(
                startDate: timeRange.start,
                endDate: timeRange.end,
                userId: userId
            )
        } catch {
            print("❌ Error fetching meals for insights: \(error)")
            return []
        }
    }
    
    private func fetchSymptoms(for timeRange: DateInterval) async -> [Symptom] {
        do {
            guard let userId = AuthenticationManager.shared.currentUserId else {
                print("❌ Error fetching symptoms for insights: No authenticated user")
                return []
            }
            
            // Use the date range extension method
            return try await SymptomRepository.shared.fetchSymptomsForDateRange(
                startDate: timeRange.start,
                endDate: timeRange.end,
                userId: userId
            )
        } catch {
            print("❌ Error fetching symptoms for insights: \(error)")
            return []
        }
    }
    
    private func fetchHealthData(for timeRange: DateInterval) async -> GutHealthData? {
        return await withCheckedContinuation { continuation in
            HealthKitManager.shared.fetchGutHealthData(from: timeRange.start, to: timeRange.end) { healthData in
                continuation.resume(returning: healthData)
            }
        }
    }
    
    // MARK: - Pattern Conversion
    
    private func convertPatternsToInsights(_ patternResult: PatternAnalysisResult) async -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Convert food triggers
        for trigger in patternResult.foodTriggers {
            let insight = HealthInsight(
                title: "Food Trigger: \(trigger.foodName)",
                summary: "May be causing digestive symptoms",
                detailedDescription: generateFoodTriggerDescription(trigger),
                iconName: "exclamationmark.triangle.fill",
                confidenceLevel: Int(trigger.confidence * 100),
                dateRange: formatDateRange(patternResult.timeRange),
                recommendations: trigger.recommendations
            )
            insights.append(insight)
        }
        
        // Convert temporal patterns
        for pattern in patternResult.temporalPatterns {
            let insight = HealthInsight(
                title: pattern.title,
                summary: pattern.description,
                detailedDescription: generateTemporalPatternDescription(pattern),
                iconName: "clock.fill",
                confidenceLevel: Int(pattern.confidence * 100),
                dateRange: formatDateRange(patternResult.timeRange),
                recommendations: pattern.recommendations
            )
            insights.append(insight)
        }
        
        // Convert lifestyle correlations
        for correlation in patternResult.lifestyleCorrelations {
            let insight = HealthInsight(
                title: correlation.title,
                summary: correlation.description,
                detailedDescription: generateLifestyleCorrelationDescription(correlation),
                iconName: getLifestyleIcon(for: correlation.factor),
                confidenceLevel: Int(correlation.confidence * 100),
                dateRange: formatDateRange(patternResult.timeRange),
                recommendations: correlation.recommendations
            )
            insights.append(insight)
        }
        
        // Convert nutrition trends
        for trend in patternResult.nutritionTrends {
            let insight = HealthInsight(
                title: trend.title,
                summary: trend.description,
                detailedDescription: generateNutritionTrendDescription(trend),
                iconName: "chart.bar.fill",
                confidenceLevel: Int(trend.confidence * 100),
                dateRange: formatDateRange(patternResult.timeRange),
                recommendations: trend.recommendations
            )
            insights.append(insight)
        }
        
        return insights.sorted { $0.confidenceLevel > $1.confidenceLevel }
    }
    
    // MARK: - Description Generation
    
    private func generateFoodTriggerDescription(_ trigger: FoodTriggerInsight) -> String {
        var description = "\(trigger.foodName) appears to be triggering digestive symptoms with \(Int(trigger.confidence * 100))% confidence. "
        
        description += "Symptoms typically occur within \(trigger.timeWindow) after consumption. "
        
        if trigger.symptomCount > 1 {
            description += "This correlation has been observed \(trigger.symptomCount) times. "
        }
        
        if !trigger.highRiskCompounds.isEmpty {
            description += "The food contains \(trigger.highRiskCompounds.count) high-risk compounds that may contribute to symptoms. "
        }
        
        description += "Consider eliminating this food temporarily and reintroducing gradually to confirm the trigger."
        
        return description
    }
    
    private func generateTemporalPatternDescription(_ pattern: TemporalPatternInsight) -> String {
        var description = "A temporal pattern has been identified with \(Int(pattern.confidence * 100))% confidence. "
        
        description += pattern.description + " "
        
        if pattern.evidence.count > 1 {
            description += "This pattern is supported by multiple observations: "
            for evidence in pattern.evidence {
                description += evidence + ". "
            }
        }
        
        description += "Understanding these timing patterns can help you plan meals and activities to minimize symptom occurrence."
        
        return description
    }
    
    private func generateLifestyleCorrelationDescription(_ correlation: LifestyleCorrelationInsight) -> String {
        var description = "A correlation has been found between \(correlation.factor.lowercased()) and your digestive health with \(Int(correlation.confidence * 100))% confidence. "
        
        description += correlation.description + " "
        
        if correlation.impact == .positive {
            description += "This suggests that \(correlation.factor.lowercased()) has a beneficial effect on your gut health. "
        } else if correlation.impact == .negative {
            description += "This suggests that \(correlation.factor.lowercased()) may be contributing to your symptoms. "
        }
        
        description += "The evidence supporting this correlation includes: "
        for evidence in correlation.evidence {
            description += evidence + ". "
        }
        
        description += "Consider adjusting your \(correlation.factor.lowercased()) habits based on these findings."
        
        return description
    }
    
    private func generateNutritionTrendDescription(_ trend: NutritionTrendInsight) -> String {
        var description = "A nutrition trend has been identified with \(Int(trend.confidence * 100))% confidence. "
        
        description += trend.description + " "
        
        description += "Your current intake is \(String(format: "%.1f", trend.currentValue)) \(trend.unit), while the recommended target is \(String(format: "%.1f", trend.targetValue)) \(trend.unit). "
        
        if trend.currentValue < trend.targetValue {
            description += "This represents a \(Int(((trend.targetValue - trend.currentValue) / trend.targetValue) * 100))% shortfall from your target. "
        }
        
        description += "The evidence supporting this trend includes: "
        for evidence in trend.evidence {
            description += evidence + ". "
        }
        
        description += "Addressing this trend could significantly improve your digestive health."
        
        return description
    }
    
    // MARK: - Helper Methods
    

    
    private func getLifestyleIcon(for factor: String) -> String {
        switch factor.lowercased() {
        case "exercise":
            return "figure.walk"
        case "sleep":
            return "bed.double.fill"
        case "stress":
            return "brain.head.profile"
        default:
            return "heart.fill"
        }
    }
    
    private func formatDateRange(_ timeRange: DateInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let startString = formatter.string(from: timeRange.start)
        let endString = formatter.string(from: timeRange.end)
        
        if Calendar.current.isDate(timeRange.start, inSameDayAs: timeRange.end) {
            return startString
        } else {
            return "\(startString) - \(endString)"
        }
    }
    
}


