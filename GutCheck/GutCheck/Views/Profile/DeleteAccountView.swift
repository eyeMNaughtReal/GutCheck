//
//  DeleteAccountView.swift
//  GutCheck
//
//  View for erasing everything the app holds on this device.
//
//  There is no account and no server, so there is nothing to re-authenticate
//  against — the confirmation alert is the last gate before the data goes.
//
//  Created by Mark Conley on 8/18/25.
//

import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalUserService.self) var userService
    @State private var showingFinalConfirmation = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isDeleting = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Warning Header
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 64))
                        .foregroundStyle(.red)
                    
                    Text("Delete All Your Data")
                        .font(.title.bold())
                        .foregroundStyle(.red)
                    
                    Text("This action cannot be undone")
                        .typography(Typography.headline)
                        .foregroundStyle(.secondary)
                }
                
                // Consequences Warning
                VStack(alignment: .leading, spacing: 16) {
                    Text("What will happen:")
                        .typography(Typography.headline)
                        .foregroundStyle(.red)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        WarningRow(icon: "trash", text: "All your health data will be permanently deleted")
                        WarningRow(icon: "chart.bar", text: "All insights and patterns will be lost")
                        WarningRow(icon: "calendar", text: "Your meal and symptom history will be erased")
                        WarningRow(icon: "person.crop.circle", text: "Your profile and settings will be removed")
                        WarningRow(icon: "iphone", text: "This is the only copy — nothing is stored anywhere else")
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .clipShape(.rect(cornerRadius: 12))
                
                // Data Summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Data that will be deleted:")
                        .typography(Typography.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        DataRow(icon: "fork.knife", text: "Meal logs and nutrition data")
                        DataRow(icon: "heart", text: "Symptom tracking and health patterns")
                        DataRow(icon: "chart.bar", text: "Insights and correlations")
                        DataRow(icon: "person", text: "User profile and preferences")
                        DataRow(icon: "gear", text: "App settings and configurations")
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(.rect(cornerRadius: 12))
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: { showingFinalConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete My Data")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                    .disabled(isDeleting)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(ColorTheme.background)
        .navigationTitle("Delete All Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Final Confirmation", isPresented: $showingFinalConfirmation) {
            Button("Delete Everything", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you absolutely sure? This permanently erases everything "
                 + "recorded on this device and cannot be undone.")
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if alertTitle == "Data Deleted" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func deleteAccount() {
        isDeleting = true
        
        Task {
            do {
                try await userService.deleteAllLocalData()
                
                await MainActor.run {
                    alertTitle = "Data Deleted"
                    alertMessage = "Everything recorded on this device has been erased."
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Deletion Failed"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isDeleting = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct WarningRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.red)
                .frame(width: 20)
            
            Text(text)
                .typography(Typography.body)
            
            Spacer()
        }
    }
}

struct DataRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 20)
            
            Text(text)
                .typography(Typography.body)
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        DeleteAccountView()
            .environment(LocalUserService.shared)
    }
}
