import Foundation

@MainActor
class InsightsViewModel: ObservableObject {
    @Published var recentInsights: [HealthInsight] = []
    @Published var patterns: [HealthPattern] = []
    @Published var recommendations: [HealthRecommendation] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let aiService = AIAnalysisService.shared
    
    func loadInsights() async {
        isLoading = true
        error = nil
        
        do {
            // Load recent insights
            recentInsights = try await loadRecentInsights()
            
            // Load patterns
            patterns = try await loadPatterns()
            
            // Load recommendations
            recommendations = try await loadRecommendations()
            
        } catch {
            self.error = error.localizedDescription
            print("❌ Error loading insights: \(error)")
        }
        
        isLoading = false
    }
    
    private func loadRecentInsights() async throws -> [HealthInsight] {
        // TODO: Replace with real data from AIAnalysisService
        return [
            HealthInsight(
                title: "Dairy Sensitivity Pattern",
                summary: "Strong correlation between dairy consumption and bloating",
                detailedDescription: "Analysis shows symptoms typically occur 2-4 hours after consuming dairy products, particularly with high-fat items.",
                iconName: "pills.fill",
                confidenceLevel: 85,
                dateRange: "Last 30 Days",
                recommendations: [
                    "Consider lactose-free alternatives",
                    "Try smaller portions to test tolerance",
                    "Keep track of different dairy types separately"
                ]
            ),
            HealthInsight(
                title: "Meal Timing Impact",
                summary: "Late dinners may affect sleep quality",
                detailedDescription: "Meals consumed after 8 PM show a correlation with reduced sleep quality and morning discomfort.",
                iconName: "clock.fill",
                confidenceLevel: 75,
                dateRange: "Last 14 Days",
                recommendations: [
                    "Try to eat dinner before 7 PM",
                    "Allow 3 hours between dinner and bedtime",
                    "Consider lighter evening meals"
                ]
            )
        ]
    }
    
    private func loadPatterns() async throws -> [HealthPattern] {
        // TODO: Replace with real data from AIAnalysisService
        return [
            HealthPattern(
                title: "Morning Symptom Pattern",
                description: "Symptoms are more frequent in the morning hours",
                iconName: "sunrise.fill",
                confidence: 0.85,
                dateRange: "Last 30 Days",
                supportingData: [
                    "70% of symptoms occur between 6-10 AM",
                    "Often follows large evening meals"
                ],
                recommendations: [
                    "Consider smaller evening meals",
                    "Try eating dinner earlier"
                ]
            ),
            HealthPattern(
                title: "Exercise Impact",
                description: "Moderate exercise appears to reduce symptom frequency",
                iconName: "figure.walk",
                confidence: 0.78,
                dateRange: "Last 60 Days",
                supportingData: [
                    "25% fewer symptoms on days with exercise",
                    "Best results with 30+ minutes of activity"
                ],
                recommendations: [
                    "Aim for daily moderate exercise",
                    "Try morning walks before meals"
                ]
            )
        ]
    }
    
    private func loadRecommendations() async throws -> [HealthRecommendation] {
        // TODO: Replace with real data from AIAnalysisService
        return [
            HealthRecommendation(
                title: "Meal Timing Adjustment",
                description: "Consider adjusting your dinner schedule to improve digestion and sleep quality.",
                iconName: "clock.fill",
                priority: .high,
                actionItems: [
                    "Eat dinner before 7 PM",
                    "Allow 3 hours before bedtime",
                    "Track evening meal times"
                ],
                source: "Pattern Analysis",
                dateCreated: Date()
            ),
            HealthRecommendation(
                title: "Dairy Alternative Trial",
                description: "Test lactose-free alternatives to assess if dairy is a trigger.",
                iconName: "cup.and.saucer.fill",
                priority: .medium,
                actionItems: [
                    "Try lactose-free milk",
                    "Test dairy alternatives",
                    "Monitor symptoms"
                ],
                source: "Food Sensitivity Analysis",
                dateCreated: Date()
            )
        ]
    }
}
