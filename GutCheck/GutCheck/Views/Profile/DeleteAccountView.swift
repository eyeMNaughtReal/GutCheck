//
//  DeleteAccountView.swift
//  GutCheck
//
//  View for deleting user account with proper security measures
//  and re-authentication requirements.
//
//  Created by Mark Conley on 8/18/25.
//

import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var showingReauthentication = false
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
                    
                    Text("Delete Your Account")
                        .font(.title.bold())
                        .foregroundStyle(.red)
                    
                    Text("This action cannot be undone")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                // Consequences Warning
                VStack(alignment: .leading, spacing: 16) {
                    Text("What will happen:")
                        .font(.headline)
                        .foregroundStyle(.red)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        WarningRow(icon: "trash", text: "All your health data will be permanently deleted")
                        WarningRow(icon: "chart.bar", text: "All insights and patterns will be lost")
                        WarningRow(icon: "calendar", text: "Your meal and symptom history will be erased")
                        WarningRow(icon: "person.crop.circle", text: "Your profile and settings will be removed")
                        WarningRow(icon: "icloud", text: "Data cannot be recovered from backups")
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                
                // Data Summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Data that will be deleted:")
                        .font(.headline)
                    
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
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: { showingReauthentication = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete My Account")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
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
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReauthentication) {
            ReauthenticationView(
                operation: "deleting your account",
                onSuccess: { showingFinalConfirmation = true },
                onCancel: { showingReauthentication = false }
            )
        }
        .alert("Final Confirmation", isPresented: $showingFinalConfirmation) {
            Button("Delete Account", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you absolutely sure you want to delete your account? This action is permanent and cannot be undone.")
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if alertTitle == "Account Deleted" {
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
                // User was already re-authenticated via ReauthenticationView
                try await authService.deleteAuthenticatedAccount()
                
                await MainActor.run {
                    alertTitle = "Account Deleted"
                    alertMessage = "Your account has been successfully deleted."
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
                .font(.body)
            
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
                .font(.body)
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        DeleteAccountView()
            .environmentObject(AuthService())
    }
}
