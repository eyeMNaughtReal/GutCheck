import Foundation

@MainActor
class InsightsViewModel: ObservableObject {
    @Published var recentInsights: [HealthInsight] = []
    @Published var patterns: [HealthPattern] = []
    @Published var recommendations: [HealthRecommendation] = []
    @Published var isLoading = false
    @Published var error: String?
    
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
            let endDate = Date()
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
            
        } catch {
            self.error = error.localizedDescription
            print("❌ Error loading insights: \(error)")
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
                dateCreated: Date()
            )
        }
    }
    
    private func getCurrentUserId() -> String {
        // Get the current user ID from the authentication service
        if let currentUser = authService.currentUser {
            return currentUser.id
        } else {
            // Fallback to a default if no user is authenticated
            // This should rarely happen in a properly authenticated app
            print("⚠️ InsightsViewModel: No authenticated user found, using default user ID")
            return "default_user"
        }
    }
}
