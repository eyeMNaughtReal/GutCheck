
//  InsightsView.swift
//  GutCheck
//
//  Fixed to use correct navigation and User model
//

import SwiftUI

struct InsightsView: View {
    @Environment(AuthService.self) var authService
    @Environment(AppRouter.self) var router
    @State private var viewModel = InsightsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Weekly Stats Row
                weeklyStatsRow

                // Weekly Trigger Report Card
                if let report = viewModel.weeklyTriggerReport {
                    weeklyTriggerReportCard(report: report)
                }

                // Trigger Pattern Summaries
                if !viewModel.topTriggerPatterns.isEmpty {
                    triggerPatternSummarySection
                }

                // Safe Meal Suggestions Card
                if !viewModel.mealSuggestions.isEmpty {
                    mealSuggestionsCard
                }

                // Top Summary Cards
                topSymptomsCard
                triggerFoodsCard

                // Symptom Explorer Card
                symptomExplorerCard

                // Symptom Charts Card
                symptomChartsCard

                bestDaysCard

                // Recent Insights Section
                if !viewModel.recentInsights.isEmpty {
                    recentInsightsSection
                }
                
                // Categories Section
                insightCategoriesSection
                
                // Patterns Section
                if !viewModel.patterns.isEmpty {
                    patternsSection
                }
                
