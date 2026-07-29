//
//  HealthScoreWidget.swift
//  GutCheckWidgets
//
//  Daily health score widget for the home screen and the lock screen.
//
//  All data comes from the App Group snapshot the app publishes
//  (see WidgetDataStore / WidgetSyncService) — the extension never touches
//  Firebase or HealthKit.
//

import SwiftUI
import WidgetKit

// MARK: - Entry

struct HealthScoreEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    /// True for gallery/preview renderings, which must not imply real data.
    let isPlaceholder: Bool

    init(date: Date = Date.now, snapshot: WidgetSnapshot, isPlaceholder: Bool = false) {
        self.date = date
        self.snapshot = snapshot
        self.isPlaceholder = isPlaceholder
    }
}

// MARK: - Timeline Provider

struct HealthScoreTimelineProvider: TimelineProvider {

    /// Fallback cadence when no reminder is scheduled.
    private static let refreshInterval: TimeInterval = 2 * 60 * 60

    private let store: WidgetDataStore

    init(store: WidgetDataStore = .shared) {
        self.store = store
    }

    func placeholder(in context: Context) -> HealthScoreEntry {
        HealthScoreEntry(snapshot: .placeholder, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (HealthScoreEntry) -> Void) {
        // The widget gallery previews with sample data; a real install shows
        // whatever the app last published.
        if context.isPreview {
            completion(HealthScoreEntry(snapshot: .placeholder, isPlaceholder: true))
            return
        }

        guard let stored = store.load() else {
            completion(HealthScoreEntry(snapshot: .placeholder, isPlaceholder: true))
            return
        }

        completion(HealthScoreEntry(snapshot: stored))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthScoreEntry>) -> Void) {
        guard let stored = store.load() else {
            let entry = HealthScoreEntry(snapshot: .placeholder, isPlaceholder: true)
            completion(Timeline(entries: [entry], policy: .after(Date(timeIntervalSinceNow: Self.refreshInterval))))
            return
        }

        let entry = HealthScoreEntry(snapshot: stored)
        completion(Timeline(entries: [entry], policy: .after(Self.nextRefreshDate(for: stored))))
    }

    /// Refresh at the next reminder if one is due sooner than the two-hour
    /// fallback — that is the moment the widget's "next reminder" line goes
    /// stale, and it usually coincides with the user logging something.
    static func nextRefreshDate(for snapshot: WidgetSnapshot) -> Date {
        let fallback = Date(timeIntervalSinceNow: refreshInterval)

        guard let reminder = snapshot.nextReminderDate, reminder > Date.now else {
            return fallback
        }

        // Give the reminder a minute to fire before re-rendering, and never
        // schedule sooner than 15 minutes out — WidgetKit throttles aggressive
        // refresh requests and would drop them anyway.
        let afterReminder = reminder.addingTimeInterval(60)
        let floorDate = Date(timeIntervalSinceNow: 15 * 60)
        return max(min(afterReminder, fallback), floorDate)
    }
}

// MARK: - Widget

struct HealthScoreWidget: Widget {
    static let kind = "GutCheckHealthScoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HealthScoreTimelineProvider()) { entry in
            HealthScoreWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Health Score")
        .description("Today's gut health score, your last meal and your next reminder.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Entry View

struct HealthScoreWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: HealthScoreEntry

    var body: some View {
        content
            // Placeholder data must never read as the user's real health data.
            .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            HealthScoreSmallView(snapshot: entry.snapshot)
        case .systemMedium:
            HealthScoreMediumView(snapshot: entry.snapshot)
        case .accessoryCircular:
            HealthScoreCircularView(snapshot: entry.snapshot)
        case .accessoryRectangular:
            HealthScoreRectangularView(snapshot: entry.snapshot)
        default:
            HealthScoreSmallView(snapshot: entry.snapshot)
        }
    }
}
