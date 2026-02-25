import SwiftUI
import HealthKit

struct HealthDataIntegrationView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var authService: AuthService
    @StateObject private var healthKitVM = HealthKitViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Connection status
                Section(header: Text("Apple Health")) {
                    if healthKitVM.healthData != nil {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button {
                            Task {
                                await healthKitVM.requestHealthKitAccess()
                                if healthKitVM.healthData != nil {
                                    await healthKitVM.updateUserProfileWithHealthData()
                                }
                            }
                        } label: {
                            Label("Enable Apple Health Access", systemImage: "heart.circle")
                        }
                    }
                }

                // MARK: - Read preferences (only shown once connected)
                if healthKitVM.healthData != nil {
                    Section(
                        header: Text("Sync from Apple Health"),
                        footer: Text("When enabled, GutCheck reads your latest health metrics each time the app opens.")
                    ) {
                        Toggle("Sync health data on launch", isOn: $settingsVM.healthKitSyncEnabled)
                    }

                    // MARK: - Health data snapshot
                    Section(header: Text("Current Health Data")) {
                        HealthDataRow(label: "Age", value: healthKitVM.formattedAge())
                        HealthDataRow(label: "Biological Sex", value: healthKitVM.formattedBiologicalSex())
                        HealthDataRow(label: "Height", value: healthKitVM.formattedHeight())
                        HealthDataRow(label: "Weight", value: healthKitVM.formattedWeight())

                        if let systolic = healthKitVM.healthData?.bloodPressureSystolic,
                           let diastolic = healthKitVM.healthData?.bloodPressureDiastolic {
                            HealthDataRow(label: "Blood Pressure",
                                         value: "\(Int(systolic))/\(Int(diastolic)) mmHg")
                        }
                        if let glucose = healthKitVM.healthData?.bloodGlucose {
                            HealthDataRow(label: "Blood Glucose",
                                         value: String(format: "%.1f mg/dL", glucose))
                        }
                        if let hr = healthKitVM.healthData?.heartRate {
                            HealthDataRow(label: "Heart Rate",
                                         value: "\(Int(hr)) BPM")
                        }

                        Button("Refresh Health Data") {
                            Task { await healthKitVM.fetchHealthData() }
                        }
                        .foregroundColor(.accentColor)
                    }
                }

                // MARK: - Write preferences
                Section(
                    header: Text("Write to Apple Health"),
                    footer: Text("Choose which GutCheck data is shared with the Apple Health app.")
                ) {
                    Toggle("Save meals to Apple Health", isOn: $settingsVM.healthKitWriteMeals)
                    Toggle("Save symptoms to Apple Health", isOn: $settingsVM.healthKitWriteSymptoms)
                }
            }
            .navigationTitle("Apple Health")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("HealthKit permission denied or unavailable.", isPresented: $healthKitVM.showPermissionError) {
                Button("OK", role: .cancel) {}
            }
            .onAppear {
                healthKitVM.updateDependencies(settingsViewModel: settingsVM, authService: authService)
                Task { await healthKitVM.fetchHealthData() }
            }
        }
    }
}

// MARK: - Helper row
private struct HealthDataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
