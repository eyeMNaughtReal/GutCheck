//
//  HealthScoreWidgetViews.swift
//  GutCheckWidgets
//
//  Per-family layouts for the daily health score widget.
//
//  Every view here renders from a `WidgetSnapshot` only — no fetching, no
//  side effects — so each family can be previewed in isolation.
//

import SwiftUI
import WidgetKit

// MARK: - Small

/// `.systemSmall` — score number, trend arrow and colour ring.
struct HealthScoreSmallView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "leaf.fill")
                    .font(.caption2)
                    .foregroundStyle(WidgetPalette.scoreColor(for: snapshot.healthScore))

                Text("Gut Health")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                TrendLabel(trend: snapshot.trend, showsText: false)
            }

            ScoreRingView(score: snapshot.healthScore, lineWidth: 8)
                .frame(maxWidth: .infinity)

            Text(snapshot.scoreDescriptor)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(4)
        .widgetContainerBackground()
    }
}

// MARK: - Medium

/// `.systemMedium` — score plus the last meal logged and the next reminder.
struct HealthScoreMediumView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                ScoreRingView(score: snapshot.healthScore, lineWidth: 9)
                    .frame(width: 84, height: 84)

                TrendLabel(trend: snapshot.trend)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Gut Health Today")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                detailRow(
                    icon: "fork.knife",
                    title: "Last meal",
                    value: WidgetFormat.mealName(snapshot.lastMealName),
                    detail: snapshot.lastMealDate.map { WidgetFormat.time($0) }
                )

                detailRow(
                    icon: "bell.fill",
                    title: "Next reminder",
                    value: snapshot.nextReminderTitle ?? "None scheduled",
                    detail: snapshot.nextReminderDate.map { WidgetFormat.time($0) }
                )

                Spacer(minLength: 0)
            }

            Spacer(minLength: 0)
        }
        .padding(4)
        .widgetContainerBackground()
    }

    private func detailRow(icon: String, title: String, value: String, detail: String?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Text(value)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if let detail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        // Meal names are personal health context — hide them on a locked device
        // when the user has asked for sensitive widget data to be obscured.
        .privacySensitive()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)\(detail.map { ", \($0)" } ?? "")")
    }
}

// MARK: - Lock Screen: Circular

/// `.accessoryCircular` — a score gauge for the lock screen (iOS 16+).
struct HealthScoreCircularView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        Gauge(value: Double(snapshot.healthScore), in: 0...10) {
            Image(systemName: "leaf.fill")
        } currentValueLabel: {
            Text("\(snapshot.healthScore)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
        .widgetContainerBackground()
        .accessibilityLabel("Gut health score \(snapshot.healthScore) out of 10")
    }
}

// MARK: - Lock Screen: Rectangular

/// `.accessoryRectangular` — score plus a short trend label (iOS 16+).
struct HealthScoreRectangularView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "leaf.fill")
                    .font(.caption2)
                Text("Gut Health")
                    .font(.caption2.weight(.semibold))
            }
            .widgetAccentable()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(snapshot.healthScore)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                Text("/ 10")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Image(systemName: snapshot.trend.symbolName)
                    .font(.caption2.weight(.bold))
            }

            Text(snapshot.trend.shortLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .widgetContainerBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Gut health score \(snapshot.healthScore) out of 10. \(snapshot.trend.accessibilityLabel)"
        )
    }
}
