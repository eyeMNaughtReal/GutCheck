//
//  DataDeletionService.swift
//  GutCheck
//
//  Service for handling data deletion requests and processing
//
//  Created by Mark Conley on 8/18/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class DataDeletionService: ObservableObject {
    static let shared = DataDeletionService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firestore = Firestore.firestore()
    private let auth = Auth.auth()
    
    private init() {}
    
    // MARK: - Data Deletion Request Management
    
    /// Creates a new data deletion request
    func createDeletionRequest(
        userId: String,
        userEmail: String,
        userName: String,
        reason: String? = nil,
        deleteUserProfile: Bool = true,
        deleteMeals: Bool = true,
        deleteSymptoms: Bool = true,
        deleteHealthData: Bool = true,
        deleteAnalytics: Bool = true,
        deleteReminders: Bool = true
    ) async throws -> DataDeletionRequest {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let request = DataDeletionRequest(
            userId: userId,
            userEmail: userEmail,
            userName: userName,
            reason: reason,
            deleteUserProfile: deleteUserProfile,
            deleteMeals: deleteMeals,
            deleteSymptoms: deleteSymptoms,
            deleteHealthData: deleteHealthData,
            deleteAnalytics: deleteAnalytics,
            deleteReminders: deleteReminders
        )
        
        // Save to Firestore
        try await firestore
            .collection("dataDeletionRequests")
            .document(request.id)
            .setData(request.toFirestoreData())
        
        return request
    }
    
    /// Fetches all deletion requests (admin only)
    func fetchAllDeletionRequests() async throws -> [DataDeletionRequest] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let snapshot = try await firestore
            .collection("dataDeletionRequests")
            .order(by: "requestDate", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            DataDeletionRequest(from: document.data(), id: document.documentID)
        }
    }
    
    /// Fetches deletion requests for a specific user
    func fetchUserDeletionRequests(userId: String) async throws -> [DataDeletionRequest] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let snapshot = try await firestore
            .collection("dataDeletionRequests")
            .whereField("userId", isEqualTo: userId)
            .order(by: "requestDate", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            DataDeletionRequest(from: document.data(), id: document.documentID)
        }
    }
    
    /// Updates the status of a deletion request
    func updateDeletionRequestStatus(
        requestId: String,
        status: DeletionStatus,
        adminNotes: String? = nil,
        processedBy: String
    ) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        var updateData: [String: Any] = [
            "status": status.rawValue,
            "processedBy": processedBy,
            "processedDate": FieldValue.serverTimestamp()
        ]
        
        if let adminNotes = adminNotes {
            updateData["adminNotes"] = adminNotes
        }
        
        try await firestore
            .collection("dataDeletionRequests")
            .document(requestId)
            .updateData(updateData)
        
        // If approved, process the deletion
        if status == .approved {
            try await processDataDeletion(requestId: requestId)
        }
    }
    
    // MARK: - Data Deletion Processing
    
    /// Processes an approved data deletion request
    private func processDataDeletion(requestId: String) async throws {
        guard let request = try await fetchDeletionRequest(requestId: requestId) else {
            throw DataDeletionError.requestNotFound
        }
        
        // Update status to processing
        try await firestore
            .collection("dataDeletionRequests")
            .document(requestId)
            .updateData([
                "status": DeletionStatus.processing.rawValue
            ])
        
        // Delete data based on request scope
        if request.deleteMeals {
            try await deleteUserMeals(userId: request.userId)
        }
        
        if request.deleteSymptoms {
            try await deleteUserSymptoms(userId: request.userId)
        }
        
        if request.deleteReminders {
            try await deleteUserReminders(userId: request.userId)
        }
        
        if request.deleteAnalytics {
            try await deleteUserAnalytics(userId: request.userId)
        }
        
        if request.deleteHealthData {
            try await deleteUserHealthData(userId: request.userId)
        }
        
        if request.deleteUserProfile {
            try await deleteUserProfile(userId: request.userId)
        }
        
        // Update status to completed
        try await firestore
            .collection("dataDeletionRequests")
            .document(requestId)
            .updateData([
                "status": DeletionStatus.approved.rawValue,
                "processedDate": FieldValue.serverTimestamp()
            ])
    }
    
    // MARK: - Individual Data Deletion Methods
    
    private func deleteUserMeals(userId: String) async throws {
        let mealsSnapshot = try await firestore
            .collection("meals")
            .whereField("createdBy", isEqualTo: userId)
            .getDocuments()
        
        let batch = firestore.batch()
        
        for document in mealsSnapshot.documents {
            // Delete food items subcollection
            let foodItemsSnapshot = try await document.reference
                .collection("foodItems")
                .getDocuments()
            
            for foodItem in foodItemsSnapshot.documents {
                batch.deleteDocument(foodItem.reference)
            }
            
            // Delete the meal
            batch.deleteDocument(document.reference)
        }
        
        try await batch.commit()
    }
    
    private func deleteUserSymptoms(userId: String) async throws {
        let symptomsSnapshot = try await firestore
            .collection("symptoms")
            .whereField("createdBy", isEqualTo: userId)
            .getDocuments()
        
        let batch = firestore.batch()
        
        for document in symptomsSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        try await batch.commit()
    }
    
    private func deleteUserReminders(userId: String) async throws {
        let remindersSnapshot = try await firestore
            .collection("reminders")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let batch = firestore.batch()
        
        for document in remindersSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        try await batch.commit()
    }
    
    private func deleteUserAnalytics(userId: String) async throws {
        let analyticsSnapshot = try await firestore
            .collection("analytics")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let batch = firestore.batch()
        
        for document in analyticsSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        try await batch.commit()
    }
    
    private func deleteUserHealthData(userId: String) async throws {
        // Delete user's health data from their profile
        try await firestore
            .collection("users")
            .document(userId)
            .updateData([
                "dateOfBirth": FieldValue.delete(),
                "biologicalSexRawValue": FieldValue.delete(),
                "weight": FieldValue.delete(),
                "height": FieldValue.delete()
            ])
    }
    
    private func deleteUserProfile(userId: String) async throws {
        // Delete user profile
        try await firestore
            .collection("users")
            .document(userId)
            .delete()
        
        // Delete user's Firebase Auth account
        if let currentUser = auth.currentUser, currentUser.uid == userId {
            try await currentUser.delete()
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchDeletionRequest(requestId: String) async throws -> DataDeletionRequest? {
        let document = try await firestore
            .collection("dataDeletionRequests")
            .document(requestId)
            .getDocument()
        
        guard let data = document.data() else { return nil }
        return DataDeletionRequest(from: data, id: document.documentID)
    }
}

// MARK: - Errors

enum DataDeletionError: LocalizedError {
    case requestNotFound
    case unauthorized
    case deletionFailed
    
    var errorDescription: String? {
        switch self {
        case .requestNotFound:
            return "Deletion request not found"
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .deletionFailed:
            return "Failed to delete data"
        }
    }
}
