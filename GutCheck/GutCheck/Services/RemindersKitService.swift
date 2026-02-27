//
//  RemindersKitService.swift
//  GutCheck
//
//  Bridges GutCheck reminder settings to the native Apple Reminders app
//  via Apple's EventKit framework (EKReminder / EKEventStore).
//
//  Design notes:
//  - This is a completely optional, opt-in feature that supplements the existing
//    UNUserNotificationCenter local-notification system; it does not replace it.
//  - All EventKit operations run on the main actor so state is always UI-safe.
//  - A dedicated "GutCheck" Reminders list is created (or reused) so user-created
//    lists stay uncluttered.
//  - On each sync the existing GutCheck reminders are deleted and recreated, which
//    keeps things simple and avoids stale entries when settings change.
//

import EventKit
import Foundation

@MainActor
final class RemindersKitService: ObservableObject {

    // MARK: - Singleton

    static let shared = RemindersKitService()

    // MARK: - Published State

    /// Whether the user has opted in to Apple Reminders sync.
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled) }
    }

    /// Current EventKit authorization status, kept in sync with the system.
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    // MARK: - Private

    private let store = EKEventStore()
    private let gutCheckListName = "GutCheck"

    private enum Keys {
        static let isEnabled = "remindersKit_isEnabled"
    }

    // MARK: - Init

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Keys.isEnabled)
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    }

    // MARK: - Authorization

    /// Computed: does the app currently hold full Reminders access?
    var isAuthorized: Bool {
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess
        } else {
            return authorizationStatus == .authorized
        }
    }

    /// Refreshes the cached authorization status from the system.
    func refreshAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    }

    /// Requests Reminders access from the user.
    /// Returns `true` if access was granted.
    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await store.requestFullAccessToReminders()
            } else {
                granted = try await store.requestAccess(to: .reminder)
            }
            refreshAuthorizationStatus()
            return granted
        } catch {
            #if DEBUG
            print("❌ RemindersKitService: requestAccess failed: \(error)")
            #endif
            refreshAuthorizationStatus()
            return false
        }
    }

    // MARK: - Sync

    /// Creates (or recreates) Apple Reminders from the user's current ReminderSettings.
    /// Silently exits if the user isn't authorized or has opted out.
    func syncReminders(from settings: ReminderSettings) async {
        guard isEnabled, isAuthorized else { return }

        do {
            let calendar = try getOrCreateGutCheckCalendar()
            try removeExistingGutCheckReminders(in: calendar)

            if settings.mealReminderEnabled {
                try addReminder(
                    title: "Log your meal 🍽️",
                    notes: "Open GutCheck to log what you ate.",
                    time: settings.mealReminderTime,
                    recurrence: .daily,
                    calendar: calendar
                )
            }

            if settings.symptomReminderEnabled {
                try addReminder(
                    title: "Log your symptoms 📋",
                    notes: "Open GutCheck to record how you're feeling.",
                    time: settings.symptomReminderTime,
                    recurrence: .daily,
                    calendar: calendar
                )
            }

            if settings.weeklyInsightEnabled {
                try addReminder(
                    title: "Check your weekly GutCheck insights 📊",
                    notes: "Open GutCheck to review your weekly health trends.",
                    time: settings.weeklyInsightTime,
                    recurrence: .weekly,
                    calendar: calendar
                )
            }

            try store.commit()
            #if DEBUG
            print("✅ RemindersKitService: Synced reminders to Apple Reminders app")
            #endif
        } catch {
            #if DEBUG
            print("❌ RemindersKitService: Sync failed: \(error)")
            #endif
        }
    }

    /// Removes all reminders in the GutCheck list from Apple Reminders.
    /// Called when the user disables the feature.
    func removeAllGutCheckReminders() async {
        guard isAuthorized else { return }
        do {
            guard let calendar = store.calendars(for: .reminder).first(where: { $0.title == gutCheckListName }) else {
                return
            }
            try removeExistingGutCheckReminders(in: calendar)
            try store.commit()
            #if DEBUG
            print("✅ RemindersKitService: Removed all GutCheck reminders from Apple Reminders")
            #endif
        } catch {
            #if DEBUG
            print("❌ RemindersKitService: removeAll failed: \(error)")
            #endif
        }
    }

    // MARK: - Private Helpers

    private func getOrCreateGutCheckCalendar() throws -> EKCalendar {
        if let existing = store.calendars(for: .reminder).first(where: { $0.title == gutCheckListName }) {
            return existing
        }
        let cal = EKCalendar(for: .reminder, eventStore: store)
        cal.title = gutCheckListName
        cal.source = store.defaultCalendarForNewReminders()?.source
        try store.saveCalendar(cal, commit: true)
        return cal
    }

    private func removeExistingGutCheckReminders(in calendar: EKCalendar) throws {
        let predicate = store.predicateForReminders(in: [calendar])
        // fetchReminders is callback-based; use a checked continuation to bridge to async/await
        let reminders: [EKReminder] = try fetchRemindersSynchronously(predicate: predicate)
        for reminder in reminders {
            try store.remove(reminder, commit: false)
        }
    }

    /// Bridges EKEventStore's callback-based fetchReminders to async/await.
    private func fetchRemindersSynchronously(predicate: NSPredicate) throws -> [EKReminder] {
        var result: [EKReminder] = []
        let semaphore = DispatchSemaphore(value: 0)
        store.fetchReminders(matching: predicate) { reminders in
            result = reminders ?? []
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    private func addReminder(
        title: String,
        notes: String,
        time: Date,
        recurrence: EKRecurrenceFrequency,
        calendar: EKCalendar
    ) throws {
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = calendar

        // Due-date components (hour + minute only — no specific day so it repeats)
        var components = Calendar.current.dateComponents([.hour, .minute], from: time)
        components.second = 0
        reminder.dueDateComponents = components

        // Recurrence rule
        let rule = EKRecurrenceRule(
            recurrenceWith: recurrence,
            interval: 1,
            end: nil
        )
        reminder.addRecurrenceRule(rule)

        try store.save(reminder, commit: false)
    }
}
