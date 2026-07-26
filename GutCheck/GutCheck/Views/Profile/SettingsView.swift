// SettingsView.swift
// GutCheck
//
// Updated with Phase 2 Accessibility - February 23, 2026

import SwiftUI

struct SettingsView: View {
    @Environment(SettingsViewModel.self) var settingsVM
    @Environment(AuthService.self) var authService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lastHealthKitSyncTimestamp") private var lastHealthKitSyncTimestamp: Double = 0
    @State private var showAppleHealth = false

    private var appleHealthStatusText: String {
        guard lastHealthKitSyncTimestamp > 0 else { return "Not Connected" }
        let date = Date(timeIntervalSince1970: lastHealthKitSyncTimestamp)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Synced \(formatter.localizedString(for: date, relativeTo: Date.now))"
    }

    var body: some View {
        List {
                Section("Preferences") {
                    NavigationLink(value: SettingsRoute.language) {
                        HStack {
                            Text("Language")
                                .typography(Typography.body)
                            Spacer()
                            Text(settingsVM.language.displayName)
                                .typography(Typography.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Language: \(settingsVM.language.displayName)")
                    .accessibilityHint("Tap to change app language")
                    
                    NavigationLink(value: SettingsRoute.units) {
                        HStack {
                            Text("Units")
                                .typography(Typography.body)
                            Spacer()
                            Text(settingsVM.unitOfMeasure.displayName)
                                .typography(Typography.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Units: \(settingsVM.unitOfMeasure.displayName)")
                    .accessibilityHint("Tap to change measurement units")

                    NavigationLink(value: SettingsRoute.appearance) {
                        HStack {
                            Text("Appearance")
                                .typography(Typography.body)
                            Spacer()
                            Text(settingsVM.colorScheme.displayName)
                                .typography(Typography.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Appearance: \(settingsVM.colorScheme.displayName)")
                    .accessibilityHint("Tap to change app appearance")
                }
                
                Section("Notifications") {
                    NavigationLink(value: SettingsRoute.reminders) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundStyle(.orange)
                                .accessibleDecorative()
                            Text("Reminders")
                                .typography(Typography.body)
                        }
                    }
                    .accessibilityLabel("Reminders")
                    .accessibilityHint("Tap to manage notification reminders")
                }

                Section("Medications") {
                    NavigationLink(value: SettingsRoute.medications) {
                        HStack {
                            Image(systemName: "pills.fill")
                                .foregroundStyle(.purple)
                                .accessibleDecorative()
                            Text("My Medications")
                                .typography(Typography.body)
                            Spacer()
                            Text("Manage your list")
                                .typography(Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("My Medications")
                    .accessibilityHint("Tap to add or edit your medications")
                }

                Section("Healthcare") {
                    Button(action: { showAppleHealth = true }) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                                .accessibleDecorative()
                            Text("Apple Health")
                                .typography(Typography.body)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(appleHealthStatusText)
                                .typography(Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Apple Health: \(appleHealthStatusText)")
                    .accessibilityHint("Tap to manage Apple Health sync")

                    NavigationLink(value: SettingsRoute.healthcareExport) {
                        HStack {
                            Image(systemName: "heart.text.square")
                                .foregroundStyle(.blue)
                                .accessibleDecorative()
                            Text("Export Health Data")
                                .typography(Typography.body)
                            Spacer()
                            Text("For Healthcare Professionals")
                                .typography(Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Export Health Data for Healthcare Professionals")
                    .accessibilityHint("Tap to export your health data")
                }
                
                Section("Privacy & Security") {
                    NavigationLink(value: SettingsRoute.privacyPolicy) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundStyle(.green)
                                .accessibleDecorative()
                            Text("Privacy Policy")
                                .typography(Typography.body)
                        }
                    }
                    .accessibilityLabel("Privacy Policy")
                    .accessibilityHint("Tap to read the privacy policy")

                    NavigationLink(value: SettingsRoute.dataDeletion) {
                        HStack {
                            Image(systemName: "trash.circle")
                                .foregroundStyle(.orange)
                                .accessibleDecorative()
                            Text("Request Data Deletion")
                                .typography(Typography.body)
                            Spacer()
                            Text("GDPR Right")
                                .typography(Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Request Data Deletion")
                    .accessibilityHint("Tap to submit a GDPR data deletion request")

                    HStack {
                        Image(systemName: "checkmark.shield")
                            .foregroundStyle(.blue)
                            .accessibleDecorative()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Privacy Policy Accepted")
                                .font(.subheadline)
                            Text("Version 1.0 - August 18, 2025")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .accessibleDecorative()
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Privacy Policy accepted, Version 1.0, August 18, 2025")
                }
                
                Section("Data & Storage") {
                    NavigationLink(value: SettingsRoute.localStorage) {
                        HStack {
                            Image(systemName: "internaldrive")
                                .foregroundStyle(.blue)
                            Text("Local Storage")
                            Spacer()
                            Text("Core Data")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                #if DEBUG
                Section {
                    Toggle(isOn: Bindable(settingsVM).testMealModeEnabled) {
                        HStack {
                            Image(systemName: "fork.knife.circle")
                                .foregroundStyle(.mint)
                                .accessibleDecorative()
                            Text("Test Meal Mode")
                                .typography(Typography.body)
                        }
                    }
                    .accessibilityLabel("Test Meal Mode")
                    .accessibilityHint("Toggle to enable sample meal data for testing")

                    Toggle(isOn: Bindable(settingsVM).experimentalAIEnabled) {
                        HStack {
                            Image(systemName: "brain")
                                .foregroundStyle(.purple)
                                .accessibleDecorative()
                            Text("Experimental AI Predictions")
                                .typography(Typography.body)
                        }
                    }
                    .accessibilityLabel("Experimental AI Predictions")
                    .accessibilityHint("Toggle to enable experimental AI analysis features")

                    Toggle(isOn: Bindable(settingsVM).showSyncDebugInfo) {
                        HStack {
                            Image(systemName: "ant.circle")
                                .foregroundStyle(.orange)
                                .accessibleDecorative()
                            Text("Show Sync/Debug Info")
                                .typography(Typography.body)
                        }
                    }
                    .accessibilityLabel("Show Sync and Debug Info")
                    .accessibilityHint("Toggle to display sync status and debug logs")

                    NavigationLink(value: SettingsRoute.debugMenu) {
                        HStack {
                            Image(systemName: "ladybug")
                                .foregroundStyle(.red)
                                .accessibleDecorative()
                            Text("Debug Menu")
                                .typography(Typography.body)
                        }
                    }
                    .accessibilityLabel("Debug Menu")
                    .accessibilityHint("Tap to open the debug menu")
                } header: {
                    Label("Developer", systemImage: "hammer.fill")
                }
                #endif

                Section("Account Management") {
                    // Linked account display
                    if let user = authService.currentUser {
                        HStack(spacing: 12) {
                            Image(systemName: user.signInMethod.icon)
                                .foregroundStyle(ColorTheme.primary)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Signed in with \(user.signInMethod.displayName)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ColorTheme.success)
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Signed in with \(user.signInMethod.displayName), \(user.email)")
                    }
                    
                    // Sign out
                    Button {
                        HapticManager.shared.medium()
                        try? authService.signOut()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.orange)
                            Text("Sign Out")
                                .foregroundStyle(ColorTheme.primaryText)
                        }
                    }
                    .accessibilityLabel("Sign Out")
                    .accessibilityHint("Tap to sign out of your account")
                    
                    // Delete account
                    NavigationLink(value: SettingsRoute.deleteAccount) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                            Text("Delete Account")
                            Spacer()
                            Text("Permanent")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        .navigationTitle("Settings")
        .navigationDestination(for: SettingsRoute.self) { route in
            SettingsRoute.destinationView(for: route)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    HapticManager.shared.light()
                    dismiss()
                }
                .accessibleButton(
                    label: "Close",
                    hint: "Close settings"
                )
            }
        }
        .sheet(isPresented: $showAppleHealth) {
            HealthDataIntegrationView()
                .environment(settingsVM)
                .environment(authService)
        }
    }
}

struct LanguageSelectionView: View {
    @Environment(SettingsViewModel.self) var settingsVM
    var body: some View {
        List {
            ForEach(AppLanguage.allCases, id: \ .self) { lang in
                Button {
                    HapticManager.shared.selection()
                    settingsVM.language = lang
                } label: {
                    HStack {
                        Text(lang.displayName)
                            .typography(Typography.body)
                        Spacer()
                        if lang == settingsVM.language {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                                .accessibleDecorative()
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibleSelectable(
                    label: lang.displayName,
                    isSelected: lang == settingsVM.language
                )
                .accessibilityHint("Tap to select \(lang.displayName)")
            }
        }
        .navigationTitle("Language")
    }
}

struct UnitSelectionView: View {
    @Environment(SettingsViewModel.self) var settingsVM
    var body: some View {
        List {
            ForEach(UnitSystem.allCases, id: \ .self) { unit in
                Button {
                    HapticManager.shared.selection()
                    settingsVM.unitOfMeasure = unit
                } label: {
                    HStack {
                        Text(unit.displayName)
                            .typography(Typography.body)
                        Spacer()
                        if unit == settingsVM.unitOfMeasure {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                                .accessibleDecorative()
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibleSelectable(
                    label: unit.displayName,
                    isSelected: unit == settingsVM.unitOfMeasure
                )
                .accessibilityHint("Tap to select \(unit.displayName)")
            }
        }
        .navigationTitle("Units")
    }
}

struct AppearanceSelectionView: View {
    @Environment(SettingsViewModel.self) var settingsVM
    var body: some View {
        List {
            ForEach(AppColorScheme.allCases, id: \ .self) { scheme in
                Button {
                    HapticManager.shared.selection()
                    settingsVM.colorScheme = scheme
                } label: {
                    HStack {
                        Text(scheme.displayName)
                            .typography(Typography.body)
                        Spacer()
                        if scheme == settingsVM.colorScheme {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                                .accessibleDecorative()
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibleSelectable(
                    label: scheme.displayName,
                    isSelected: scheme == settingsVM.colorScheme
                )
                .accessibilityHint("Tap to select \(scheme.displayName)")
            }
        }
        .navigationTitle("Appearance")
    }
}
