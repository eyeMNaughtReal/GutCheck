import Foundation

@MainActor
class CategoryInsightsViewModel: ObservableObject {
    @Published var activeInsights: [HealthInsight] = []
    @Published var historicalInsights: [HealthInsight] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let aiService = AIAnalysisService.shared
    
    func loadInsights(for category: InsightCategory) async {
        isLoading = true
        error = nil
        
        // TODO: Replace with real data from AIAnalysisService
        switch category {
        case .foodTriggers:
            activeInsights = [
                HealthInsight(
                    title: "Dairy Sensitivity",
                    summary: "High correlation with digestive symptoms",
                    detailedDescription: "Dairy products show a strong correlation with bloating and discomfort, particularly when consumed in larger quantities.",
                    iconName: "exclamationmark.triangle.fill",
                    confidenceLevel: 85,
                    dateRange: "Last 30 Days",
                    recommendations: [
                        "Consider lactose-free alternatives",
                        "Test different dairy products separately",
                        "Monitor portion sizes"
                    ]
                )
            ]
            
            historicalInsights = [
                HealthInsight(
                    title: "Gluten Sensitivity",
                    summary: "Previous correlation found, now resolved",
                    detailedDescription: "Historical data showed potential gluten sensitivity, but recent logs show improved tolerance.",
                    iconName: "checkmark.circle.fill",
                    confidenceLevel: 70,
                    dateRange: "3 Months Ago",
                    recommendations: [
                        "Continue current approach",
                        "Monitor any changes"
                    ]
                )
            ]
            
        case .patterns:
            activeInsights = [
                HealthInsight(
                    title: "Morning Symptom Pattern",
                    summary: "Symptoms more frequent in early hours",
                    detailedDescription: "Analysis shows increased symptom frequency between 6-9 AM, often following large evening meals.",
                    iconName: "sunrise.fill",
                    confidenceLevel: 80,
                    dateRange: "Last 14 Days",
                    recommendations: [
                        "Consider lighter evening meals",
                        "Allow more time between dinner and sleep"
                    ]
                )
            ]
            
        case .trends:
            activeInsights = [
                HealthInsight(
                    title: "Improving Sleep Quality",
                    summary: "Better sleep with meal timing changes",
                    detailedDescription: "Sleep quality has improved since implementing earlier dinner times.",
                    iconName: "bed.double.fill",
                    confidenceLevel: 75,
                    dateRange: "Last 30 Days",
                    recommendations: [
                        "Maintain current dinner schedule",
                        "Continue monitoring sleep patterns"
                    ]
                )
            ]
            
        case .recommendations:
            activeInsights = [
                HealthInsight(
                    title: "Dietary Modifications",
                    summary: "Suggested changes based on patterns",
                    detailedDescription: "Based on recent patterns, several dietary modifications could help reduce symptoms.",
                    iconName: "list.bullet.clipboard.fill",
                    confidenceLevel: 90,
                    dateRange: "Current",
                    recommendations: [
                        "Increase fiber intake gradually",
                        "Space meals more evenly",
                        "Stay hydrated throughout the day"
                    ]
                )
            ]
        }
        
        isLoading = false
    }
}

