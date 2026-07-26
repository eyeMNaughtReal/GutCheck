//
//  TriggerPatternDetailView.swift
//  GutCheck
//
//  Detail view showing a food's full trigger profile with scoring,
//  severity prediction, ingredient breakdown, and summary insights.
//

import SwiftUI

struct TriggerPatternDetailView: View {
    let pattern: TriggerPattern
    @State private var viewModel = TriggerPatternDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                triggerScoreHeader
                if !pattern.summaryInsights.isEmpty { summaryInsightsSection }
                severityDistributionCard
                timingProfileCard
                if !pattern.ingredientBreakdown.isEmpty { ingredientBreakdownSection }
                scoreBreakdownCard
                if !pattern.recommendations.isEmpty { recommendationsSection }
                if !viewModel.relatedPatterns.isEmpty { relatedTriggersSection }
            }
            .padding()
        }
        .navigationTitle(pattern.foodName)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.triggerPatternDetailView)
    }

    // MARK: - Header

    private var triggerScoreHeader: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pattern.foodName)
                        .font(.title2.bold())
                        .foregroundStyle(ColorTheme.primaryText)

                    Text("\(pattern.triggeringObservations) of \(pattern.totalObservations) observations triggered symptoms")
                        .typography(Typography.subheadline)
                        .foregroundStyle(ColorTheme.secondaryText)

                    severityBadge
                }

                Spacer()

                // Trigger score gauge
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 72, height: 72)
                    Circle()
                        .trim(from: 0, to: Double(pattern.triggerScore.overall) / 100.0)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(pattern.triggerScore.overall)")
                            .font(.title3.bold())
                            .foregroundStyle(scoreColor)
                        Text("Score")
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                }
            }

            if !pattern.associatedSymptomLabels.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(pattern.associatedSymptomLabels, id: \.self) { label in
                            Text(label)
                                .typography(Typography.caption)
                                .foregroundStyle(scoreColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(scoreColor.opacity(0.1)))
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

    // MARK: - Summary Insights

    private var summaryInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Key Findings", systemImage: "lightbulb.fill")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            ForEach(pattern.summaryInsights) { insight in
                VStack(alignment: .leading, spacing: 6) {
                    Text(insight.headline)
                        .font(.subheadline.bold())
                        .foregroundStyle(ColorTheme.primaryText)

                    Text(insight.detail)
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)

                    HStack {
                        Text("\(insight.dataPoints) data points")
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.secondaryText)

                        Spacer()

                        Text("\(Int(insight.confidence * 100))% confidence")
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.accent)
                    }
                }
                .padding(12)
                .background(ColorTheme.accent.opacity(0.05))
                .clipShape(.rect(cornerRadius: 8))
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Severity Distribution

    private var severityDistributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Severity Distribution", systemImage: "chart.bar.fill")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            VStack(spacing: 8) {
                severityBar(label: "Severe", value: pattern.severityPrediction.painDistribution[.severe] ?? 0, color: .red)
                severityBar(label: "Moderate", value: pattern.severityPrediction.painDistribution[.moderate] ?? 0, color: .orange)
                severityBar(label: "Mild", value: pattern.severityPrediction.painDistribution[.mild] ?? 0, color: .yellow)
                severityBar(label: "None", value: pattern.severityPrediction.painDistribution[.none] ?? 0, color: .gray)
            }

            if pattern.severityPrediction.stoolRisk != .normal {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .typography(Typography.caption)
                    Text("Stool risk: \(pattern.severityPrediction.stoolRisk.rawValue)")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private func severityBar(label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
                .frame(width: 60, alignment: .trailing)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.3))
                    .frame(width: geo.size.width)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: max(0, geo.size.width * value))
                    }
            }
            .frame(height: 16)

            Text("\(Int(value * 100))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(ColorTheme.secondaryText)
                .frame(width: 36, alignment: .trailing)
        }
    }

    // MARK: - Timing Profile

    private var timingProfileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Timing Profile", systemImage: "clock.fill")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            HStack(spacing: 0) {
                timingStat(label: "Avg", value: pattern.timingProfile.averageOnsetHours)
                Divider().frame(height: 40)
                timingStat(label: "Median", value: pattern.timingProfile.medianOnsetHours)
                Divider().frame(height: 40)
                timingStat(label: "Min", value: pattern.timingProfile.minOnsetHours)
                Divider().frame(height: 40)
                timingStat(label: "Max", value: pattern.timingProfile.maxOnsetHours)
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private func timingStat(label: String, value: Double) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", value))
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(ColorTheme.primaryText)
            Text(label)
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
            Text("hours")
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ingredient Breakdown

    private var ingredientBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ingredient Analysis", systemImage: "leaf.fill")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            ForEach(pattern.ingredientBreakdown) { ingredient in
                HStack(spacing: 12) {
                    Circle()
                        .fill(ingredient.severity.borderColor)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(ingredient.ingredientName)
                            .font(.subheadline.bold())
                            .foregroundStyle(ColorTheme.primaryText)

                        if let category = ingredient.compoundCategory {
                            Text(category)
                                .typography(Typography.caption)
                                .foregroundStyle(ColorTheme.secondaryText)
                        }
                    }

                    Spacer()

                    ProgressView(value: ingredient.correlationScore)
                        .tint(ingredient.severity.borderColor)
                        .frame(width: 50)

                    Text("\(Int(ingredient.correlationScore * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(ColorTheme.secondaryText)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Score Breakdown

    private var scoreBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Trigger Score Breakdown", systemImage: "gauge.with.dots.needle.33percent")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            scoreRow(label: "Correlation", value: pattern.triggerScore.correlationComponent, color: .blue)
            scoreRow(label: "Severity", value: pattern.triggerScore.severityComponent, color: .red)
            scoreRow(label: "Recurrence", value: pattern.triggerScore.recurrenceComponent, color: .orange)
            scoreRow(label: "Compound Risk", value: pattern.triggerScore.compoundRiskComponent, color: .purple)
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private func scoreRow(label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
                .frame(width: 100, alignment: .trailing)

            ProgressView(value: value)
                .tint(color)

            Text("\(Int(value * 100))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(ColorTheme.secondaryText)
                .frame(width: 36, alignment: .trailing)
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recommendations", systemImage: "lightbulb.fill")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            ForEach(pattern.recommendations, id: \.self) { rec in
                Label(rec, systemImage: "checkmark.circle")
                    .typography(Typography.subheadline)
                    .foregroundStyle(ColorTheme.accent)
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Related Triggers

    private var relatedTriggersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Related Triggers", systemImage: "link")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            Text("Foods sharing similar compounds")
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)

            ForEach(viewModel.relatedPatterns) { related in
                NavigationLink(value: InsightsRoute.triggerPatternDetail(related)) {
                    HStack {
                        Text(related.foodName)
                            .typography(Typography.subheadline)
                            .foregroundStyle(ColorTheme.primaryText)

                        Spacer()

                        Text("Score: \(related.triggerScore.overall)")
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.secondaryText)

                        Image(systemName: "chevron.right")
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Helpers

    private var scoreColor: Color {
        let score = pattern.triggerScore.overall
        if score >= 70 { return .red }
        if score >= 40 { return .orange }
        return .yellow
    }

    private var severityBadge: some View {
        let prediction = pattern.severityPrediction
        let painLabel: String = {
            switch prediction.mostLikelyPainLevel {
            case .severe: return "Severe"
            case .moderate: return "Moderate"
            case .mild: return "Mild"
            case .none: return "No Pain"
            }
        }()

        return Text("Likely: \(painLabel) pain")
            .typography(Typography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(scoreColor.opacity(0.8)))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TriggerPatternDetailView(pattern: TriggerPattern(
            id: UUID(),
            foodName: "Dairy Milk",
            triggerScore: TriggerScore(
                overall: 72,
                correlationComponent: 0.8,
                severityComponent: 0.65,
                recurrenceComponent: 0.7,
                compoundRiskComponent: 0.45
            ),
            severityPrediction: SeverityPrediction(
                mostLikelyPainLevel: .moderate,
                mostLikelyUrgencyLevel: .moderate,
                painDistribution: [.none: 0.1, .mild: 0.2, .moderate: 0.5, .severe: 0.2],
                urgencyDistribution: [.none: 0.2, .mild: 0.3, .moderate: 0.4, .urgent: 0.1],
                stoolRisk: .loose,
                confidence: 0.5
            ),
            ingredientBreakdown: [
                IngredientTriggerBreakdown(id: UUID(), ingredientName: "Lactose", compoundName: "Lactose", compoundCategory: "Food Intolerances", correlationScore: 0.85, severity: .high, occurrenceCount: 6),
                IngredientTriggerBreakdown(id: UUID(), ingredientName: "Casein", compoundName: "Casein", compoundCategory: "Food Intolerances", correlationScore: 0.6, severity: .medium, occurrenceCount: 4)
            ],
            timingProfile: TimingProfile(averageOnsetHours: 3.2, medianOnsetHours: 3.0, minOnsetHours: 2.1, maxOnsetHours: 5.5),
            summaryInsights: [
                TriggerSummaryInsight(id: UUID(), headline: "Dairy Milk frequently leads to moderate-severe pain", detail: "In 7 of 10 instances (70%), Dairy Milk was followed by moderate or severe pain within 3.2 hours.", dataPoints: 10, confidence: 0.8),
                TriggerSummaryInsight(id: UUID(), headline: "Symptoms typically appear 3.2h after Dairy Milk", detail: "Onset ranges from 2.1 to 5.5 hours, with a median of 3.0 hours.", dataPoints: 10, confidence: 0.8),
                TriggerSummaryInsight(id: UUID(), headline: "Dairy Milk often causes urgent bowel movements", detail: "50% of instances involved moderate or high urgency.", dataPoints: 10, confidence: 0.8)
            ],
            associatedSymptomLabels: ["Moderate Pain", "Severe Pain", "Moderate Urgency", "Loose Stool"],
            totalObservations: 14,
            triggeringObservations: 10,
            recommendations: [
                "Consider eliminating Dairy Milk for 2-4 weeks",
                "Consult a healthcare professional about Dairy Milk sensitivity",
                "High-risk compounds detected: Lactose, Casein",
                "Reintroduce gradually to confirm sensitivity"
            ],
            lastOccurrence: .now,
            firstOccurrence: Calendar.current.date(byAdding: .day, value: -25, to: .now)!,
            trendDirection: .stable
        ))
    }
}
