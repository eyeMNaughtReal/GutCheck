import SwiftUI

struct InsightDetailView: View {
    let insight: HealthInsight
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InsightDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                VStack(alignment: .leading, spacing: 16) {
                    InsightHeaderView(insight: insight)
                    
                    if let description = insight.detailedDescription {
                        Text(description)
                            .font(.body)
                            .foregroundColor(ColorTheme.text.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .roundedCard()
                
                // Data Visualization
                if !viewModel.chartData.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Trend Analysis")
                            .font(.title2)
                            .bold()
                        
                        // Simple chart placeholder
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ColorTheme.accent.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                Text("Chart Visualization")
                                    .foregroundColor(ColorTheme.accent)
                                    .font(.headline)
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .roundedCard()
                }
                
                // Contributing Factors
                if !viewModel.contributingFactors.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contributing Factors")
                            .font(.title2)
                            .bold()
                        
                        ForEach(viewModel.contributingFactors) { factor in
                            ContributingFactorRow(factor: factor)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .roundedCard()
                }
                
                // Recommendations
                if !insight.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recommendations")
                            .font(.title2)
                            .bold()
                        
                        ForEach(insight.recommendations, id: \.self) { recommendation in
                            RecommendationRow(text: recommendation)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .roundedCard()
                }
                
                // Related Insights
                if !viewModel.relatedInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Related Insights")
                            .font(.title2)
                            .bold()
                        
                        ForEach(viewModel.relatedInsights) { relatedInsight in
                            RelatedInsightRow(insight: relatedInsight)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .roundedCard()
                }
            }
            .padding()
        }
        .navigationTitle("Insight Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData(for: insight)
        }
    }
}

// MARK: - Supporting Views

private struct InsightHeaderView: View {
    let insight: HealthInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(insight.title, systemImage: insight.iconName)
                .font(.title2)
                .bold()
                .foregroundColor(ColorTheme.primary)
            
            Text(insight.summary)
                .font(.headline)
            
            HStack {
                Label("\(insight.confidenceLevel)% Confidence", 
                      systemImage: "chart.bar.fill")
                Spacer()
                Label(insight.dateRange, systemImage: "calendar")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
    }
}

private struct ContributingFactorRow: View {
    let factor: ContributingFactor
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(factor.name)
                    .font(.headline)
                Text(factor.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(factor.impact * 100))%")
                .font(.headline)
                .foregroundColor(impactColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
    
    private var impactColor: Color {
        switch factor.impact {
        case 0.8...: return .red
        case 0.6...: return .orange
        case 0.4...: return .yellow
        default: return .green
        }
    }
}

private struct RecommendationRow: View {
    let text: String
    
    var body: some View {
        Label(text, systemImage: "checkmark.circle")
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }
}

private struct RelatedInsightRow: View {
    let insight: HealthInsight
    
    var body: some View {
        NavigationLink(destination: InsightDetailView(insight: insight)) {
            HStack {
                Label(insight.title, systemImage: insight.iconName)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Supporting Types

struct HealthInsight: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let detailedDescription: String?
    let iconName: String
    let confidenceLevel: Int
    let dateRange: String
    let recommendations: [String]
}

struct ContributingFactor: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let impact: Double
}

#Preview {
    NavigationView {
        InsightDetailView(insight: HealthInsight(
            title: "Dairy Sensitivity Pattern",
            summary: "Strong correlation between dairy consumption and bloating",
            detailedDescription: "Analysis shows symptoms typically occur 2-4 hours after consuming dairy products, particularly with high-fat items.",
            iconName: "stomach",
            confidenceLevel: 85,
            dateRange: "Last 30 Days",
            recommendations: [
                "Consider lactose-free alternatives",
                "Try smaller portions to test tolerance",
                "Keep track of different dairy types separately"
            ]
        ))
    }
}
