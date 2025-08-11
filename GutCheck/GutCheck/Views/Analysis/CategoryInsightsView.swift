import SwiftUI

struct CategoryInsightsView: View {
    let category: InsightCategory
    @StateObject private var viewModel = CategoryInsightsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Category Header
                categoryHeader
                
                // Active Insights
                if !viewModel.activeInsights.isEmpty {
                    activeInsightsSection
                }
                
                // Historical Insights
                if !viewModel.historicalInsights.isEmpty {
                    historicalInsightsSection
                }
                
                // No Insights Message
                if viewModel.activeInsights.isEmpty && viewModel.historicalInsights.isEmpty {
                    noInsightsMessage
                }
            }
            .padding()
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadInsights(for: category)
        }
    }
    
    private var categoryHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: category.iconName)
                .font(.system(size: 48))
                .foregroundColor(category.accentColor)
            
            Text(category.description)
                .font(.body)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
    
    private var activeInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Insights")
                .font(.title2.bold())
                .foregroundColor(ColorTheme.primaryText)
            
            ForEach(viewModel.activeInsights) { insight in
                NavigationLink(destination: InsightDetailView(insight: insight)) {
                    ActiveInsightRow(insight: insight)
                }
            }
        }
    }
    
    private var historicalInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Historical Insights")
                .font(.title2.bold())
                .foregroundColor(ColorTheme.primaryText)
            
            ForEach(viewModel.historicalInsights) { insight in
                NavigationLink(destination: InsightDetailView(insight: insight)) {
                    HistoricalInsightRow(insight: insight)
                }
            }
        }
    }
    
    private var noInsightsMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(ColorTheme.secondaryText)
            
            Text("No Insights Yet")
                .font(.title3.bold())
                .foregroundColor(ColorTheme.primaryText)
            
            Text("Keep logging your meals and symptoms. We'll analyze your data to provide insights in this category.")
                .font(.body)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

private struct ActiveInsightRow: View {
    let insight: HealthInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.iconName)
                    .font(.title2)
                    .foregroundColor(ColorTheme.accent)
                
                Text(insight.title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                Text("\(insight.confidenceLevel)%")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Text(insight.summary)
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
                .lineLimit(2)
            
            HStack {
                Text(insight.dateRange)
                    .font(.caption)
                    .foregroundColor(ColorTheme.accent)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(ColorTheme.secondaryText)
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
}

private struct HistoricalInsightRow: View {
    let insight: HealthInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insight.iconName)
                    .font(.headline)
                    .foregroundColor(ColorTheme.secondaryText)
                
                Text(insight.title)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
                
                Spacer()
                
                Text(insight.dateRange)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Text(insight.summary)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
                .lineLimit(1)
        }
        .padding()
        .background(ColorTheme.surface.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        CategoryInsightsView(category: .foodTriggers)
    }
}

