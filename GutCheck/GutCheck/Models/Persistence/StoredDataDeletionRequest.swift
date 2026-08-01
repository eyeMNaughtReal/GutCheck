//
//  StoredDataDeletionRequest.swift
//  GutCheck
//
//  SwiftData entity backing the `DataDeletionRequest` domain struct.
//
//  With no backend there is no queue for a reviewer to work through: a request
//  is now a local record of what the user asked to erase and when it was
//  carried out, kept as an audit trail alongside the deletion itself.
//

import Foundation
import SwiftData

@Model
final class StoredDataDeletionRequest {
    @Attribute(.unique) var id: String

    var userId: String
    var userEmail: String
    var userName: String
    var requestDate: Date
    var reason: String?
    var statusRawValue: String
    var adminNotes: String?
    var processedDate: Date?
    var processedBy: String?

    var deleteUserProfile: Bool
    var deleteMeals: Bool
    var deleteSymptoms: Bool
    var deleteHealthData: Bool
    var deleteAnalytics: Bool
    var deleteReminders: Bool

    init(
        id: String,
        userId: String,
        userEmail: String,
        userName: String,
        requestDate: Date,
        reason: String?,
        statusRawValue: String,
        adminNotes: String?,
        processedDate: Date?,
        processedBy: String?,
        deleteUserProfile: Bool,
        deleteMeals: Bool,
        deleteSymptoms: Bool,
        deleteHealthData: Bool,
        deleteAnalytics: Bool,
        deleteReminders: Bool
    ) {
        self.id = id
        self.userId = userId
        self.userEmail = userEmail
        self.userName = userName
        self.requestDate = requestDate
        self.reason = reason
        self.statusRawValue = statusRawValue
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

// MARK: - Domain mapping

extension StoredDataDeletionRequest {
    convenience init(_ request: DataDeletionRequest) {
        self.init(
            id: request.id,
            userId: request.userId,
            userEmail: request.userEmail,
            userName: request.userName,
            requestDate: request.requestDate,
            reason: request.reason,
            statusRawValue: request.status.rawValue,
            adminNotes: request.adminNotes,
            processedDate: request.processedDate,
            processedBy: request.processedBy,
            deleteUserProfile: request.deleteUserProfile,
            deleteMeals: request.deleteMeals,
            deleteSymptoms: request.deleteSymptoms,
            deleteHealthData: request.deleteHealthData,
            deleteAnalytics: request.deleteAnalytics,
            deleteReminders: request.deleteReminders
        )
    }

    func apply(_ request: DataDeletionRequest) {
        userId = request.userId
        userEmail = request.userEmail
        userName = request.userName
        requestDate = request.requestDate
        reason = request.reason
        statusRawValue = request.status.rawValue
        adminNotes = request.adminNotes
        processedDate = request.processedDate
        processedBy = request.processedBy
        deleteUserProfile = request.deleteUserProfile
        deleteMeals = request.deleteMeals
        deleteSymptoms = request.deleteSymptoms
        deleteHealthData = request.deleteHealthData
        deleteAnalytics = request.deleteAnalytics
        deleteReminders = request.deleteReminders
    }

    var domainModel: DataDeletionRequest {
        DataDeletionRequest(
            id: id,
            userId: userId,
            userEmail: userEmail,
            userName: userName,
            requestDate: requestDate,
            reason: reason,
            status: DeletionStatus(rawValue: statusRawValue) ?? .pending,
            adminNotes: adminNotes,
            processedDate: processedDate,
            processedBy: processedBy,
            deleteUserProfile: deleteUserProfile,
            deleteMeals: deleteMeals,
            deleteSymptoms: deleteSymptoms,
            deleteHealthData: deleteHealthData,
            deleteAnalytics: deleteAnalytics,
            deleteReminders: deleteReminders
        )
    }
}
