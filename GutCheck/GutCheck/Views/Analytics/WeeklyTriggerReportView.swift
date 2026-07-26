//
//  WeeklyTriggerReportView.swift
//  GutCheck
//
//  Detail view for the weekly trigger report showing new, recurring, and resolved triggers.
//

import SwiftUI

struct WeeklyTriggerReportView: View {
    let report: WeeklyTriggerReport

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                reportHeader
                summaryStats
                if !report.newTriggers.isEmpty { newTriggersSection }
                if !report.recurringTriggers.isEmpty { recurringTriggersSection }
                if !report.resolvedTriggers.isEmpty { resolvedTriggersSection }
                symptomTrendCard
                recommendationsSection
            }
            .padding()
        }
        .navigationTitle("Weekly Report")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.weeklyTriggerReportView)
    }

    // MARK: - Header

    private var reportHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(ColorTheme.accent)

                Text("Weekly Trigger Report")
                    .font(.title2.bold())
                    .foregroundStyle(ColorTheme.primaryText)

                Spacer()

                TrendBadge(trend: report.symptomTrend)
            }

            Text(dateRangeString)
                .font(.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Summary Stats

    private var summaryStats: some View {
        HStack(spacing: 12) {
            TriggerCountPill(
                count: report.newTriggers.count,
                label: "New",
                color: .red
            )
            TriggerCountPill(
                count: report.recurringTriggers.count,
                label: "Recurring",
                color: .orange
            )
            TriggerCountPill(
                count: report.resolvedTriggers.count,
                label: "Resolved",
                color: ColorTheme.success
            )
        }
    }

    // MARK: - Trigger Sections

    private var newTriggersSection: some View {
        triggerSection(
            title: "New Triggers",
            icon: "exclamationmark.triangle.fill",
            accentColor: .red,
            triggers: report.newTriggers,
            badge: nil
        )
    }

    private var recurringTriggersSection: some View {
        triggerSection(
            title: "Recurring Triggers",
            icon: "arrow.triangle.2.circlepath",
            accentColor: .orange,
            triggers: report.recurringTriggers,
            badge: "2+ weeks"
        )
    }

    private var resolvedTriggersSection: some View {
        triggerSection(
            title: "Resolved Triggers",
            icon: "checkmark.circle.fill",
            accentColor: ColorTheme.success,
            triggers: report.resolvedTriggers,
            badge: "No longer detected"
        )
    }

    private func triggerSection(
        title: String,
        icon: String,
        accentColor: Color,
        triggers: [TriggerEntry],
        badge: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(accentColor)

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(accentColor.opacity(0.8)))
                }
            }

            ForEach(triggers) { trigger in
                TriggerEntryRow(trigger: trigger, accentColor: accentColor)
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Symptom Trend

    private var symptomTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Symptom Trend", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundStyle(ColorTheme.primaryText)

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(report.currentWeekSymptomCount)")
                        .font(.title.bold())
                        .foregroundStyle(ColorTheme.primaryText)
                    Text("This week")
                        .font(.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(ColorTheme.secondaryText)

                VStack(spacing: 4) {
                    Text("\(report.previousWeekSymptomCount)")
                        .font(.title.bold())
                        .foregroundStyle(ColorTheme.secondaryText)
                    Text("Last week")
                        .font(.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }

                Spacer()

                VStack(spacing: 4) {
                    TrendBadge(trend: report.symptomTrend)
                    if report.symptomChangePercentage != 0 {
                        Text("\(abs(report.symptomChangePercentage))%")
                            .font(.caption.bold())
                            .foregroundStyle(trendColor)
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        let allRecommendations = aggregatedRecommendations
        guard !allRecommendations.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Label("Recommendations", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundStyle(ColorTheme.primaryText)

                ForEach(allRecommendations, id: \.self) { recommendation in
                    Label(recommendation, systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(ColorTheme.accent)
                }
            }
            .padding()
            .background(ColorTheme.surface)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Helpers

    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: report.weekStart)
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "MMM d, yyyy"
        let end = endFormatter.string(from: report.weekEnd)
        return "\(start) – \(end)"
    }

    private var trendColor: Color {
        switch report.symptomTrend {
        case .improving: return ColorTheme.success
        case .worsening: return .red
        case .stable: return ColorTheme.secondaryText
        }
    }

    private var aggregatedRecommendations: [String] {
        var seen = Set<String>()
        var result: [String] = []
        let allTriggers = report.newTriggers + report.recurringTriggers
        for trigger in allTriggers {
            for rec in trigger.recommendations {
                if seen.insert(rec).inserted {
                    result.append(rec)
                }
            }
        }
        return result
    }
}

// MARK: - Supporting Views

private struct TriggerEntryRow: View {
    let trigger: TriggerEntry
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trigger.foodName)
                    .font(.subheadline.bold())
                    .foregroundStyle(ColorTheme.primaryText)

                Spacer()

                Text("\(trigger.correlationCount) correlation\(trigger.correlationCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }

            HStack(spacing: 12) {
                // Confidence bar
                HStack(spacing: 4) {
                    Text("Confidence")
                        .font(.caption2)
                        .foregroundStyle(ColorTheme.secondaryText)
                    ProgressView(value: trigger.confidence)
                        .tint(accentColor)
                        .frame(width: 60)
                }

                // Average onset
                Label(String(format: "%.1fh onset", trigger.averageOnsetHours), systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(ColorTheme.secondaryText)
            }

            if !trigger.associatedSymptoms.isEmpty {
                HStack(spacing: 6) {
                    ForEach(trigger.associatedSymptoms, id: \.self) { symptom in
                        Text(symptom)
                            .font(.caption2)
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(accentColor.opacity(0.1)))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct TrendBadge: View {
    let trend: TrendDirection

    var body: some View {
        Image(systemName: trend.icon)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Circle().fill(color))
    }

    private var color: Color {
        switch trend {
        case .improving: return ColorTheme.success
        case .worsening: return .red
        case .stable: return ColorTheme.secondaryText
        }
    }
}

struct TriggerCountPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(count > 0 ? color : ColorTheme.secondaryText)

            Text(label)
                .font(.caption)
                .foregroundStyle(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WeeklyTriggerReportView(report: WeeklyTriggerReport(
            id: UUID(),
            generatedDate: .now,
            weekStart: Calendar.current.date(byAdding: .day, value: -7, to: .now)!,
            weekEnd: .now,
            newTriggers: [
                TriggerEntry(
                    id: UUID(),
                    foodName: "Spicy Chicken",
                    correlationCount: 4,
                    confidence: 0.7,
                    averageOnsetHours: 3.5,
                    associatedSymptoms: ["Moderate Pain", "Loose Stool"],
                    recommendations: ["Consider reducing Spicy Chicken intake for 2-4 weeks", "Reintroduce gradually to confirm sensitivity"]
                ),
                TriggerEntry(
                    id: UUID(),
                    foodName: "Fried Rice",
                    correlationCount: 2,
                    confidence: 0.5,
                    averageOnsetHours: 4.2,
                    associatedSymptoms: ["Mild Urgency"],
                    recommendations: ["Consider reducing Fried Rice intake for 2-4 weeks"]
                )
            ],
            recurringTriggers: [
                TriggerEntry(
                    id: UUID(),
                    foodName: "Dairy Milk",
                    correlationCount: 5,
                    confidence: 0.8,
                    averageOnsetHours: 2.8,
                    associatedSymptoms: ["Moderate Pain", "High Urgency", "Loose Stool"],
                    recommendations: ["Consider reducing Dairy Milk intake for 2-4 weeks", "Strong correlation detected — consult a dietitian", "Reintroduce gradually to confirm sensitivity"]
                )
            ],
            resolvedTriggers: [
                TriggerEntry(
                    id: UUID(),
                    foodName: "Wheat Bread",
                    correlationCount: 3,
                    confidence: 0.6,
                    averageOnsetHours: 5.0,
                    associatedSymptoms: ["Mild Pain"],
                    recommendations: ["Consider reducing Wheat Bread intake for 2-4 weeks"]
                )
            ],
            currentWeekSymptomCount: 8,
            previousWeekSymptomCount: 12,
            currentWeekMealCount: 18,
            previousWeekMealCount: 15
        ))
    }
}
