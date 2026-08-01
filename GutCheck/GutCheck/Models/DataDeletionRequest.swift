//
//  DataDeletionRequest.swift
//  GutCheck
//
//  Model for tracking data deletion requests
//
//  Created by Mark Conley on 8/18/25.
//

import Foundation

struct DataDeletionRequest: Codable, Identifiable, Hashable, Equatable {
    let id: String
    let userId: String
    let userEmail: String
    let userName: String
    let requestDate: Date
    let reason: String?
    /// Mutable so the request can be marked complete once the erase has run.
    var status: DeletionStatus
    var adminNotes: String?
    var processedDate: Date?
    var processedBy: String?
    
    // Data scope for deletion
    let deleteUserProfile: Bool
    let deleteMeals: Bool
    let deleteSymptoms: Bool
    let deleteHealthData: Bool
    let deleteAnalytics: Bool
    let deleteReminders: Bool
    
    // Computed properties
    var isPending: Bool {
        status == .pending
    }
    
    var isApproved: Bool {
        status == .approved
    }
    
    var isRejected: Bool {
        status == .rejected
    }
    
    var isProcessed: Bool {
        status == .approved || status == .rejected
    }
    
    var formattedRequestDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: requestDate)
    }
    
    var formattedProcessedDate: String? {
        guard let processedDate = processedDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: processedDate)
    }
    
    // MARK: - Initializers
    
    init(id: String = UUID().uuidString,
         userId: String,
         userEmail: String,
         userName: String,
         requestDate: Date = Date.now,
         reason: String? = nil,
         status: DeletionStatus = .pending,
         adminNotes: String? = nil,
         processedDate: Date? = nil,
         processedBy: String? = nil,
         deleteUserProfile: Bool = true,
         deleteMeals: Bool = true,
         deleteSymptoms: Bool = true,
         deleteHealthData: Bool = true,
         deleteAnalytics: Bool = true,
         deleteReminders: Bool = true) {
        self.id = id
        self.userId = userId
        self.userEmail = userEmail
        self.userName = userName
        self.requestDate = requestDate
        self.reason = reason
        self.status = status
        self.adminNotes = adminNotes
        self.processedDate = processedDate
        self.processedBy = processedBy
        self.deleteUserProfile = deleteUserProfile
        self.deleteMeals = deleteMeals
        self.deleteSymptoms = deleteSymptoms
        self.deleteHealthData = deleteHealthData
        self.deleteAnalytics = deleteAnalytics
        self.deleteReminders = deleteReminders
    }
}

// MARK: - Deletion Status

enum DeletionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case processing = "processing"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending Review"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        case .processing:
            return "Processing"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "orange"
        case .approved:
            return "green"
        case .rejected:
            return "red"
        case .processing:
            return "blue"
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock"
        case .approved:
            return "checkmark.circle"
        case .rejected:
            return "xmark.circle"
        case .processing:
            return "gear"
        }
    }
}
