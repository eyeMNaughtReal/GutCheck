import SwiftUI

/// Comprehensive insights dashboard showing food triggers, patterns, and recommendations
struct InsightsDashboardView: View {
    @StateObject private var insightsService = InsightsService.shared
    @State private var selectedTimeRange: TimeRange = .last30Days
    @State private var selectedCategory: InsightCategory? = nil
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
        case custom = "Custom Range"
        
        var id: String { rawValue }
        
        var days: Int {
            switch self {
            case .last7Days: return 7
            case .last30Days: return 30
            case .last90Days: return 90
            case .custom: return 30
            }
        }
        
        var displayName: String {
            switch self {
            case .last7Days: return "Last 7 Days"
            case .last30Days: return "Last 30 Days"
            case .last90Days: return "Last 90 Days"
            case .custom: return "Custom Range"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Time range selector
                    timeRangeSelector
                    
                    // Summary statistics
                    summaryStatsSection
                    
                    // Insights content
                    insightsContent
                }
                .padding()
            }
            .navigationTitle("Health Insights")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshInsights()
            }
            .onAppear {
                Task {
                    await refreshInsights()
                }
            }
            .onChange(of: selectedTimeRange) { _, _ in
                Task {
                    await refreshInsights()
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discover patterns in your health data")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Get personalized insights and recommendations based on your symptoms, meals, and daily activities.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Time Range Selector
    
    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases) { timeRange in
                Text(timeRange.displayName).tag(timeRange)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Summary Statistics
    
    private var summaryStatsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Total Insights",
                value: "\(insightsService.recentInsights.count)",
                icon: "lightbulb.fill",
                color: .blue
            )
            
            StatCard(
                title: "Food Triggers",
                value: "\(insightsService.recentInsights.filter { $0.title.lowercased().contains("food") || $0.title.lowercased().contains("dairy") || $0.title.lowercased().contains("gluten") }.count)",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
            
            StatCard(
                title: "Patterns",
                value: "\(insightsService.recentInsights.filter { $0.title.lowercased().contains("pattern") || $0.title.lowercased().contains("correlation") }.count)",
                icon: "chart.bar.fill",
                color: .green
            )
        }
    }
    
    // MARK: - Insights Content
    
    private var insightsContent: some View {
        VStack(spacing: 24) {
            if insightsService.recentInsights.isEmpty {
                emptyStateSection
            } else {
                // Category filter
                categoryFilterSection
                
                // Food triggers section
                if !foodTriggerInsights.isEmpty {
                    foodTriggersSection
                }
                
                // Temporal patterns section
                if !temporalPatternInsights.isEmpty {
                    temporalPatternsSection
                }
                
                // Lifestyle correlations section
                if !lifestyleCorrelationInsights.isEmpty {
                    lifestyleCorrelationsSection
                }
                
                // Nutrition trends section
                if !nutritionTrendInsights.isEmpty {
                    nutritionTrendsSection
                }
            }
        }
    }
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryFilterButton(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                ForEach(InsightCategory.allCases) { category in
                    CategoryFilterButton(
                        title: category.title,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Food Triggers Section
    
    private var foodTriggerInsights: [HealthInsight] {
        insightsService.recentInsights.filter { $0.title.lowercased().contains("food") || $0.title.lowercased().contains("dairy") || $0.title.lowercased().contains("gluten") }
    }
    
    private var foodTriggersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Food Triggers",
                subtitle: "Foods that may be causing symptoms",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
            
            ForEach(foodTriggerInsights) { insight in
                FoodTriggerCard(insight: insight)
            }
        }
    }
    
    // MARK: - Temporal Patterns Section
    
    private var temporalPatternInsights: [HealthInsight] {
        insightsService.recentInsights.filter { $0.title.lowercased().contains("pattern") || $0.title.lowercased().contains("timing") }
    }
    
    private var temporalPatternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Temporal Patterns",
                subtitle: "Time-based symptom patterns",
                icon: "clock.fill",
                color: .blue
            )
            
            ForEach(temporalPatternInsights) { insight in
                TemporalPatternCard(insight: insight)
            }
        }
    }
    
    // MARK: - Lifestyle Correlations Section
    
    private var lifestyleCorrelationInsights: [HealthInsight] {
        insightsService.recentInsights.filter { $0.title.lowercased().contains("correlation") || $0.title.lowercased().contains("activity") }
    }
    
    private var lifestyleCorrelationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Lifestyle Correlations",
                subtitle: "How daily habits affect your health",
                icon: "heart.fill",
                color: .green
            )
            
            ForEach(lifestyleCorrelationInsights) { insight in
                LifestyleCorrelationCard(insight: insight)
            }
        }
    }
    
    // MARK: - Nutrition Trends Section
    
    private var nutritionTrendInsights: [HealthInsight] {
        insightsService.recentInsights.filter { $0.title.lowercased().contains("nutrition") || $0.title.lowercased().contains("trend") }
    }
    
    private var nutritionTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Nutrition Trends",
                subtitle: "Dietary patterns and recommendations",
                icon: "chart.bar.fill",
                color: .purple
            )
            
            ForEach(nutritionTrendInsights) { insight in
                NutritionTrendCard(insight: insight)
            }
        }
    }
    
    // MARK: - Loading & Error States
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing your health data...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
    
    private func errorSection(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Unable to load insights")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task {
                    await refreshInsights()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No insights yet")
                .font(.headline)
            
            Text("Start logging your symptoms and meals to generate personalized insights.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Helper Methods
    
    private func refreshInsights() async {
        await insightsService.generateRecentInsights()
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Insight Cards

struct FoodTriggerCard: View {
    let insight: HealthInsight
    @State private var isExpanded = false
    
    var body: some View {
        InsightCard(insight: insight, isExpanded: $isExpanded, accentColor: .red)
    }
}

struct TemporalPatternCard: View {
    let insight: HealthInsight
    @State private var isExpanded = false
    
    var body: some View {
        InsightCard(insight: insight, isExpanded: $isExpanded, accentColor: .blue)
    }
}

struct LifestyleCorrelationCard: View {
    let insight: HealthInsight
    @State private var isExpanded = false
    
    var body: some View {
        InsightCard(insight: insight, isExpanded: $isExpanded, accentColor: .green)
    }
}

struct NutritionTrendCard: View {
    let insight: HealthInsight
    @State private var isExpanded = false
    
    var body: some View {
        InsightCard(insight: insight, isExpanded: $isExpanded, accentColor: .purple)
    }
}

struct InsightCard: View {
    let insight: HealthInsight
    @Binding var isExpanded: Bool
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: insight.iconName)
                    .font(.title2)
                    .foregroundColor(accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(insight.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                }
                
                Spacer()
            }
            
            // Confidence level
            HStack {
                Text("Confidence")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(insight.confidenceLevel)%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Confidence bar
            ProgressView(value: Double(insight.confidenceLevel), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: accentColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Detailed description
                    if let detailedDescription = insight.detailedDescription {
                        Text(detailedDescription)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    // Recommendations
                    if !insight.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recommendations")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            
                            ForEach(insight.recommendations, id: \.self) { recommendation in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                    
                                    Text(recommendation)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Date range
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(insight.dateRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            
            // Expand/collapse button
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(accentColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    InsightsDashboardView()
}
