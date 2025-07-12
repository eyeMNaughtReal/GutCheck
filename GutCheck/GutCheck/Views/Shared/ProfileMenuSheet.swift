import SwiftUI

struct ProfileMenuSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: SettingsView()) {
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
        }
    }
}
