//
//  DataDeletionRequest.swift
//  GutCheck
//
//  Model for tracking data deletion requests
//
//  Created by Mark Conley on 8/18/25.
//

import Foundation
import FirebaseFirestore

struct DataDeletionRequest: Codable, Identifiable, Hashable, Equatable {
    let id: String
    let userId: String
    let userEmail: String
    let userName: String
    let requestDate: Date
    let reason: String?
    let status: DeletionStatus
    let adminNotes: String?
    let processedDate: Date?
    let processedBy: String?
    
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
         requestDate: Date = Date(),
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
    
    // MARK: - Firestore Conversion
    
    init?(from firestoreData: [String: Any], id: String) {
        guard let userId = firestoreData["userId"] as? String,
              let userEmail = firestoreData["userEmail"] as? String,
              let userName = firestoreData["userName"] as? String,
              let requestDateTimestamp = firestoreData["requestDate"] as? Timestamp,
              let statusString = firestoreData["status"] as? String,
              let status = DeletionStatus(rawValue: statusString),
              let deleteUserProfile = firestoreData["deleteUserProfile"] as? Bool,
              let deleteMeals = firestoreData["deleteMeals"] as? Bool,
              let deleteSymptoms = firestoreData["deleteSymptoms"] as? Bool,
              let deleteHealthData = firestoreData["deleteHealthData"] as? Bool,
              let deleteAnalytics = firestoreData["deleteAnalytics"] as? Bool,
              let deleteReminders = firestoreData["deleteReminders"] as? Bool else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.userEmail = userEmail
        self.userName = userName
        self.requestDate = requestDateTimestamp.dateValue()
        self.reason = firestoreData["reason"] as? String
        self.status = status
        self.adminNotes = firestoreData["adminNotes"] as? String
        
        if let processedDateTimestamp = firestoreData["processedDate"] as? Timestamp {
            self.processedDate = processedDateTimestamp.dateValue()
        } else {
            self.processedDate = nil
        }
        
        self.processedBy = firestoreData["processedBy"] as? String
        self.deleteUserProfile = deleteUserProfile
        self.deleteMeals = deleteMeals
        self.deleteSymptoms = deleteSymptoms
        self.deleteHealthData = deleteHealthData
        self.deleteAnalytics = deleteAnalytics
        self.deleteReminders = deleteReminders
    }
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "userId": userId,
            "userEmail": userEmail,
            "userName": userName,
            "requestDate": Timestamp(date: requestDate),
            "status": status.rawValue,
            "deleteUserProfile": deleteUserProfile,
            "deleteMeals": deleteMeals,
            "deleteSymptoms": deleteSymptoms,
            "deleteHealthData": deleteHealthData,
            "deleteAnalytics": deleteAnalytics,
            "deleteReminders": deleteReminders
        ]
        
        if let reason = reason {
            data["reason"] = reason
        }
        
        if let adminNotes = adminNotes {
            data["adminNotes"] = adminNotes
        }
        
        if let processedDate = processedDate {
            data["processedDate"] = Timestamp(date: processedDate)
        }
        
        if let processedBy = processedBy {
            data["processedBy"] = processedBy
        }
        
        return data
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
