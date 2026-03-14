import SwiftUI

struct ProfileMenuSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(value: ProfileMenuRoute.settings) {
                        Text("Settings")
                    }
                    Button("Privacy Policy") {
                        // TODO: Open privacy policy
                        dismiss()
                    }
                    Button("Export Data") {
                        // TODO: Trigger export
                        dismiss()
                    }
                    NavigationLink(value: ProfileMenuRoute.reminders) {
                        Label("Reminders", systemImage: "bell.badge")
                    }
                }

                Section {
                    Button("Log Out", role: .destructive) {
                        // TODO: Trigger logout logic
                        dismiss()
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ProfileMenuRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView()
                case .reminders:
                    UserRemindersView()
                }
            }
        }
    }
}
