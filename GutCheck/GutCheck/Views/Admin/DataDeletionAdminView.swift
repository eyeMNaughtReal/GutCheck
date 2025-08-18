//
//  DataDeletionAdminView.swift
//  GutCheck
//
//  Admin view for managing data deletion requests
//
//  Created by Mark Conley on 8/18/25.
//

import SwiftUI

struct DataDeletionAdminView: View {
    @StateObject private var deletionService = DataDeletionService.shared
    @State private var deletionRequests: [DataDeletionRequest] = []
    @State private var selectedRequest: DataDeletionRequest?
    @State private var showingRequestDetail = false
    @State private var showingStatusUpdate = false
    @State private var newStatus: DeletionStatus = .pending
    @State private var adminNotes = ""
    
    var body: some View {
        NavigationStack {
            List {
                if deletionRequests.isEmpty {
                    ContentUnavailableView(
                        "No Deletion Requests",
                        systemImage: "doc.text",
                        description: Text("There are currently no data deletion requests to review.")
                    )
                } else {
                    ForEach(deletionRequests) { request in
                        DeletionRequestRow(request: request) {
                            selectedRequest = request
                            showingRequestDetail = true
                        }
                    }
                }
            }
            .navigationTitle("Deletion Requests")
            .refreshable {
                await loadDeletionRequests()
            }
            .sheet(isPresented: $showingRequestDetail) {
                if let request = selectedRequest {
                    DeletionRequestDetailView(
                        request: request,
                        onStatusUpdate: { status, notes in
                            Task {
                                await updateRequestStatus(requestId: request.id, status: status, notes: notes)
                            }
                        }
                    )
                }
            }
            .task {
                await loadDeletionRequests()
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadDeletionRequests() async {
        do {
            deletionRequests = try await deletionService.fetchAllDeletionRequests()
        } catch {
            deletionService.errorMessage = error.localizedDescription
        }
    }
    
    private func updateRequestStatus(requestId: String, status: DeletionStatus, notes: String) async {
        do {
            try await deletionService.updateDeletionRequestStatus(
                requestId: requestId,
                status: status,
                adminNotes: notes.isEmpty ? nil : notes,
                processedBy: "Admin"
            )
            
            // Reload requests to show updated status
            await loadDeletionRequests()
            
        } catch {
            deletionService.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Deletion Request Row

struct DeletionRequestRow: View {
    let request: DataDeletionRequest
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.userName)
                            .font(.headline)
                        
                        Text(request.userEmail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        StatusBadge(status: request.status)
                        
                        Text(request.formattedRequestDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let reason = request.reason, !reason.isEmpty {
                    Text("Reason: \(reason)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("Data to delete:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        if request.deleteUserProfile {
                            DataTypeBadge(text: "Profile", color: .red)
                        }
                        if request.deleteMeals {
                            DataTypeBadge(text: "Meals", color: .orange)
                        }
                        if request.deleteSymptoms {
                            DataTypeBadge(text: "Symptoms", color: .blue)
                        }
                        if request.deleteHealthData {
                            DataTypeBadge(text: "Health", color: .green)
                        }
                        if request.deleteAnalytics {
                            DataTypeBadge(text: "Analytics", color: .purple)
                        }
                        if request.deleteReminders {
                            DataTypeBadge(text: "Reminders", color: .pink)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: DeletionStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .clipShape(Capsule())
    }
}

// MARK: - Data Type Badge

struct DataTypeBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

// MARK: - Deletion Request Detail View

struct DeletionRequestDetailView: View {
    let request: DataDeletionRequest
    let onStatusUpdate: (DeletionStatus, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStatus: DeletionStatus
    @State private var adminNotes = ""
    
    init(request: DataDeletionRequest, onStatusUpdate: @escaping (DeletionStatus, String) -> Void) {
        self.request = request
        self.onStatusUpdate = onStatusUpdate
        self._selectedStatus = State(initialValue: request.status)
        self._adminNotes = State(initialValue: request.adminNotes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("User Information") {
                    LabeledContent("Name", value: request.userName)
                    LabeledContent("Email", value: request.userEmail)
                    LabeledContent("Request Date", value: request.formattedRequestDate)
                    
                    if let processedDate = request.formattedProcessedDate {
                        LabeledContent("Processed Date", value: processedDate)
                    }
                    
                    if let processedBy = request.processedBy {
                        LabeledContent("Processed By", value: processedBy)
                    }
                }
                
                if let reason = request.reason, !reason.isEmpty {
                    Section("Reason for Deletion") {
                        Text(reason)
                            .font(.body)
                    }
                }
                
                Section("Data to Delete") {
                    DataScopeRow(title: "User Profile", isSelected: request.deleteUserProfile, color: .red)
                    DataScopeRow(title: "Meals & Food Logs", isSelected: request.deleteMeals, color: .orange)
                    DataScopeRow(title: "Symptoms & Health Logs", isSelected: request.deleteSymptoms, color: .blue)
                    DataScopeRow(title: "Health Data", isSelected: request.deleteHealthData, color: .green)
                    DataScopeRow(title: "Analytics & Insights", isSelected: request.deleteAnalytics, color: .purple)
                    DataScopeRow(title: "Reminders & Settings", isSelected: request.deleteReminders, color: .pink)
                }
                
                if request.isProcessed, let adminNotes = request.adminNotes {
                    Section("Admin Notes") {
                        Text(adminNotes)
                            .font(.body)
                    }
                }
                
                if !request.isProcessed {
                    Section("Update Status") {
                        Picker("Status", selection: $selectedStatus) {
                            ForEach(DeletionStatus.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        TextField("Admin Notes (Optional)", text: $adminNotes, axis: .vertical)
                            .lineLimit(3...6)
                        
                        Button("Update Status") {
                            onStatusUpdate(selectedStatus, adminNotes)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(selectedStatus == .rejected ? .red : .blue)
                        .disabled(selectedStatus == request.status)
                    }
                }
            }
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Data Scope Row

struct DataScopeRow: View {
    let title: String
    let isSelected: Bool
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(color)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    DataDeletionAdminView()
}
