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
                Section(header: Text("Health Data")) {
                    if let _ = healthKitVM.healthData {
                        Text("Age: \(healthKitVM.formattedAge())")
                        Text("Sex: \(healthKitVM.formattedBiologicalSex())")
                        Text("Height: \(healthKitVM.formattedHeight())")
                        Text("Weight: \(healthKitVM.formattedWeight())")
                    } else {
                        Button("Enable HealthKit Access") {
                            Task {
                                await healthKitVM.requestHealthKitAccess()
                                // After getting health data, update the user profile
                                if healthKitVM.healthData != nil {
                                    await healthKitVM.updateUserProfileWithHealthData()
                                }
                            }
                        }
                    }
                }
                
                if healthKitVM.healthData != nil {
                    Section(header: Text("Profile Sync")) {
                        Button("Update Profile with Health Data") {
                            Task {
                                await healthKitVM.updateUserProfileWithHealthData()
                            }
                        }
                        .foregroundColor(.blue)
                        
                        Text("This will update your profile with the latest health information from Apple Health.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Health Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("HealthKit permission denied or unavailable.", isPresented: $healthKitVM.showPermissionError) {
                Button("OK", role: .cancel) {}
            }
            .onAppear {
                // Update the HealthKitViewModel with environment dependencies
                healthKitVM.updateDependencies(settingsViewModel: settingsVM, authService: authService)
                Task {
                    await healthKitVM.fetchHealthData()
                }
            }
        }
    }
}
