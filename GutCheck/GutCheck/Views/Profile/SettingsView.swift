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
        return "Synced \(formatter.localizedString(for: date, relativeTo: Date.now))"
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
                                .foregroundStyle(.secondary)
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
                                .foregroundStyle(.secondary)
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
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Appearance: \(settingsVM.colorScheme.displayName)")
                    .accessibilityHint("Tap to change app appearance")
                }
                
                Section("Notifications") {
                    NavigationLink(destination: UserRemindersView()) {
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
                    NavigationLink(destination: MedicationListView()) {
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

                    NavigationLink(destination: HealthcareExportView()) {
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
                    NavigationLink(destination: PrivacyPolicyView()) {
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

                    NavigationLink(destination: DataDeletionRequestView()) {
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
                    NavigationLink(destination: LocalStorageSettingsView()) {
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
                    NavigationLink(destination: DeleteAccountView()) {
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
                            .foregroundStyle(Color.accentColor)
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
                            .foregroundStyle(Color.accentColor)
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
                            .foregroundStyle(Color.accentColor)
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
