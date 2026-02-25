// SettingsView.swift
// GutCheck
//
// Updated with Phase 2 Accessibility - February 23, 2026

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lastHealthKitSyncTimestamp") private var lastHealthKitSyncTimestamp: Double = 0
    @State private var showAppleHealth = false

    private var appleHealthStatusText: String {
        guard lastHealthKitSyncTimestamp > 0 else { return "Not Connected" }
        let date = Date(timeIntervalSince1970: lastHealthKitSyncTimestamp)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Synced \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Preferences") {
                    NavigationLink(destination: LanguageSelectionView()) {
                        HStack {
                            Text("Language")
                                .typography(Typography.body)
                            Spacer()
                            Text(settingsVM.language.displayName)
                                .typography(Typography.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityLabel("Language: \(settingsVM.language.displayName)")
                    .accessibilityHint("Tap to change app language")
                    
                    NavigationLink(destination: UnitSelectionView()) {
                        HStack {
                            Text("Units")
                                .typography(Typography.body)
                            Spacer()
                            Text(settingsVM.unitOfMeasure.displayName)
                                .typography(Typography.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityLabel("Units: \(settingsVM.unitOfMeasure.displayName)")
                    .accessibilityHint("Tap to change measurement units")

                    NavigationLink(destination: AppearanceSelectionView()) {
                        HStack {
                            Text("Appearance")
                                .typography(Typography.body)
                            Spacer()
                            Text(settingsVM.colorScheme.displayName)
                                .typography(Typography.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityLabel("Appearance: \(settingsVM.colorScheme.displayName)")
                    .accessibilityHint("Tap to change app appearance")
                }
                
                Section("Notifications") {
                    NavigationLink(destination: UserRemindersView()) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.orange)
                                .accessibleDecorative()
                            Text("Reminders")
                                .typography(Typography.body)
                        }
                    }
                    .accessibilityLabel("Reminders")
                    .accessibilityHint("Tap to manage notification reminders")
                }

                Section("Healthcare") {
                    Button(action: { showAppleHealth = true }) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .accessibleDecorative()
                            Text("Apple Health")
                                .typography(Typography.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(appleHealthStatusText)
                                .typography(Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityLabel("Apple Health: \(appleHealthStatusText)")
                    .accessibilityHint("Tap to manage Apple Health sync")

                    NavigationLink(destination: HealthcareExportView()) {
                        HStack {
                            Image(systemName: "heart.text.square")
                                .foregroundColor(.blue)
                                .accessibleDecorative()
                            Text("Export Health Data")
                                .typography(Typography.body)
                            Spacer()
                            Text("For Healthcare Professionals")
                                .typography(Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityLabel("Export Health Data for Healthcare Professionals")
                    .accessibilityHint("Tap to export your health data")
                }
                
                Section("Privacy & Security") {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.green)
                                .accessibleDecorative()
                            Text("Privacy Policy")
                                .typography(Typography.body)
                        }
                    }
                    .accessibilityLabel("Privacy Policy")
                    .accessibilityHint("Tap to read the privacy policy")

                    NavigationLink(destination: DataDeletionRequestView()) {
                        HStack {
                            Image(systemName: "trash.circle")
                                .foregroundColor(.orange)
                                .accessibleDecorative()
                            Text("Request Data Deletion")
                                .typography(Typography.body)
                            Spacer()
                            Text("GDPR Right")
                                .typography(Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityLabel("Request Data Deletion")
                    .accessibilityHint("Tap to submit a GDPR data deletion request")

                    HStack {
                        Image(systemName: "checkmark.shield")
                            .foregroundColor(.blue)
                            .accessibleDecorative()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Privacy Policy Accepted")
                                .font(.subheadline)
                            Text("Version 1.0 - August 18, 2025")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .accessibleDecorative()
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Privacy Policy accepted, Version 1.0, August 18, 2025")
                }
                
                Section("Data & Storage") {
                    NavigationLink(destination: LocalStorageSettingsView()) {
                        HStack {
                            Image(systemName: "internaldrive")
                                .foregroundColor(.blue)
                            Text("Local Storage")
                            Spacer()
                            Text("Core Data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Account Management") {
                    NavigationLink(destination: DeleteAccountView()) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Delete Account")
                            Spacer()
                            Text("Permanent")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
                    .environmentObject(settingsVM)
                    .environmentObject(authService)
            }
        }
    }
}

struct LanguageSelectionView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    var body: some View {
        List {
            ForEach(AppLanguage.allCases, id: \ .self) { lang in
                HStack {
                    Text(lang.displayName)
                        .typography(Typography.body)
                    Spacer()
                    if lang == settingsVM.language {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                            .accessibleDecorative()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticManager.shared.selection()
                    settingsVM.language = lang
                }
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
    @EnvironmentObject var settingsVM: SettingsViewModel
    var body: some View {
        List {
            ForEach(UnitSystem.allCases, id: \ .self) { unit in
                HStack {
                    Text(unit.displayName)
                        .typography(Typography.body)
                    Spacer()
                    if unit == settingsVM.unitOfMeasure {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                            .accessibleDecorative()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticManager.shared.selection()
                    settingsVM.unitOfMeasure = unit
                }
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
    @EnvironmentObject var settingsVM: SettingsViewModel
    var body: some View {
        List {
            ForEach(AppColorScheme.allCases, id: \ .self) { scheme in
                HStack {
                    Text(scheme.displayName)
                        .typography(Typography.body)
                    Spacer()
                    if scheme == settingsVM.colorScheme {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                            .accessibleDecorative()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticManager.shared.selection()
                    settingsVM.colorScheme = scheme
                }
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
