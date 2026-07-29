//
//  GutCheckMetricWidget.swift
//  GutCheckWidgets
//
//  A user-configurable widget: the same App Group snapshot, but the user picks
//  which single metric it shows.
//
//  `AppIntentConfiguration` is iOS 17+, so everything here is gated. Devices on
//  iOS 16 still get the fixed Daily Health Score widget.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Configuration

@available(iOS 17.0, *)
enum WidgetMetric: String, AppEnum {
    case healthScore
    case lastMeal
    case nextReminder

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Metric")
    }

    static var caseDisplayRepresentations: [WidgetMetric: DisplayRepresentation] {
        [
            .healthScore: DisplayRepresentation(title: "Health Score"),
            .lastMeal: DisplayRepresentation(title: "Last Meal"),
            .nextReminder: DisplayRepresentation(title: "Next Reminder")
        ]
    }

    var title: String {
        switch self {
        case .healthScore: return "Gut Health"
        case .lastMeal: return "Last Meal"
        case .nextReminder: return "Next Reminder"
        }
    }

    var symbolName: String {
        switch self {
        case .healthScore: return "leaf.fill"
        case .lastMeal: return "fork.knife"
        case .nextReminder: return "bell.fill"
        }
    }
}

@available(iOS 17.0, *)
struct SelectMetricIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose Metric"

    static var description = IntentDescription("Pick which GutCheck metric this widget shows.")

    @Parameter(title: "Metric", default: .healthScore)
    var metric: WidgetMetric

    init() {}

    init(metric: WidgetMetric) {
        self.metric = metric
    }
}

// MARK: - Entry & Provider

@available(iOS 17.0, *)
struct GutCheckMetricEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let metric: WidgetMetric
    let isPlaceholder: Bool

    init(
        date: Date = Date.now,
        snapshot: WidgetSnapshot,
        metric: WidgetMetric,
        isPlaceholder: Bool = false
    ) {
        self.date = date
        self.snapshot = snapshot
        self.metric = metric
        self.isPlaceholder = isPlaceholder
    }
}

@available(iOS 17.0, *)
struct GutCheckMetricProvider: AppIntentTimelineProvider {

    private let store: WidgetDataStore

    init(store: WidgetDataStore = .shared) {
        self.store = store
    }

    func placeholder(in context: Context) -> GutCheckMetricEntry {
        GutCheckMetricEntry(snapshot: .placeholder, metric: .healthScore, isPlaceholder: true)
    }

    func snapshot(for configuration: SelectMetricIntent, in context: Context) async -> GutCheckMetricEntry {
        guard !context.isPreview, let stored = store.load() else {
            return GutCheckMetricEntry(
                snapshot: .placeholder,
                metric: configuration.metric,
                isPlaceholder: true
            )
        }
        return GutCheckMetricEntry(snapshot: stored, metric: configuration.metric)
    }

    func timeline(for configuration: SelectMetricIntent, in context: Context) async -> Timeline<GutCheckMetricEntry> {
        guard let stored = store.load() else {
            let entry = GutCheckMetricEntry(
                snapshot: .placeholder,
                metric: configuration.metric,
                isPlaceholder: true
            )
            return Timeline(entries: [entry], policy: .after(Date(timeIntervalSinceNow: 2 * 60 * 60)))
        }

        let entry = GutCheckMetricEntry(snapshot: stored, metric: configuration.metric)
        return Timeline(
            entries: [entry],
            policy: .after(HealthScoreTimelineProvider.nextRefreshDate(for: stored))
        )
    }
}

// MARK: - Widget

@available(iOS 17.0, *)
struct GutCheckMetricWidget: Widget {
    static let kind = "GutCheckMetricWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: SelectMetricIntent.self,
            provider: GutCheckMetricProvider()
        ) { entry in
            GutCheckMetricEntryView(entry: entry)
        }
        .configurationDisplayName("GutCheck Metric")
        .description("Show your health score, your last meal or your next reminder.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

// MARK: - Views

@available(iOS 17.0, *)
struct GutCheckMetricEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: GutCheckMetricEntry

    var body: some View {
        content
            .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryRectangular:
            rectangular
        default:
            small
        }
    }

    // MARK: Small

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(entry.metric.title, systemImage: entry.metric.symbolName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)

            Spacer(minLength: 0)

            switch entry.metric {
            case .healthScore:
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.snapshot.healthScore)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetPalette.scoreColor(for: entry.snapshot.healthScore))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Text("/ 10")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .privacySensitive()

                TrendLabel(trend: entry.snapshot.trend)

            case .lastMeal:
                Text(WidgetFormat.mealName(entry.snapshot.lastMealName))
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .privacySensitive()

                if let date = entry.snapshot.lastMealDate {
                    Text(WidgetFormat.time(date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .nextReminder:
                Text(entry.snapshot.nextReminderTitle ?? "None scheduled")
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                if let date = entry.snapshot.nextReminderDate {
                    Text(WidgetFormat.time(date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
        .widgetContainerBackground()
        .accessibilityElement(children: .combine)
    }

    // MARK: Rectangular

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(entry.metric.title, systemImage: entry.metric.symbolName)
                .font(.caption2.weight(.semibold))
                .widgetAccentable()
                .lineLimit(1)

            switch entry.metric {
            case .healthScore:
                Text("\(entry.snapshot.healthScore) / 10 · \(entry.snapshot.trend.shortLabel)")
                    .font(.caption)
                    .lineLimit(1)
                    .privacySensitive()

            case .lastMeal:
                Text(WidgetFormat.mealName(entry.snapshot.lastMealName))
                    .font(.caption)
                    .lineLimit(2)
                    .privacySensitive()

            case .nextReminder:
                if let date = entry.snapshot.nextReminderDate {
                    Text("\(entry.snapshot.nextReminderTitle ?? "Reminder") at \(WidgetFormat.time(date))")
                        .font(.caption)
                        .lineLimit(2)
                } else {
                    Text("None scheduled")
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        }
        .widgetContainerBackground()
        .accessibilityElement(children: .combine)
    }
}