                // Recommendations Section
                if !viewModel.recommendations.isEmpty {
                    recommendationsSection
                }
            }
            .padding()
        }
        // Without this the view falls through to the system background and renders
        // black, while every other tab renders navy.
        .background(ColorTheme.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: InsightsRoute.self) { route in
            switch route {
            case .insightDetail(let insight):
                InsightDetailView(insight: insight)
            case .categoryInsights(let category):
                CategoryInsightsView(category: category)
            case .weeklyTriggerReport(let report):
                WeeklyTriggerReportView(report: report)
            case .triggerPatternDetail(let pattern):
                TriggerPatternDetailView(pattern: pattern)
            case .symptomExplorer:
                SymptomExplorerView()
            case .symptomCharts:
                SymptomChartsView()
            case .mealSuggestions(let suggestions):
                MealSuggestionsView(suggestions: suggestions)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ProfileAvatarButton(user: authService.currentUser) {
                    router.presentSheet(.profile)
                }
            }
        }
        .refreshable {
            await viewModel.loadInsights()
        }
        .task {
            await viewModel.loadInsights()
        }
    }
    
    // MARK: - View Components
    
    private var recentInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Insights")
                .font(.title2.bold())
                .foregroundStyle(ColorTheme.primaryText)
            
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(viewModel.recentInsights) { insight in
                        AnalyticsInsightCard(insight: insight)
                            .frame(width: 280, height: 160)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    private var insightCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.title2.bold())
                .foregroundStyle(ColorTheme.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(InsightCategory.allCases) { category in
                    CategoryCard(category: category)
                }
            }
        }
    }
    
    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Patterns")
                .font(.title2.bold())
                .foregroundStyle(ColorTheme.primaryText)
            
            ForEach(viewModel.patterns) { pattern in
                PatternRow(pattern: pattern)
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.title2.bold())
                .foregroundStyle(ColorTheme.primaryText)
            
            ForEach(viewModel.recommendations) { recommendation in
                RecommendationCard(recommendation: recommendation)
            }
        }
    }

    // MARK: - Summary Cards

    private var weeklyStatsRow: some View {
        HStack(spacing: 12) {
            WeeklyStatPill(
                icon: "fork.knife",
                value: "\(viewModel.weeklyMealCount)",
                label: "Meals",
                color: ColorTheme.primary
            )
            WeeklyStatPill(
                icon: "heart.text.clipboard",
                value: "\(viewModel.weeklySymptomCount)",
                label: "Symptoms",
                color: viewModel.weeklySymptomCount > 0 ? ColorTheme.warning : ColorTheme.success
            )
            WeeklyStatPill(
                icon: "calendar",
                value: "7d",
                label: "This Week",
                color: ColorTheme.accent
            )
        }
    }

    private func weeklyTriggerReportCard(report: WeeklyTriggerReport) -> some View {
        NavigationLink(value: InsightsRoute.weeklyTriggerReport(report)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .typography(Typography.title2)
                        .foregroundStyle(ColorTheme.accent)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Trigger Report")
                            .typography(Typography.headline)
                            .foregroundStyle(ColorTheme.primaryText)
                        Text(reportDateRange(report))
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(ColorTheme.secondaryText)
                }

                HStack(spacing: 12) {
                    TriggerCountPill(count: report.newTriggers.count, label: "New", color: .red)
                    TriggerCountPill(count: report.recurringTriggers.count, label: "Recurring", color: .orange)
                    TriggerCountPill(count: report.resolvedTriggers.count, label: "Resolved", color: ColorTheme.success)
                }
            }
            .padding()
            .background(ColorTheme.surface)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.weeklyTriggerReportCard)
    }

    private func reportDateRange(_ report: WeeklyTriggerReport) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: report.weekStart)
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "MMM d, yyyy"
        let end = endFormatter.string(from: report.weekEnd)
        return "\(start) – \(end)"
    }

    // MARK: - Trigger Pattern Summary

    private var triggerPatternSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Top Trigger Patterns", systemImage: "exclamationmark.triangle.fill")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            ForEach(Array(viewModel.topTriggerPatterns.enumerated()), id: \.element.id) { index, pattern in
                NavigationLink(value: InsightsRoute.triggerPatternDetail(pattern)) {
                    HStack(spacing: 12) {
                        // Score badge
                        ZStack {
                            Circle()
                                .fill(triggerScoreColor(pattern.triggerScore.overall).opacity(0.15))
                                .frame(width: 44, height: 44)
                            Text("\(pattern.triggerScore.overall)")
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(triggerScoreColor(pattern.triggerScore.overall))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(pattern.foodName)
                                .font(.subheadline.bold())
                                .foregroundStyle(ColorTheme.primaryText)

                            if let topInsight = pattern.summaryInsights.first {
                                Text(topInsight.headline)
                                    .typography(Typography.caption)
                                    .foregroundStyle(ColorTheme.secondaryText)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                    .padding(12)
                    .background(ColorTheme.surface)
                    .clipShape(.rect(cornerRadius: 12))
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Insights.triggerPatternCard(index))
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.triggerPatternSummarySection)
    }

    private func triggerScoreColor(_ score: Int) -> Color {
        if score >= 70 { return .red }
        if score >= 40 { return .orange }
        return .yellow
    }

    // MARK: - Meal Suggestions

    private var mealSuggestionsCard: some View {
        NavigationLink(value: InsightsRoute.mealSuggestions(viewModel.mealSuggestions)) {
            HStack(spacing: 12) {
                Image(systemName: "leaf.circle.fill")
                    .typography(Typography.title2)
                    .foregroundStyle(ColorTheme.success)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Safe Meal Ideas")
                        .typography(Typography.headline)
                        .foregroundStyle(ColorTheme.primaryText)
                    Text("\(viewModel.mealSuggestions.count) suggestions based on your history")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(ColorTheme.secondaryText)
            }
            .padding()
            .background(ColorTheme.surface)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.mealSuggestionsCard)
    }

    // MARK: - Symptom Charts

    private var symptomChartsCard: some View {
        NavigationLink(value: InsightsRoute.symptomCharts) {
            HStack(spacing: 12) {
                Image(systemName: "chart.xyaxis.line")
                    .typography(Typography.title2)
                    .foregroundStyle(ColorTheme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Symptom Charts")
                        .typography(Typography.headline)
                        .foregroundStyle(ColorTheme.primaryText)
                    Text("Interactive graphs and trends")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(ColorTheme.secondaryText)
            }
            .padding()
            .background(ColorTheme.surface)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.symptomChartsCard)
    }

    // MARK: - Symptom Explorer

    private var symptomExplorerCard: some View {
        NavigationLink(value: InsightsRoute.symptomExplorer) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .typography(Typography.title2)
                    .foregroundStyle(ColorTheme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Symptom Explorer")
                        .typography(Typography.headline)
                        .foregroundStyle(ColorTheme.primaryText)
                    Text("Investigate meals before symptoms")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(ColorTheme.secondaryText)
            }
            .padding()
            .background(ColorTheme.surface)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.symptomExplorerCard)
    }

    private var topSymptomsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Most Frequent Symptoms", systemImage: "chart.bar.fill")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            if viewModel.topSymptoms.isEmpty {
                Text("No symptoms logged this week")
                    .typography(Typography.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(viewModel.topSymptoms.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(rankColor(index)))

                        Text(item.name)
                            .typography(Typography.subheadline)
                            .foregroundStyle(ColorTheme.primaryText)

                        Spacer()

                        Text("\(item.count)×")
                            .font(.subheadline.bold())
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private var triggerFoodsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Top Triggering Foods", systemImage: "exclamationmark.triangle.fill")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            if viewModel.topTriggerFoods.isEmpty {
                Text("Not enough data to identify triggers yet")
                    .typography(Typography.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(viewModel.topTriggerFoods.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .typography(Typography.caption)
                            .foregroundStyle(rankColor(index))

                        Text(item.name)
                            .typography(Typography.subheadline)
                            .foregroundStyle(ColorTheme.primaryText)
                            .lineLimit(1)

                        Spacer()

                        Text("\(item.count) correlation\(item.count == 1 ? "" : "s")")
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private var bestDaysCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Best Days", systemImage: "checkmark.seal.fill")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            if viewModel.bestDays.isEmpty {
                Text("Log symptoms for a week to see your best days")
                    .typography(Typography.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(viewModel.bestDays.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(ColorTheme.success)

                        Text(item.name)
                            .typography(Typography.subheadline)
                            .foregroundStyle(ColorTheme.primaryText)

                        Spacer()

                        if item.count == 0 {
                            Text("Symptom-free")
                                .typography(Typography.caption)
                                .foregroundStyle(ColorTheme.success)
                        } else {
                            Text("Low symptoms")
                                .typography(Typography.caption)
                                .foregroundStyle(ColorTheme.secondaryText)
                        }
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        default: return .gray
        }
    }
}

// MARK: - Supporting Views

private struct WeeklyStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .typography(Typography.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(ColorTheme.primaryText)

            Text(label)
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

private struct AnalyticsInsightCard: View {
    let insight: HealthInsight
    
    var body: some View {
        NavigationLink(value: InsightsRoute.insightDetail(insight)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: insight.iconName)
                        .typography(Typography.title2)
                        .foregroundStyle(ColorTheme.accent)
                    
                    Spacer()
                    
                    Text("\(insight.confidenceLevel)%")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }
                
                Text(insight.title)
                    .typography(Typography.headline)
                    .foregroundStyle(ColorTheme.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(insight.summary)
                    .typography(Typography.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .lineLimit(2)
                
                Text(insight.dateRange)
                    .typography(Typography.caption)
                    .foregroundStyle(ColorTheme.accent)
            }
            .padding()
            .background(ColorTheme.surface)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
    }
}

private struct CategoryCard: View {
    let category: InsightCategory
    
    var body: some View {
        NavigationLink(value: InsightsRoute.categoryInsights(category)) {
            VStack(spacing: 12) {
                Image(systemName: category.iconName)
                    .typography(Typography.title)
                    .foregroundStyle(category.accentColor)
                
                Text(category.title)
                    .typography(Typography.headline)
                    .foregroundStyle(ColorTheme.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(category.description)
                    .typography(Typography.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    // 2 lines clipped "Get personalized suggestions…"; grid rows
                    // size to the tallest card, so letting it wrap costs nothing.
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
            .background(ColorTheme.surface)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
    }
}

private struct PatternRow: View {
    let pattern: HealthPattern
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: pattern.iconName)
                .typography(Typography.title2)
                .foregroundStyle(ColorTheme.accent)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.title)
                    .typography(Typography.headline)
                    .foregroundStyle(ColorTheme.primaryText)
                
                Text(pattern.description)
                    .typography(Typography.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(ColorTheme.secondaryText)
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}

private struct RecommendationCard: View {
    let recommendation: HealthRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: recommendation.iconName)
                    .typography(Typography.title2)
                    .foregroundStyle(ColorTheme.accent)
                
                Text(recommendation.title)
                    .typography(Typography.headline)
                    .foregroundStyle(ColorTheme.primaryText)
            }
            
            Text(recommendation.description)
                .typography(Typography.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
            
            if !recommendation.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recommendation.actionItems, id: \.self) { action in
                        Label(action, systemImage: "checkmark.circle")
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.accent)
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    InsightsView()
        .environment(AuthService())
        .environment(AppRouter.shared)
}

#Preview {
    InsightsView()
        .environment(AuthService())
}
