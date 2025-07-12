import SwiftUI
import HealthKit

struct SettingsView: View {
    @StateObject private var healthKitVM = HealthKitViewModel()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Health Data")) {
                    if let _ = healthKitVM.profile {
                        Text("Age: \(healthKitVM.formattedAge())")
                        Text("Height: \(healthKitVM.formattedHeight())")
                        Text("Weight: \(healthKitVM.formattedWeight())")
                    } else {
                        Button("Enable HealthKit Access") {
                            Task {
                                await healthKitVM.requestHealthKitAccess()
                            }
                        }
                    }
                }

                // MARK: - Add other settings sections here
                // Example:
                // Section(header: Text("Preferences")) { ... }
            }
            .navigationTitle("Settings")
            .alert("HealthKit permission denied or unavailable.", isPresented: $healthKitVM.showPermissionError) {
                Button("OK", role: .cancel) {}
            }
            .onAppear {
                Task {
                    await healthKitVM.fetchProfile()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
