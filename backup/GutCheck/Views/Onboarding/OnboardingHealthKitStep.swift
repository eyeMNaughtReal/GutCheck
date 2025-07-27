import SwiftUI
struct OnboardingHealthKitStep: View {
    @StateObject private var healthKitVM = HealthKitViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Access Your Health Data")
                .font(.title)
                .bold()

            Text("We use Apple Health data to help personalize your nutrition and symptom insights. This includes:")
                .font(.subheadline)

            VStack(alignment: .leading) {
                Label("📅 Date of Birth", systemImage: "calendar")
                Label("📏 Height", systemImage: "ruler")
                Label("⚖️ Weight", systemImage: "scalemass")
            }
            .padding(.vertical)

            Button("Enable HealthKit") {
                Task {
                    await healthKitVM.requestHealthKitAccess()
                }
            }
            .buttonStyle(.borderedProminent)

            if healthKitVM.showPermissionError {
                Text("Permission denied. You can change this in Settings.")
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}
