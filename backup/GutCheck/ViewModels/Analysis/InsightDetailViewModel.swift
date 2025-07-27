import Foundation

@MainActor
class InsightDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String? = nil
    
    // Additional properties for storing insight-related data
    @Published var relatedMeals: [Meal] = []
    @Published var relatedSymptoms: [Symptom] = []
    @Published var confidenceLevel: Double = 0.0
    @Published var recommendations: [String] = []
    
    // Properties expected by the view
    @Published var chartData: [Double] = []
    @Published var contributingFactors: [ContributingFactor] = []
    @Published var relatedInsights: [HealthInsight] = []
    
    /// Load detailed data for the insight
    func loadData(for insight: HealthInsight) async {
        isLoading = true
        defer { isLoading = false }
        
        // Set confidence level from the insight
        confidenceLevel = Double(insight.confidenceLevel) / 100.0
        
        // Use the existing recommendations from the insight
        recommendations = insight.recommendations
        
        // Generate mock chart data for demonstration
        chartData = generateMockChartData()
        
        // Generate contributing factors based on the insight
        contributingFactors = generateContributingFactors(for: insight)
        
        // TODO: In the future, we could load related meals and symptoms
        // based on the insight's title or other identifiers
        
        // For now, we'll just show the insight as provided
        error = nil
    }
    
    /// Generate mock chart data for visualization
    private func generateMockChartData() -> [Double] {
        // Return some sample data for the chart
        return [3.2, 4.1, 2.8, 5.2, 3.7, 4.5, 2.9, 3.8, 4.2, 3.5]
    }
    
    /// Generate contributing factors based on the insight
    private func generateContributingFactors(for insight: HealthInsight) -> [ContributingFactor] {
        var factors: [ContributingFactor] = []
        
        if insight.title.lowercased().contains("dairy") {
            factors.append(ContributingFactor(
                name: "Dairy Products",
                description: "High correlation with reported symptoms",
                impact: 0.85
            ))
            factors.append(ContributingFactor(
                name: "Lactose Content",
                description: "Amount of lactose in consumed items",
                impact: 0.72
            ))
        } else if insight.title.lowercased().contains("stress") {
            factors.append(ContributingFactor(
                name: "Stress Levels",
                description: "Self-reported stress during symptom periods",
                impact: 0.68
            ))
        }
        
        return factors
    }
}
