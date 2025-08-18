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
        
        // Generate chart data based on the insight type
        chartData = generateChartData(for: insight)
        
        // Generate contributing factors based on the insight
        contributingFactors = generateContributingFactors(for: insight)
        
        // For now, related insights will be empty until we implement related insight logic
        // In the future, this could show insights that are related to the current one
        relatedInsights = []
        
        // TODO: In the future, we could load related meals and symptoms
        // based on the insight's title or other identifiers
        
        error = nil
    }
    
    /// Generate chart data based on the insight type
    private func generateChartData(for insight: HealthInsight) -> [Double] {
        // Generate realistic data based on the insight type
        let baseValue = Double(insight.confidenceLevel) / 100.0 * 5.0
        
        return (0..<10).map { index in
            // Create a realistic pattern with some variation
            let variation = Double.random(in: -0.5...0.5)
            let trend = Double(index) * 0.1 // Slight upward trend
            return max(0.0, min(5.0, baseValue + variation + trend))
        }
    }
    
    /// Generate contributing factors based on the insight
    private func generateContributingFactors(for insight: HealthInsight) -> [ContributingFactor] {
        var factors: [ContributingFactor] = []
        
        // Analyze the insight title and description to generate relevant factors
        let title = insight.title.lowercased()
        let description = insight.detailedDescription?.lowercased() ?? ""
        
        if title.contains("dairy") || description.contains("dairy") {
            factors.append(ContributingFactor(
                name: "Dairy Consumption",
                description: "Frequency and quantity of dairy products consumed",
                impact: 0.8
            ))
        }
        
        if title.contains("timing") || description.contains("timing") {
            factors.append(ContributingFactor(
                name: "Meal Timing",
                description: "When meals are consumed relative to symptoms",
                impact: 0.7
            ))
        }
        
        if title.contains("stress") || description.contains("stress") {
            factors.append(ContributingFactor(
                name: "Stress Levels",
                description: "Daily stress and anxiety levels",
                impact: 0.6
            ))
        }
        
        if title.contains("exercise") || description.contains("exercise") {
            factors.append(ContributingFactor(
                name: "Physical Activity",
                description: "Exercise frequency and intensity",
                impact: 0.5
            ))
        }
        
        if title.contains("sleep") || description.contains("sleep") {
            factors.append(ContributingFactor(
                name: "Sleep Quality",
                description: "Duration and quality of sleep",
                impact: 0.7
            ))
        }
        
        // If no specific factors were identified, add a generic one
        if factors.isEmpty {
            factors.append(ContributingFactor(
                name: "Data Correlation",
                description: "Pattern correlation strength",
                impact: confidenceLevel
            ))
        }
        
        return factors
    }
}
