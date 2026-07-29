//
//  WidgetDataStore.swift
//  GutCheck
//
//  Shared App Group storage that carries the small amount of glanceable state
//  the home screen / lock screen widgets render.
//
//  IMPORTANT: this file is compiled into BOTH the GutCheck app target and the
//  GutCheckWidgets extension target. It must therefore only depend on
//  Foundation — no Firebase, no app models, no SwiftUI.
//

import Foundation

// MARK: - Trend

/// Direction of today's health score compared with the previous day.
enum WidgetScoreTrend: String, Codable, Sendable {
    case up
    case down
    case steady

    /// SF Symbol used for the trend arrow.
    var symbolName: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .steady: return "arrow.right"
        }
    }

    /// Short label used on the rectangular lock screen widget.
    var shortLabel: String {
        switch self {
        case .up: return "Improving"
        case .down: return "Declining"
        case .steady: return "Steady"
        }
    }

    /// Spoken description for VoiceOver — the arrow alone conveys nothing.
    var accessibilityLabel: String {
        switch self {
        case .up: return "Trending up from yesterday"
        case .down: return "Trending down from yesterday"
        case .steady: return "Unchanged from yesterday"
        }
    }
}

// MARK: - Snapshot

/// The complete payload the app hands to its widgets.
///
/// Deliberately small and denormalized: widgets have a tight memory budget and
/// no access to Firebase, so everything they need is pre-computed app-side.
struct WidgetSnapshot: Codable, Equatable, Sendable {
    /// Today's health score, 1–10.
    var healthScore: Int
    /// Yesterday's score, when known — drives the trend arrow.
    var previousScore: Int?
    /// Name of the most recently logged meal, if any.
    var lastMealName: String?
    /// When that meal was logged.
    var lastMealDate: Date?
    /// Human-readable title of the next scheduled reminder, e.g. "Dinner".
    var nextReminderTitle: String?
    /// When that reminder fires.
    var nextReminderDate: Date?
    /// When the app last wrote this snapshot.
    var updatedAt: Date

    init(
        healthScore: Int,
        previousScore: Int? = nil,
        lastMealName: String? = nil,
        lastMealDate: Date? = nil,
        nextReminderTitle: String? = nil,
        nextReminderDate: Date? = nil,
        updatedAt: Date = Date.now
    ) {
        self.healthScore = max(1, min(10, healthScore))
        self.previousScore = previousScore.map { max(1, min(10, $0)) }
        self.lastMealName = lastMealName
        self.lastMealDate = lastMealDate
        self.nextReminderTitle = nextReminderTitle
        self.nextReminderDate = nextReminderDate
        self.updatedAt = updatedAt
    }

    /// Trend relative to yesterday. `steady` when there is nothing to compare.
    var trend: WidgetScoreTrend {
        guard let previousScore else { return .steady }
        if healthScore > previousScore { return .up }
        if healthScore < previousScore { return .down }
        return .steady
    }

    /// Score as a fraction of the 1–10 range, for gauges and rings.
    var scoreFraction: Double {
        Double(healthScore) / 10.0
    }

    /// Short qualitative descriptor matching the dashboard's score card wording.
    var scoreDescriptor: String {
        switch healthScore {
        case 8...10: return "Great"
        case 6...7: return "Good"
        case 4...5: return "Fair"
        default: return "Rough"
        }
    }

    /// Sample data for widget galleries and SwiftUI previews.
    /// Never persisted — the gallery must not imply real user data.
    static let placeholder = WidgetSnapshot(
        healthScore: 8,
        previousScore: 7,
        lastMealName: "Grilled chicken salad",
        lastMealDate: Date(timeIntervalSinceNow: -90 * 60),
        nextReminderTitle: "Dinner",
        nextReminderDate: Date(timeIntervalSinceNow: 3 * 60 * 60),
        updatedAt: Date.now
    )
}

// MARK: - Store

/// Reads and writes the widget snapshot in the shared App Group container.
///
/// Holds no cached state so it is trivially `Sendable` and safe to use from the
/// widget extension, background tasks and the main actor alike.
struct WidgetDataStore: Sendable {

    /// App Group shared by the app and the widget extension.
    /// Must be enabled on both targets' Signing & Capabilities.
    static let appGroupIdentifier = "group.com.gutcheck.shared"

    static let shared = WidgetDataStore()

    private enum Key {
        static let snapshot = "widget.snapshot"
    }

    private let suiteName: String

    init(suiteName: String = WidgetDataStore.appGroupIdentifier) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    /// Persist the latest snapshot. Silently no-ops when the App Group is not
    /// configured — a missing entitlement must not crash a save flow.
    func save(_ snapshot: WidgetSnapshot) {
        guard let defaults else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Key.snapshot)
    }

    /// The most recently written snapshot, or `nil` when the app has never
    /// published one (fresh install, signed out, or App Group unavailable).
    func load() -> WidgetSnapshot? {
        guard let defaults,
              let data = defaults.data(forKey: Key.snapshot) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// Remove all shared data. Called on sign-out so a signed-out device never
    /// leaves another user's health score on the lock screen.
    func clear() {
        defaults?.removeObject(forKey: Key.snapshot)
    }
}
