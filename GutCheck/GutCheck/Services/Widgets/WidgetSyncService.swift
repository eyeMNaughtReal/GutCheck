//
//  WidgetSyncService.swift
//  GutCheck
//
//  App-side writer for the shared widget snapshot.
//
//  Widgets cannot reach Firebase, so the app pushes a pre-computed snapshot to
//  the App Group after anything that could change what the widget shows —
//  a meal save, a symptom save, a dashboard recalculation or a reminder change.
//

import Foundation
import WidgetKit
import os.log

@MainActor
final class WidgetSyncService {
    static let shared = WidgetSyncService()

    private let store: WidgetDataStore
    private let healthScoreService: HealthScoreService

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.gutcheck",
        category: "Widgets"
    )

    /// Guards against several save flows kicking off overlapping refreshes.
    private var refreshTask: Task<Void, Never>?

    /// - Parameter healthScoreService: pass `nil` to use the shared instance.
    ///   Resolved inside the initializer rather than as a default argument so
    ///   the main-actor-isolated singleton isn't touched from the caller's
    ///   isolation context.
    init(
        store: WidgetDataStore = .shared,
        healthScoreService: HealthScoreService? = nil
    ) {
        self.store = store
        self.healthScoreService = healthScoreService ?? HealthScoreService.shared
    }

    // MARK: - Refresh

    /// Recompute the snapshot and publish it to the App Group.
    ///
    /// Failures are logged and swallowed: a widget that shows slightly stale
    /// data is never a reason to fail the user's save.
    func refresh() async {
        do {
            let summary = try await healthScoreService.summary()
            let reminder = nextReminder()

            let snapshot = WidgetSnapshot(
                healthScore: summary.score,
                previousScore: summary.previousScore,
                lastMealName: summary.lastMealName,
                lastMealDate: summary.lastMealDate,
                nextReminderTitle: reminder?.title,
                nextReminderDate: reminder?.date
            )

            store.save(snapshot)
            WidgetCenter.shared.reloadAllTimelines()
            logger.info("Published widget snapshot (score \(snapshot.healthScore, privacy: .public))")
        } catch {
            logger.error("Widget snapshot refresh failed: \(error.localizedDescription)")
        }
    }

    /// Fire-and-forget variant for call sites inside save flows.
    /// Coalesces with any refresh already in flight.
    func scheduleRefresh() {
        // Supersede any refresh still in flight — only the newest data matters.
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await self?.refresh()
        }
    }

    /// Publish values a caller has already computed, without re-fetching.
    ///
    /// The dashboard recalculates the score on every load; making it round-trip
    /// to Firestore a second time just to feed the widgets would be wasteful.
    /// - Parameter previousScore: pass `nil` to keep whatever trend baseline was
    ///   already stored for today.
    func publish(
        score: Int,
        previousScore: Int? = nil,
        lastMealName: String?,
        lastMealDate: Date?
    ) {
        let existing = store.load()
        let carriedPrevious = previousScore ?? sameDayPreviousScore(from: existing)
        let reminder = nextReminder()

        let snapshot = WidgetSnapshot(
            healthScore: score,
            previousScore: carriedPrevious,
            lastMealName: lastMealName,
            lastMealDate: lastMealDate,
            nextReminderTitle: reminder?.title,
            nextReminderDate: reminder?.date
        )

        store.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Yesterday's score as recorded earlier today, if the stored snapshot is
    /// still from today. A stale baseline would render a misleading trend arrow.
    private func sameDayPreviousScore(from snapshot: WidgetSnapshot?) -> Int? {
        guard let snapshot,
              Calendar.current.isDateInToday(snapshot.updatedAt) else { return nil }
        return snapshot.previousScore
    }

    /// Wipe shared data and blank the widgets. Called on sign-out so one user's
    /// health score never lingers on the lock screen for the next.
    func clear() {
        store.clear()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Next Reminder

    /// The soonest upcoming reminder, derived from the locally mirrored reminder
    /// settings that `ReminderSettingsService` keeps in UserDefaults.
    ///
    /// Mirrors the scheduling rules in `ReminderSettingsService.scheduleNotifications`:
    /// meal reminders fire 15 minutes after the stored meal time, and reminders
    /// suppressed by an active Focus Filter are ignored.
    func nextReminder() -> (title: String, date: Date)? {
        let defaults = UserDefaults.standard
        let focus = FocusFilterState.current

        var candidates: [(title: String, date: Date)] = []

        func addCandidate(enabledKey: String, timeKey: String, title: String, offsetMinutes: Int, suppressed: Bool) {
            guard !suppressed, defaults.bool(forKey: enabledKey) else { return }
            guard let storedTime = defaults.object(forKey: timeKey) as? Date else { return }
            let shifted = Calendar.current.date(byAdding: .minute, value: offsetMinutes, to: storedTime) ?? storedTime
            guard let next = nextOccurrence(of: shifted) else { return }
            candidates.append((title, next))
        }

        addCandidate(enabledKey: "breakfastReminderEnabled", timeKey: "breakfastReminderTime",
                     title: "Breakfast", offsetMinutes: 15, suppressed: focus.mealRemindersSuppressed)
        addCandidate(enabledKey: "lunchReminderEnabled", timeKey: "lunchReminderTime",
                     title: "Lunch", offsetMinutes: 15, suppressed: focus.mealRemindersSuppressed)
        addCandidate(enabledKey: "dinnerReminderEnabled", timeKey: "dinnerReminderTime",
                     title: "Dinner", offsetMinutes: 15, suppressed: focus.mealRemindersSuppressed)
        addCandidate(enabledKey: "symptomReminderEnabled", timeKey: "symptomReminderTime",
                     title: "Symptom check-in", offsetMinutes: 0, suppressed: focus.symptomRemindersSuppressed)
        addCandidate(enabledKey: "medicationReminderEnabled", timeKey: "medicationReminderTime",
                     title: "Medication", offsetMinutes: 0, suppressed: focus.medicationRemindersSuppressed)

        return candidates.min(by: { $0.date < $1.date })
    }

    /// The next time today or tomorrow that matches the hour/minute of `time`.
    private func nextOccurrence(of time: Date) -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.nextDate(
            after: Date.now,
            matching: components,
            matchingPolicy: .nextTime
        )
    }
}
