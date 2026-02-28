import SwiftUI
import HealthKit

struct HealthDataIntegrationView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var authService: AuthService
    @StateObject private var healthKitVM = HealthKitViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showPermissionsGuide = false

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Connection
                Section(header: Text("Apple Health")) {
                    if healthKitVM.healthData != nil {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)

                        Button {
                            openHealthApp()
                        } label: {
                            Label("Open Health App", systemImage: "heart.circle")
                        }
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

                // MARK: - Manage iOS-level permissions
                Section(
                    header: Text("Permissions"),
                    footer: Text("Individual data type permissions are managed in the Apple Health app.")
                ) {
                    Button {
                        showPermissionsGuide = true
                    } label: {
                        HStack {
                            Label("Manage HealthKit Permissions", systemImage: "lock.shield")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                // MARK: - What GutCheck reads
                Section(
                    header: Text("Data GutCheck Reads"),
                    footer: Text("GutCheck reads these metrics from Apple Health to keep your profile up to date.")
                ) {
                    HealthTypeRow(icon: "scalemass",         color: .blue,   label: "Weight")
                    HealthTypeRow(icon: "ruler",             color: .blue,   label: "Height")
                    HealthTypeRow(icon: "heart.fill",        color: .red,    label: "Blood Pressure")
                    HealthTypeRow(icon: "drop.fill",         color: .red,    label: "Blood Glucose")
                    HealthTypeRow(icon: "waveform.path.ecg", color: .pink,   label: "Heart Rate")
                }

                // MARK: - Medications
                Section(
                    header: Text("Medications"),
                    footer: Text("Track your medications manually within GutCheck to help surface insights about how they affect your gut health.")
                ) {
                    NavigationLink(destination: MedicationListView()) {
                        Label("My Medications", systemImage: "pills.fill")
                            .foregroundColor(.primary)
                    }
                }

                // MARK: - Sync toggle (read)
                Section(
                    header: Text("Sync Settings"),
                    footer: Text("When enabled, GutCheck checks for updated health metrics each time the app opens.")
                ) {
                    Toggle(isOn: $settingsVM.healthKitSyncEnabled) {
                        Label("Sync health data on launch", systemImage: "arrow.clockwise.heart")
                    }
                }

                // MARK: - Current snapshot (only if connected)
                if healthKitVM.healthData != nil {
                    Section(header: Text("Current Health Data")) {
                        HealthDataRow(label: "Age",            value: healthKitVM.formattedAge())
                        HealthDataRow(label: "Biological Sex", value: healthKitVM.formattedBiologicalSex())
                        HealthDataRow(label: "Height",         value: healthKitVM.formattedHeight())
                        HealthDataRow(label: "Weight",         value: healthKitVM.formattedWeight())

                        if let sys = healthKitVM.healthData?.bloodPressureSystolic,
                           let dia = healthKitVM.healthData?.bloodPressureDiastolic {
                            HealthDataRow(label: "Blood Pressure",
                                         value: "\(Int(sys))/\(Int(dia)) mmHg")
                        }
                        if let glucose = healthKitVM.healthData?.bloodGlucose {
                            HealthDataRow(label: "Blood Glucose",
                                         value: String(format: "%.1f mg/dL", glucose))
                        }
                        if let hr = healthKitVM.healthData?.heartRate {
                            HealthDataRow(label: "Heart Rate", value: "\(Int(hr)) BPM")
                        }

                        Button("Refresh Health Data") {
                            Task { await healthKitVM.fetchHealthData() }
                        }
                        .foregroundColor(.accentColor)
                    }
                }

                // MARK: - What GutCheck writes — Meals
                Section(
                    header: Text("Data GutCheck Writes"),
                    footer: writesFooter
                ) {
                    // ── Meals header row ──────────────────────────────────────────
                    HStack {
                        HealthTypeRow(icon: "fork.knife", color: .orange, label: "Meals")
                        Spacer()
                        Toggle("", isOn: $settingsVM.healthKitWriteMeals)
                            .labelsHidden()
                    }

                    WritePermissionRow(
                        name: "Dietary Energy (Calories)",
                        status: healthKitVM.mealWriteStatuses[.dietaryEnergyConsumed]
                    )
                    WritePermissionRow(
                        name: "Carbohydrates",
                        status: healthKitVM.mealWriteStatuses[.dietaryCarbohydrates]
                    )
                    WritePermissionRow(
                        name: "Protein",
                        status: healthKitVM.mealWriteStatuses[.dietaryProtein]
                    )
                    WritePermissionRow(
                        name: "Total Fat",
                        status: healthKitVM.mealWriteStatuses[.dietaryFatTotal]
                    )
                    WritePermissionRow(
                        name: "Dietary Fiber",
                        status: healthKitVM.mealWriteStatuses[.dietaryFiber]
                    )
                    WritePermissionRow(
                        name: "Dietary Sugar",
                        status: healthKitVM.mealWriteStatuses[.dietarySugar]
                    )
                    WritePermissionRow(
                        name: "Sodium",
                        status: healthKitVM.mealWriteStatuses[.dietarySodium]
                    )

                    Divider()
                        .listRowInsets(EdgeInsets())

                    // ── Symptoms header row ───────────────────────────────────────
                    HStack {
                        HealthTypeRow(icon: "cross.case.fill", color: .purple, label: "Symptoms")
                        Spacer()
                        Toggle("", isOn: $settingsVM.healthKitWriteSymptoms)
                            .labelsHidden()
                    }

                    WritePermissionRow(
                        name: "Abdominal Cramps",
                        status: healthKitVM.symptomWriteStatuses[.abdominalCramps]
                    )
                    WritePermissionRow(
                        name: "Diarrhea",
                        status: healthKitVM.symptomWriteStatuses[.diarrhea]
                    )
                    WritePermissionRow(
                        name: "Constipation",
                        status: healthKitVM.symptomWriteStatuses[.constipation]
                    )
                    WritePermissionRow(
                        name: "Bloating",
                        status: healthKitVM.symptomWriteStatuses[.bloating]
                    )
                    WritePermissionRow(
                        name: "Nausea",
                        status: healthKitVM.symptomWriteStatuses[.nausea]
                    )
                }

                // MARK: - Permission action button
                if healthKitVM.hasWriteIssues {
                    Section {
                        if healthKitVM.hasUndeterminedWrites {
                            // Some types have never been requested — re-request will show a prompt
                            Button {
                                Task { await healthKitVM.requestHealthKitAccess() }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                    Text("Request Write Permissions")
                                }
                            }
                            .foregroundColor(.accentColor)
                        }

                        if healthKitVM.hasDeniedWrites {
                            // Denied types require the user to go to the Health app manually
                            Button {
                                openHealthApp()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.forward.app.fill")
                                    Text("Enable in Health App Settings")
                                }
                            }
                            .foregroundColor(.orange)
                        }
                    }
                }
            }
            .navigationTitle("Apple Health")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showPermissionsGuide) {
                HealthKitPermissionsGuideView()
            }
            .alert("HealthKit permission denied or unavailable.", isPresented: $healthKitVM.showPermissionError) {
                Button("OK", role: .cancel) {}
            }
            .onAppear {
                healthKitVM.updateDependencies(settingsViewModel: settingsVM, authService: authService)
                Task { await healthKitVM.fetchHealthData() }
                healthKitVM.refreshWriteStatuses()
            }
        }
    }

    // MARK: - Footer helper

    @ViewBuilder
    private var writesFooter: some View {
        if healthKitVM.hasDeniedWrites {
            Text("Some write permissions are denied. Go to Health App → Privacy → Apps → GutCheck to re-enable them.")
                .foregroundColor(.orange)
        } else if healthKitVM.hasUndeterminedWrites {
            Text("Tap \"Request Write Permissions\" below to grant write access for types not yet authorized.")
        } else {
            Text("Choose which GutCheck data is shared back to Apple Health.")
        }
    }

    private func openHealthApp() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Permissions Guide Sheet (MFP-style step-by-step)

