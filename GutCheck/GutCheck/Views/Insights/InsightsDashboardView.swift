import SwiftUI

/// Comprehensive insights dashboard showing food triggers, patterns, and recommendations
struct InsightsDashboardView: View {
    @State private var insightsService = InsightsService.shared
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    InsightsDashboardHeaderSection()
                    
                    InsightsDashboardTimeRangeSelector(selectedTimeRange: $selectedTimeRange)
                    
                    InsightsDashboardSummaryStats(insights: insightsService.recentInsights)
                    
                    InsightsDashboardContent(
                        insights: insightsService.recentInsights,
                        selectedCategory: $selectedCategory
                    )
                }
                .padding()
            }
            .navigationTitle("Health Insights")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshInsights()
            }
            .task {
                await refreshInsights()
            }
            .onChange(of: selectedTimeRange) { _, _ in
                Task {
                    await refreshInsights()
                }
            }
        }
    }
    
    private func refreshInsights() async {
        await insightsService.generateRecentInsights()
    }
}

// MARK: - Header Section

struct InsightsDashboardHeaderSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discover patterns in your health data")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Get personalized insights and recommendations based on your symptoms, meals, and daily activities.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Time Range Selector

struct InsightsDashboardTimeRangeSelector: View {
    @Binding var selectedTimeRange: InsightsDashboardView.TimeRange
    
    var body: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(InsightsDashboardView.TimeRange.allCases) { timeRange in
                Text(timeRange.displayName).tag(timeRange)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Summary Statistics

struct InsightsDashboardSummaryStats: View {
    let insights: [HealthInsight]
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Total Insights",
                value: "\(insights.count)",
                icon: "lightbulb.fill",
                color: .blue
            )
            
            StatCard(
                title: "Food Triggers",
                value: "\(insights.filter { $0.title.lowercased().contains("food") || $0.title.lowercased().contains("dairy") || $0.title.lowercased().contains("gluten") }.count)",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
            
            StatCard(
                title: "Patterns",
                value: "\(insights.filter { $0.title.lowercased().contains("pattern") || $0.title.lowercased().contains("correlation") }.count)",
                icon: "chart.bar.fill",
                color: .green
            )
        }
    }
}

// MARK: - Insights Content

struct InsightsDashboardContent: View {
    let insights: [HealthInsight]
    @Binding var selectedCategory: InsightCategory?
    
    private var foodTriggerInsights: [HealthInsight] {
        insights.filter { $0.title.lowercased().contains("food") || $0.title.lowercased().contains("dairy") || $0.title.lowercased().contains("gluten") }
    }
    
    private var temporalPatternInsights: [HealthInsight] {
        insights.filter { $0.title.lowercased().contains("pattern") || $0.title.lowercased().contains("timing") }
    }
    
    private var lifestyleCorrelationInsights: [HealthInsight] {
        insights.filter { $0.title.lowercased().contains("correlation") || $0.title.lowercased().contains("activity") }
    }
    
    private var nutritionTrendInsights: [HealthInsight] {
        insights.filter { $0.title.lowercased().contains("nutrition") || $0.title.lowercased().contains("trend") }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            if insights.isEmpty {
                InsightsDashboardEmptyState()
            } else {
                InsightsDashboardCategoryFilter(selectedCategory: $selectedCategory)
                
                if !foodTriggerInsights.isEmpty {
                    InsightsDashboardFoodTriggers(insights: foodTriggerInsights)
                }
                
                if !temporalPatternInsights.isEmpty {
                    InsightsDashboardTemporalPatterns(insights: temporalPatternInsights)
                }
                
                if !lifestyleCorrelationInsights.isEmpty {
                    InsightsDashboardLifestyleCorrelations(insights: lifestyleCorrelationInsights)
                }
                
                if !nutritionTrendInsights.isEmpty {
                    InsightsDashboardNutritionTrends(insights: nutritionTrendInsights)
                }
            }
        }
    }
}

// MARK: - Category Filter

struct InsightsDashboardCategoryFilter: View {
    @Binding var selectedCategory: InsightCategory?
    
    var body: some View {
        ScrollView(.horizontal) {
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
        .scrollIndicators(.hidden)
    }
}

// MARK: - Section Views

struct InsightsDashboardFoodTriggers: View {
    let insights: [HealthInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Food Triggers",
                subtitle: "Foods that may be causing symptoms",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
            
            ForEach(insights) { insight in
                FoodTriggerCard(insight: insight)
            }
        }
    }
}

struct InsightsDashboardTemporalPatterns: View {
    let insights: [HealthInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Temporal Patterns",
                subtitle: "Time-based symptom patterns",
                icon: "clock.fill",
                color: .blue
            )
            
            ForEach(insights) { insight in
                TemporalPatternCard(insight: insight)
            }
        }
    }
}

struct InsightsDashboardLifestyleCorrelations: View {
    let insights: [HealthInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Lifestyle Correlations",
                subtitle: "How daily habits affect your health",
                icon: "heart.fill",
                color: .green
            )
            
            ForEach(insights) { insight in
                LifestyleCorrelationCard(insight: insight)
            }
        }
    }
}

struct InsightsDashboardNutritionTrends: View {
    let insights: [HealthInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Nutrition Trends",
                subtitle: "Dietary patterns and recommendations",
                icon: "chart.bar.fill",
                color: .purple
            )
            
            ForEach(insights) { insight in
                NutritionTrendCard(insight: insight)
            }
        }
    }
}

// MARK: - State Views

struct InsightsDashboardLoadingState: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing your health data...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
}

struct InsightsDashboardErrorState: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Unable to load insights")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
}

struct InsightsDashboardEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No insights yet")
                .font(.headline)
            
            Text("Start logging your symptoms and meals to generate personalized insights.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    InsightsDashboardView()
}
