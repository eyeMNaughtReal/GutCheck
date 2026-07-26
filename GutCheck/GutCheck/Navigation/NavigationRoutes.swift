//
//  NavigationRoutes.swift
//  GutCheck
//
//  Sub-screen navigation route enums for value-based NavigationLink.
//

import SwiftUI

// Settings sub-screen navigation
enum SettingsRoute: Hashable {
    case language
    case units
    case appearance
    case reminders
    case medications
    case healthcareExport
    case privacyPolicy
    case dataDeletion
    case localStorage
    case deleteAccount
    case debugMenu

    @ViewBuilder
    static func destinationView(for route: SettingsRoute) -> some View {
        switch route {
        case .language:
            LanguageSelectionView()
        case .units:
            UnitSelectionView()
        case .appearance:
            AppearanceSelectionView()
        case .reminders:
            UserRemindersView()
        case .medications:
            MedicationListView()
        case .healthcareExport:
            HealthcareExportView()
        case .privacyPolicy:
            PrivacyPolicyView()
        case .dataDeletion:
            DataDeletionRequestView()
        case .localStorage:
            LocalStorageSettingsView()
        case .deleteAccount:
            DeleteAccountView()
        case .debugMenu:
            DebugView()
        }
    }
}

// Insights navigation
enum InsightsRoute: Hashable {
    case insightDetail(HealthInsight)
    case categoryInsights(InsightCategory)
    case weeklyTriggerReport(WeeklyTriggerReport)
    case triggerPatternDetail(TriggerPattern)
    case symptomExplorer
    case symptomCharts
    case mealSuggestions([MealSuggestion])
}

// Privacy policy navigation
enum PrivacyPolicyRoute: Hashable {
    case sectionDetail(PolicySection)
}

// Profile menu navigation
enum ProfileMenuRoute: Hashable {
    case settings
    case reminders
}

// Calendar navigation
enum CalendarRoute: Hashable {
    case dayDetail(Date)
    case fullCalendar(Date)
}
