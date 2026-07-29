//
//  WidgetSupport.swift
//  GutCheckWidgets
//
//  Shared presentation helpers for the GutCheck widgets.
//
//  The widget extension has no access to the app's asset catalog, so the score
//  colours are defined here with the same values the app uses for its health
//  indicators (see ColorTheme / the Bristol scale palette).
//

import SwiftUI
import WidgetKit

// MARK: - Palette

enum WidgetPalette {

    /// Colour for a 1–10 health score. Matches the dashboard's banding:
    /// 8+ is good, 6–7 is fair, below that needs attention.
    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 8...10:
            return Color(red: 0.2, green: 0.6, blue: 0.4)
        case 6...7:
            return Color(red: 0.8, green: 0.6, blue: 0.2)
        default:
            return Color(red: 0.7, green: 0.3, blue: 0.3)
        }
    }

    /// Colour for the trend arrow. Up is good, down needs attention.
    static func trendColor(for trend: WidgetScoreTrend) -> Color {
        switch trend {
        case .up:
            return Color(red: 0.2, green: 0.6, blue: 0.4)
        case .down:
            return Color(red: 0.7, green: 0.3, blue: 0.3)
        case .steady:
            return .secondary
        }
    }
}

// MARK: - Container Background

/// `containerBackground(for: .widget)` is required from iOS 17 and unavailable
/// before it, so the background is applied through a single guarded modifier.
struct WidgetContainerBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(.fill.tertiary, for: .widget)
        } else {
            content
        }
    }
}

extension View {
    func widgetContainerBackground() -> some View {
        modifier(WidgetContainerBackground())
    }
}

// MARK: - Score Ring

/// Circular progress ring used by the small and medium home screen widgets.
struct ScoreRingView: View {
    let score: Int
    var lineWidth: CGFloat = 8
    var showsLabel: Bool = true

    private var fraction: Double {
        Double(max(1, min(10, score))) / 10.0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    WidgetPalette.scoreColor(for: score),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            if showsLabel {
                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetPalette.scoreColor(for: score))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Text("of 10")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                // Hidden when the device is locked and the user has opted to
                // hide sensitive widget content.
                .privacySensitive()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gut health score \(score) out of 10")
    }
}

// MARK: - Trend Label

/// Arrow plus wording. The arrow alone is meaningless to VoiceOver, so the
/// spoken label always carries the full sentence.
struct TrendLabel: View {
    let trend: WidgetScoreTrend
    var showsText: Bool = true

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: trend.symbolName)
                .font(.caption.weight(.bold))

            if showsText {
                Text(trend.shortLabel)
                    .font(.caption)
            }
        }
        .foregroundStyle(WidgetPalette.trendColor(for: trend))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(trend.accessibilityLabel)
    }
}

// MARK: - Formatting

enum WidgetFormat {

    /// "12:30 PM" in the user's locale.
    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    /// Meal names can be long ("Leftover roast chicken with…"); widgets have
    /// very little room, so they are clipped rather than wrapped indefinitely.
    static func mealName(_ name: String?) -> String {
        guard let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "No meals yet"
        }
        return name
    }
}
