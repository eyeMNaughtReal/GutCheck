import SwiftUI
import HealthKit

struct HealthDataIntegrationView: View {
    @StateObject private var healthKitVM = HealthKitViewModel()
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Health Data")) {
                    if let _ = healthKitVM.healthData {
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
                Task {
                    await healthKitVM.fetchHealthData()
                }
            }
        }
    }
}
