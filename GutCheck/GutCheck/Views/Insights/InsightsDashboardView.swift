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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
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
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
    
    private func errorSection(_ error: String) -> some View {
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
    
    // MARK: - Helper Methods
    
    private func refreshInsights() async {
        await insightsService.generateRecentInsights()
    }
}

#Preview {
    InsightsDashboardView()
}