struct HealthKitPermissionsGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("To adjust which data Apple Health and GutCheck share with each other, you'll need to manage permissions directly in the Health app.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }

                Section(header: Text("How to manage permissions")) {
                    GuideStepRow(
                        icon: "heart.fill",
                        iconColor: .red,
                        iconBackground: .white,
                        step: "Open the Health App",
                        detail: "Open the Apple Health app on your iPhone."
                    )
                    GuideStepRow(
                        icon: "person.circle.fill",
                        iconColor: .blue,
                        iconBackground: .white,
                        step: "Tap your Profile icon",
                        detail: "Tap your profile picture or initials in the upper-right corner."
                    )
                    GuideStepRow(
                        icon: "hand.point.up.fill",
                        iconColor: .gray,
                        iconBackground: .white,
                        step: "Go to Privacy › Apps",
                        detail: "Scroll down to the Privacy section and tap Apps."
                    )
                    GuideStepRow(
                        icon: "cross.circle.fill",
                        iconColor: .accentColor,
                        iconBackground: .white,
                        step: "Select GutCheck",
                        detail: "Find GutCheck in the list. Tap \"Data from GutCheck\" to control write permissions for each data type."
                    )
                }

                Section {
                    Button {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Label("Open Health App", systemImage: "heart.circle.fill")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Health App Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

// MARK: - Guide Step Row

private struct GuideStepRow: View {
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let step: String
    let detail: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(step)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(step). \(detail)")
    }
}

// MARK: - Write Permission Row (indented, with status badge)

private struct WritePermissionRow: View {
    let name: String
    let status: HKAuthorizationStatus?

    private var statusConfig: (icon: String, color: Color, label: String) {
        switch status {
        case .sharingAuthorized:
            return ("checkmark.circle.fill", .green, "Authorized")
        case .sharingDenied:
            return ("xmark.circle.fill",     .red,   "Denied")
        default:
            return ("circle",                .secondary, "Not set")
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Indent to align under parent category name
            Color.clear.frame(width: 32, height: 1)

            Text(name)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: statusConfig.icon)
                .foregroundColor(statusConfig.color)
                .font(.system(size: 15))
                .accessibilityLabel(statusConfig.label)
        }
    }
}

// MARK: - Health Type Row (icon + label, no value)

private struct HealthTypeRow: View {
    let icon: String
    let color: Color
    let label: String

    var body: some View {
        Label {
            Text(label)
        } icon: {
            Image(systemName: icon)
                .foregroundColor(color)
        }
    }
}

// MARK: - Health Data Row (label + value)

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
