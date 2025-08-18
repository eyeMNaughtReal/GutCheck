//
//  DataDeletionRequestView.swift
//  GutCheck
//
//  View for requesting data deletion
//
//  Created by Mark Conley on 8/18/25.
//

import SwiftUI

struct DataDeletionRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var deletionService = DataDeletionService.shared
    
    @State private var reason = ""
    @State private var deleteUserProfile = true
    @State private var deleteMeals = true
    @State private var deleteSymptoms = true
    @State private var deleteHealthData = true
    @State private var deleteAnalytics = true
    @State private var deleteReminders = true
    
    @State private var showingConfirmation = false
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Data Deletion Request")
                                .font(.headline)
                        }
                        
                        Text("This will submit a request to delete your data. The request will be reviewed by our team before any data is permanently removed.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Reason for Deletion (Optional)") {
                    TextField("Why are you requesting data deletion?", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Data to Delete") {
                    Toggle("User Profile", isOn: $deleteUserProfile)
                        .tint(.red)
                    
                    Toggle("Meals & Food Logs", isOn: $deleteMeals)
                        .tint(.red)
                    
                    Toggle("Symptoms & Health Logs", isOn: $deleteSymptoms)
                        .tint(.red)
                    
                    Toggle("Health Data", isOn: $deleteHealthData)
                        .tint(.red)
                    
                    Toggle("Analytics & Insights", isOn: $deleteAnalytics)
                        .tint(.red)
                    
                    Toggle("Reminders & Settings", isOn: $deleteReminders)
                        .tint(.red)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Important Notes:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("• This is a request, not an immediate deletion")
                        Text("• Your request will be reviewed within 30 days")
                        Text("• You will receive email confirmation")
                        Text("• You can cancel this request at any time")
                        Text("• Some data may be retained for legal compliance")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: submitRequest) {
                        HStack {
                            if deletionService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane")
                            }
                            Text("Submit Deletion Request")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(deletionService.isLoading || !hasSelectedData)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .navigationTitle("Data Deletion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Confirm Deletion Request", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Submit Request", role: .destructive) {
                    Task {
                        await submitDeletionRequest()
                    }
                }
            } message: {
                Text("Are you sure you want to submit a data deletion request? This action cannot be undone.")
            }
            .alert("Request Submitted", isPresented: $showingSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your data deletion request has been submitted successfully. You will receive an email confirmation within 24 hours.")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasSelectedData: Bool {
        deleteUserProfile || deleteMeals || deleteSymptoms || 
        deleteHealthData || deleteAnalytics || deleteReminders
    }
    
    // MARK: - Actions
    
    private func submitRequest() {
        showingConfirmation = true
    }
    
    private func submitDeletionRequest() async {
        guard let currentUser = authService.currentUser else {
            deletionService.errorMessage = "User not authenticated"
            return
        }
        
        do {
            try await deletionService.createDeletionRequest(
                userId: currentUser.id,
                userEmail: currentUser.email,
                userName: currentUser.fullName,
                reason: reason.isEmpty ? nil : reason,
                deleteUserProfile: deleteUserProfile,
                deleteMeals: deleteMeals,
                deleteSymptoms: deleteSymptoms,
                deleteHealthData: deleteHealthData,
                deleteAnalytics: deleteAnalytics,
                deleteReminders: deleteReminders
            )
            
            showingSuccess = true
            
        } catch {
            deletionService.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    DataDeletionRequestView()
        .environmentObject(AuthService())
}
