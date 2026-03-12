
//  InsightsView.swift
//  GutCheck
//
//  Fixed to use correct navigation and User model
//

import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = InsightsViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Weekly Stats Row
                    weeklyStatsRow

                    // Top Summary Cards
                    topSymptomsCard
                    triggerFoodsCard
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
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
    }
    
    // MARK: - View Components
    
    private var recentInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Insights")
                .font(.title2.bold())
                .foregroundStyle(ColorTheme.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.recentInsights) { insight in
                        AnalyticsInsightCard(insight: insight)
                            .frame(width: 280, height: 160)
                    }
                }
            }
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

    private var topSymptomsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Most Frequent Symptoms", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(ColorTheme.primaryText)

            if viewModel.topSymptoms.isEmpty {
                Text("No symptoms logged this week")
                    .font(.subheadline)
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
                            .font(.subheadline)
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
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private var triggerFoodsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Top Triggering Foods", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(ColorTheme.primaryText)

            if viewModel.topTriggerFoods.isEmpty {
                Text("Not enough data to identify triggers yet")
                    .font(.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(viewModel.topTriggerFoods.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(rankColor(index))

                        Text(item.name)
                            .font(.subheadline)
                            .foregroundStyle(ColorTheme.primaryText)
                            .lineLimit(1)

                        Spacer()

                        Text("\(item.count) correlation\(item.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private var bestDaysCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Best Days", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(ColorTheme.primaryText)

            if viewModel.bestDays.isEmpty {
                Text("Log symptoms for a week to see your best days")
                    .font(.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(viewModel.bestDays.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(ColorTheme.success)

                        Text(item.name)
                            .font(.subheadline)
                            .foregroundStyle(ColorTheme.primaryText)

                        Spacer()

                        if item.count == 0 {
                            Text("Symptom-free")
                                .font(.caption)
                                .foregroundStyle(ColorTheme.success)
                        } else {
                            Text("Low symptoms")
                                .font(.caption)
                                .foregroundStyle(ColorTheme.secondaryText)
                        }
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
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
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(ColorTheme.primaryText)

            Text(label)
                .font(.caption)
                .foregroundStyle(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(ColorTheme.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

private struct AnalyticsInsightCard: View {
    let insight: HealthInsight
    
    var body: some View {
        NavigationLink(destination: InsightDetailView(insight: insight)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: insight.iconName)
                        .font(.title2)
                        .foregroundStyle(ColorTheme.accent)
                    
                    Spacer()
                    
                    Text("\(insight.confidenceLevel)%")
                        .font(.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }
                
                Text(insight.title)
                    .font(.headline)
                    .foregroundStyle(ColorTheme.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(insight.summary)
                    .font(.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .lineLimit(2)
                
                Text(insight.dateRange)
                    .font(.caption)
                    .foregroundStyle(ColorTheme.accent)
            }
            .padding()
            .background(ColorTheme.surface)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
    }
}

private struct CategoryCard: View {
    let category: InsightCategory
    
    var body: some View {
        NavigationLink(destination: CategoryInsightsView(category: category)) {
            VStack(spacing: 12) {
                Image(systemName: category.iconName)
                    .font(.title)
                    .foregroundStyle(category.accentColor)
                
                Text(category.title)
                    .font(.headline)
                    .foregroundStyle(ColorTheme.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(category.description)
                    .font(.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
            .background(ColorTheme.surface)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
    }
}

private struct PatternRow: View {
    let pattern: HealthPattern
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: pattern.iconName)
                .font(.title2)
                .foregroundStyle(ColorTheme.accent)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.title)
                    .font(.headline)
                    .foregroundStyle(ColorTheme.primaryText)
                
                Text(pattern.description)
                    .font(.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(ColorTheme.secondaryText)
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
}

private struct RecommendationCard: View {
    let recommendation: HealthRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: recommendation.iconName)
                    .font(.title2)
                    .foregroundStyle(ColorTheme.accent)
                
                Text(recommendation.title)
                    .font(.headline)
                    .foregroundStyle(ColorTheme.primaryText)
            }
            
            Text(recommendation.description)
                .font(.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
            
            if !recommendation.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recommendation.actionItems, id: \.self) { action in
                        Label(action, systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(ColorTheme.accent)
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    InsightsView()
        .environmentObject(AuthService())
        .environmentObject(AppRouter.shared)
}

#Preview {
    InsightsView()
        .environmentObject(AuthService())
}
