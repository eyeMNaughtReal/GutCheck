//
//  InsightsDashboardComponents.swift
//  GutCheck
//
//  Supporting view components for InsightsDashboardView.
//

import SwiftUI

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
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(.rect(cornerRadius: 12))
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
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(.rect(cornerRadius: 20))
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
                    .foregroundStyle(accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(insight.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                }
                
                Spacer()
            }
            
            // Confidence level
            HStack {
                Text("Confidence")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(insight.confidenceLevel)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                            .foregroundStyle(.primary)
                    }
                    
                    // Recommendations
                    if !insight.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recommendations")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            
                            ForEach(insight.recommendations, id: \.self) { recommendation in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                    
                                    Text(recommendation)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Date range
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(insight.dateRange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
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
                .foregroundStyle(accentColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
