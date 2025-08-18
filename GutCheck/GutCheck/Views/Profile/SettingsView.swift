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
                            Spacer()
                            Text(settingsVM.language.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink(destination: UnitSelectionView()) {
                        HStack {
                            Text("Units")
                            Spacer()
                            Text(settingsVM.unitOfMeasure.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Healthcare") {
                    NavigationLink(destination: HealthcareExportView()) {
                        HStack {
                            Image(systemName: "heart.text.square")
                                .foregroundColor(.blue)
                            Text("Export Health Data")
                            Spacer()
                            Text("For Healthcare Professionals")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
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
                    Button("Close") { dismiss() }
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
                    Spacer()
                    if lang == settingsVM.language {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { settingsVM.language = lang }
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
                    Spacer()
                    if unit == settingsVM.unitOfMeasure {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { settingsVM.unitOfMeasure = unit }
            }
        }
        .navigationTitle("Units")
    }
}
