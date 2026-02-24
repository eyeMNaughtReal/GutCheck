// SettingsView.swift
// GutCheck
//
// Updated with Phase 2 Accessibility - February 23, 2026

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
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
                }
                
                Section("Healthcare") {
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
                            Text("Privacy Policy")
                        }
                    }
                    
                    NavigationLink(destination: DataDeletionRequestView()) {
                        HStack {
                            Image(systemName: "trash.circle")
                                .foregroundColor(.orange)
                            Text("Request Data Deletion")
                            Spacer()
                            Text("GDPR Right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.shield")
                            .foregroundColor(.blue)
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
                    }
                    .padding(.vertical, 4)
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
