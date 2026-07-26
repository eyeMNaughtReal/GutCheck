//
//  GutCheckFocusFilter.swift
//  GutCheck
//
//  Focus Filter intent that lets users configure which GutCheck notification
//  categories to suppress when an iOS Focus mode is active.
//

import AppIntents

struct GutCheckFocusFilter: SetFocusFilterIntent {

    // MARK: - Metadata

    static var title: LocalizedStringResource = "GutCheck Notifications"
    static var description: IntentDescription? = IntentDescription(
        "Choose which GutCheck reminders to silence during this Focus."
    )

    // MARK: - Parameters

    @Parameter(title: "Suppress Meal Reminders", default: false)
    var suppressMealReminders: Bool

    @Parameter(title: "Suppress Symptom Reminders", default: false)
    var suppressSymptomReminders: Bool

    @Parameter(title: "Suppress Medication Reminders", default: false)
    var suppressMedicationReminders: Bool

    @Parameter(title: "Suppress Weekly Insights", default: false)
    var suppressWeeklyInsights: Bool

    // MARK: - Display Representation

    var displayRepresentation: DisplayRepresentation {
        var suppressed: [String] = []
        if suppressMealReminders { suppressed.append("Meals") }
        if suppressSymptomReminders { suppressed.append("Symptoms") }
        if suppressMedicationReminders { suppressed.append("Medication") }
        if suppressWeeklyInsights { suppressed.append("Weekly Insights") }

        if suppressed.isEmpty {
            return DisplayRepresentation(stringLiteral: "No reminders suppressed")
        }
        return DisplayRepresentation(stringLiteral: "Suppressing: \(suppressed.joined(separator: ", "))")
    }

    // MARK: - Perform

    @MainActor
    func perform() async throws -> some IntentResult {
        FocusFilterState.update(
            mealRemindersSuppressed: suppressMealReminders,
            symptomRemindersSuppressed: suppressSymptomReminders,
            medicationRemindersSuppressed: suppressMedicationReminders,
            weeklyInsightsSuppressed: suppressWeeklyInsights
        )

        await ReminderSettingsService.shared.rescheduleNotificationsForFocusChange()

        return .result()
    }
}
