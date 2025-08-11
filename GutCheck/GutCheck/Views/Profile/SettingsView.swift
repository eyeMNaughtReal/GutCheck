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
