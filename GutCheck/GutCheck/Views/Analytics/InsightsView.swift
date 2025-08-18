
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
                .foregroundColor(ColorTheme.primaryText)
            
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
                .foregroundColor(ColorTheme.primaryText)
            
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
                .foregroundColor(ColorTheme.primaryText)
            
            ForEach(viewModel.patterns) { pattern in
                PatternRow(pattern: pattern)
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.title2.bold())
                .foregroundColor(ColorTheme.primaryText)
            
            ForEach(viewModel.recommendations) { recommendation in
                RecommendationCard(recommendation: recommendation)
            }
        }
    }
}

// MARK: - Supporting Views

private struct AnalyticsInsightCard: View {
    let insight: HealthInsight
    
    var body: some View {
        NavigationLink(destination: InsightDetailView(insight: insight)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: insight.iconName)
                        .font(.title2)
                        .foregroundColor(ColorTheme.accent)
                    
                    Spacer()
                    
                    Text("\(insight.confidenceLevel)%")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                Text(insight.title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(insight.summary)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
                    .lineLimit(2)
                
                Text(insight.dateRange)
                    .font(.caption)
                    .foregroundColor(ColorTheme.accent)
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
                    .foregroundColor(category.accentColor)
                
                Text(category.title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
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
                .foregroundColor(ColorTheme.accent)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(pattern.description)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(ColorTheme.secondaryText)
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
                    .foregroundColor(ColorTheme.accent)
                
                Text(recommendation.title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
            }
            
            Text(recommendation.description)
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
            
            if !recommendation.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recommendation.actionItems, id: \.self) { action in
                        Label(action, systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(ColorTheme.accent)
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
