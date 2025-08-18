import Foundation

@MainActor
class CategoryInsightsViewModel: ObservableObject {
    @Published var activeInsights: [HealthInsight] = []
    @Published var historicalInsights: [HealthInsight] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let insightsService = InsightsService.shared
    private let mealRepository = MealRepository.shared
    private let symptomRepository = SymptomRepository.shared
    private let authService = AuthService()
    
    func loadInsights(for category: InsightCategory) async {
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
            
            // Generate real insights using the service
            await insightsService.generateInsights(
                timeRange: timeRange,
                meals: meals,
                symptoms: symptoms,
                healthData: nil
            )
            
            // Get insights from the service
            let allInsights = insightsService.recentInsights
            
            // Filter insights based on category
            switch category {
            case .foodTriggers:
                activeInsights = allInsights.filter { insight in
                    insight.title.lowercased().contains("trigger") ||
                    insight.title.lowercased().contains("food") ||
                    insight.title.lowercased().contains("sensitivity") ||
                    insight.title.lowercased().contains("allergy")
                }
                
            case .patterns:
                activeInsights = allInsights.filter { insight in
                    insight.title.lowercased().contains("pattern") ||
                    insight.title.lowercased().contains("timing") ||
                    insight.title.lowercased().contains("correlation")
                }
                
            case .trends:
                activeInsights = allInsights.filter { insight in
                    insight.title.lowercased().contains("trend") ||
                    insight.title.lowercased().contains("improvement") ||
                    insight.title.lowercased().contains("change")
                }
                
            case .recommendations:
                activeInsights = allInsights.filter { insight in
                    insight.title.lowercased().contains("recommendation") ||
                    insight.title.lowercased().contains("suggestion") ||
                    insight.title.lowercased().contains("advice")
                }
            }
            
            // For now, historical insights will be empty until we implement historical data
            // In the future, this could show insights from previous time periods
            historicalInsights = []
            
        } catch {
            self.error = error.localizedDescription
            print("❌ Error loading category insights: \(error)")
        }
        
        isLoading = false
    }
    
    private func getCurrentUserId() -> String {
        // Get the current user ID from the authentication service
        if let currentUser = authService.currentUser {
            return currentUser.id
        } else {
            // Fallback to a default if no user is authenticated
            // This should rarely happen in a properly authenticated app
            print("⚠️ CategoryInsightsViewModel: No authenticated user found, using default user ID")
            return "default_user"
        }
    }
}

