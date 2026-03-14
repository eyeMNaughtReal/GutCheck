import SwiftUI

struct CategoryInsightsView: View {
    let category: InsightCategory
    @State private var viewModel = CategoryInsightsViewModel()
    
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
                .foregroundStyle(category.accentColor)
            
            Text(category.description)
                .font(.body)
                .foregroundStyle(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
    
    private var activeInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Insights")
                .font(.title2.bold())
                .foregroundStyle(ColorTheme.primaryText)
            
            ForEach(viewModel.activeInsights) { insight in
                NavigationLink(value: InsightsRoute.insightDetail(insight)) {
                    ActiveInsightRow(insight: insight)
                }
            }
        }
    }
    
    private var historicalInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Historical Insights")
                .font(.title2.bold())
                .foregroundStyle(ColorTheme.primaryText)
            
            ForEach(viewModel.historicalInsights) { insight in
                NavigationLink(value: InsightsRoute.insightDetail(insight)) {
                    HistoricalInsightRow(insight: insight)
                }
            }
        }
    }
    
    private var noInsightsMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(ColorTheme.secondaryText)
            
            Text("No Insights Yet")
                .font(.title3.bold())
                .foregroundStyle(ColorTheme.primaryText)
            
            Text("Keep logging your meals and symptoms. We'll analyze your data to provide insights in this category.")
                .font(.body)
                .foregroundStyle(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
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
                    .foregroundStyle(ColorTheme.accent)
                
                Text(insight.title)
                    .font(.headline)
                    .foregroundStyle(ColorTheme.primaryText)
                
                Spacer()
                
                Text("\(insight.confidenceLevel)%")
                    .font(.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }
            
            Text(insight.summary)
                .font(.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
                .lineLimit(2)
            
            HStack {
                Text(insight.dateRange)
                    .font(.caption)
                    .foregroundStyle(ColorTheme.accent)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(ColorTheme.secondaryText)
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}

private struct HistoricalInsightRow: View {
    let insight: HealthInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insight.iconName)
                    .font(.headline)
                    .foregroundStyle(ColorTheme.secondaryText)
                
                Text(insight.title)
                    .font(.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                
                Spacer()
                
                Text(insight.dateRange)
                    .font(.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }
            
            Text(insight.summary)
                .font(.caption)
                .foregroundStyle(ColorTheme.secondaryText)
                .lineLimit(1)
        }
        .padding()
        .background(ColorTheme.surface.opacity(0.5))
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CategoryInsightsView(category: .foodTriggers)
    }
}

