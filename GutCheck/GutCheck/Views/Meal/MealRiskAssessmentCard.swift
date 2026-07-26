//
//  MealRiskAssessmentCard.swift
//  GutCheck
//
//  Collapsible card showing meal risk assessment with per-food breakdowns.
//

import SwiftUI

struct MealRiskAssessmentCard: View {
    let assessment: MealRiskAssessment
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header (always visible, tappable to expand)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
                HapticManager.shared.light()
            }) {
                headerContent
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.riskAssessmentHeader)

            // MARK: - Expanded Details
            if isExpanded {
                Divider()
                    .padding(.horizontal)

                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.riskAssessmentCard)
        .accessibleGroup(
            label: "Risk Assessment: \(assessment.overallRiskLevel.displayName) risk, score \(assessment.overallRiskScore). \(assessment.overallExplanation)",
            hint: "Tap to \(isExpanded ? "collapse" : "expand") risk details"
        )
    }

    // MARK: - Header

    private var headerContent: some View {
        HStack(spacing: 12) {
            Image(systemName: assessment.overallRiskLevel.icon)
                .typography(Typography.title2)
                .foregroundStyle(assessment.overallRiskLevel.color)

            VStack(alignment: .leading, spacing: 4) {
                Text("Risk Assessment")
                    .typography(Typography.headline)
                    .foregroundStyle(ColorTheme.primaryText)

                Text(assessment.overallExplanation)
                    .typography(Typography.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            riskScoreBadge

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
        }
    }

    private var riskScoreBadge: some View {
        Text("\(assessment.overallRiskScore)")
            .typography(Typography.headline)
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(assessment.overallRiskLevel.color)
            .clipShape(Circle())
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 12) {
            if !assessment.hasHistoricalData {
                noHistoryBanner
            }

            ForEach(assessment.foodItemRisks) { itemRisk in
                foodItemRiskRow(itemRisk)
            }
        }
        .padding(.top, 12)
    }

    private var noHistoryBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(ColorTheme.info)
            Text("Risk based on food compound analysis. Log more meals to get personalized predictions.")
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
        }
        .padding(10)
        .background(ColorTheme.info.opacity(0.1))
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.riskAssessmentNoHistory)
    }

    private func foodItemRiskRow(_ itemRisk: FoodItemRiskDetail) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(itemRisk.riskLevel.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(itemRisk.foodName)
                        .typography(Typography.subheadline)
                        .foregroundStyle(ColorTheme.primaryText)

                    Spacer()

                    if itemRisk.dataSource == .historicalCorrelation || itemRisk.dataSource == .combined {
                        Image(systemName: "person.fill")
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.primary)
                    }

                    Text("\(itemRisk.riskScore)")
                        .typography(Typography.caption)
                        .foregroundStyle(itemRisk.riskLevel.color)
                        .bold()
                }

                Text(itemRisk.explanation)
                    .typography(Typography.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(itemRisk.foodName): \(itemRisk.riskLevel.displayName) risk, score \(itemRisk.riskScore). \(itemRisk.explanation)")
    }

    // MARK: - Styling

    private var cardBackgroundColor: Color {
        switch assessment.overallRiskLevel {
        case .low: return ColorTheme.surface
        case .moderate: return ColorTheme.warning.opacity(0.05)
        case .high: return ColorTheme.error.opacity(0.05)
        }
    }

    private var borderColor: Color {
        switch assessment.overallRiskLevel {
        case .low: return ColorTheme.border
        case .moderate: return ColorTheme.warning.opacity(0.3)
        case .high: return ColorTheme.error.opacity(0.3)
        }
    }
}
