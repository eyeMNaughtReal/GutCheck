//
//  DataDeletionService.swift
//  GutCheck
//
//  Service for handling data deletion requests and processing
//
//  Created by Mark Conley on 8/18/25.
//
//  This used to file a request into a Firestore queue for a reviewer to
//  approve. There is no queue and no reviewer any more: the data is on this
//  device, so a request is carried out the moment it is made. The request
//  record is still written, and still kept after processing, as the user's
//  receipt of what was erased and when.
//

import Foundation

@MainActor
@Observable class DataDeletionService {
    static let shared = DataDeletionService()

    var isLoading = false
    var errorMessage: String?

    private let requestRepository = DataDeletionRequestRepository.shared

    private init() {}

    // MARK: - Data Deletion Request Management

    /// Records a deletion request and carries it out immediately.
    @discardableResult
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
            status: .processing,
            deleteUserProfile: deleteUserProfile,
            deleteMeals: deleteMeals,
            deleteSymptoms: deleteSymptoms,
            deleteHealthData: deleteHealthData,
            deleteAnalytics: deleteAnalytics,
            deleteReminders: deleteReminders
        )

        try await requestRepository.save(request)

        do {
            try await processDataDeletion(request)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }

        // Re-read so the caller gets the record with its final status.
        return try await requestRepository.fetch(id: request.id) ?? request
    }

    /// All deletion requests recorded on this device, newest first.
    func fetchAllDeletionRequests() async throws -> [DataDeletionRequest] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        return try await requestRepository.fetchAll()
    }

    /// Deletion requests recorded for a given profile.
    func fetchUserDeletionRequests(userId: String) async throws -> [DataDeletionRequest] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        return try await requestRepository.fetchAll(userId: userId)
    }

    // MARK: - Data Deletion Processing

    /// Erases the data the request covers, then marks it complete.
    private func processDataDeletion(_ request: DataDeletionRequest) async throws {
        let userId = request.userId

        if request.deleteMeals {
            try await MealRepository.shared.deleteAll(userId: userId)
        }

        if request.deleteSymptoms {
            try await SymptomRepository.shared.deleteAll(userId: userId)
        }

        if request.deleteReminders {
            if let settings = try? await ReminderSettingsRepository.shared.fetch(forUser: userId) {
                try await ReminderSettingsRepository.shared.delete(settings)
            }
        }

        // "Analytics" here means the medication history the insight engine
        // reads. Nothing is reported off-device, so there is no separate
        // analytics store to clear.
        if request.deleteAnalytics {
            try await MedicationDoseRepository.shared.deleteAll(userId: userId)
            try await MedicationRepository.shared.deleteAll(userId: userId)
        }

        if request.deleteHealthData {
            try await clearHealthFields(userId: userId)
        }

        if request.deleteUserProfile {
            // Clears the encrypted loose files as well, then starts a fresh
            // empty profile so the app still has an owner for new records.
            try await LocalUserService.shared.deleteAllLocalData()
        }

        var completed = request
        completed.status = .approved
        completed.processedDate = Date.now
        completed.processedBy = "on-device"
        try await requestRepository.save(completed)
    }

    /// Removes the HealthKit-derived fields from the local profile, leaving the
    /// profile itself in place.
    private func clearHealthFields(userId: String) async throws {
        guard var user = LocalUserService.shared.currentUser, user.id == userId else { return }
        user.dateOfBirth = nil
        user.biologicalSexRawValue = nil
        user.weight = nil
        user.height = nil
        try await LocalUserService.shared.updateUserProfile(user)
    }
}

// MARK: - Errors

enum DataDeletionError: LocalizedError {
    case requestNotFound
    case deletionFailed

    var errorDescription: String? {
        switch self {
        case .requestNotFound:
            return "Deletion request not found"
        case .deletionFailed:
            return "Failed to delete data"
        }
    }
}
