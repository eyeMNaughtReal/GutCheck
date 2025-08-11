import SwiftUI
import FirebaseAuth
import Network

struct DebugView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var showingResetConfirmation = false
    @State private var isResetting = false
    @State private var resetError: Error?
    
    var body: some View {
        NavigationView {
            List {
                // App Info
                Section("App Information") {
                    LabeledContent("Version", value: Constants.appVersion)
                    LabeledContent("Build", value: Bundle.main.buildNumber)
                    LabeledContent("Environment", value: Constants.API.baseURL.contains("production") ? "Production" : "Development")
                }
                
                // Network Status
                Section("Network Status") {
                    LabeledContent("Connected", value: networkMonitor.isConnected ? "Yes" : "No")
                }
                
                // User Info
                if let user = authService.currentUser {
                    Section("User Information") {
                        LabeledContent("User ID", value: user.id)
                        LabeledContent("Email", value: user.email)
                        LabeledContent("Name", value: user.fullName)
                    }
                }
                
                // Firebase Auth Info
                if let firebaseUser = authService.authUser {
                    Section("Firebase Auth") {
                        LabeledContent("UID", value: firebaseUser.uid)
                        if let lastSignIn = firebaseUser.metadata.lastSignInDate {
                            LabeledContent("Last Sign In", value: lastSignIn.formattedDateTime)
                        }
                    }
                }
                
                // Feature Flags
                Section("Feature Flags") {
                    Toggle("HealthKit Integration", isOn: .constant(Constants.Features.enableHealthKit))
                        .disabled(true)
                    Toggle("LiDAR Scanning", isOn: .constant(Constants.Features.enableLiDAR))
                        .disabled(true)
                    Toggle("AI Analysis", isOn: .constant(Constants.Features.enableAIAnalysis))
                        .disabled(true)
                }
                
                // Debug Actions
                Section("Debug Actions") {
                    Button("Clear Local Cache", role: .destructive) {
                        showingResetConfirmation = true
                    }
                    
                    NavigationLink("View Logs") {
                        LogViewer()
                    }
                    
                    NavigationLink("Network Requests") {
                        NetworkDebugger()
                    }
                }
            }
            .navigationTitle("Debug Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Reset Application", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    Task { await resetApplication() }
                }
            } message: {
                Text("This will clear all local data. This action cannot be undone.")
            }
            .alert("Reset Error", isPresented: .constant(resetError != nil)) {
                Button("OK") { resetError = nil }
            } message: {
                if let error = resetError {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    private func resetApplication() async {
        isResetting = true
        defer { isResetting = false }
        
        do {
            // Clear UserDefaults
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            
            // Clear Core Data
            try await LocalStorageService.shared.clearAllPrivateData()
            
            // Clear document directory
            try FileManager.default.clearDocumentDirectory()
            
            // Sign out user
            try Auth.auth().signOut()
            
            dismiss()
        } catch {
            resetError = error
        }
    }
}

// MARK: - Supporting Views

private struct LogViewer: View {
    @State private var logs: [String] = []
    
    var body: some View {
        List(logs, id: \.self) { log in
            Text(log)
                .font(.system(.body, design: .monospaced))
        }
        .navigationTitle("Application Logs")
        .onAppear {
            // Load logs from file system
            logs = (try? FileManager.default.loadLogs()) ?? []
        }
    }
}

private struct NetworkDebugger: View {
    @StateObject private var viewModel = NetworkDebuggerViewModel()
    
    var body: some View {
        List(viewModel.requests) { request in
            VStack(alignment: .leading, spacing: 8) {
                Text(request.url)
                    .font(.headline)
                Text(request.method)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let statusCode = request.statusCode {
                    Text("Status: \(statusCode)")
                        .foregroundColor(statusCode >= 400 ? .red : .green)
                }
            }
        }
        .navigationTitle("Network Requests")
        .onAppear {
            viewModel.loadRequests()
        }
    }
}

// MARK: - Supporting Types

private class NetworkDebuggerViewModel: ObservableObject {
    @Published var requests: [NetworkRequest] = []
    
    func loadRequests() {
        // Load network requests from debug storage
        // This would be implemented in a real debug system
    }
}

private struct NetworkRequest: Identifiable {
    let id = UUID()
    let url: String
    let method: String
    let statusCode: Int?
}

// MARK: - Extensions

private extension FileManager {
    func clearDocumentDirectory() throws {
        let urls = try contentsOfDirectory(
            at: urls(for: .documentDirectory, in: .userDomainMask)[0],
            includingPropertiesForKeys: nil
        )
        try urls.forEach { try removeItem(at: $0) }
    }
    
    func loadLogs() throws -> [String] {
        // Implementation would load from actual log files
        return []
    }
}
