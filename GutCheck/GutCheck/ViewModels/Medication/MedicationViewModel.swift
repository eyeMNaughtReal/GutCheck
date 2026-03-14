//
//  MedicationViewModel.swift
//  GutCheck
//
//  Manages medication list state, CRUD operations.
//

import Foundation
import SwiftUI

// MARK: - Medication List ViewModel

@MainActor
@Observable class MedicationViewModel: HasLoadingState {

    // MARK: - Published: List State

    var activeMedications: [MedicationRecord] = []
    var allMedications: [MedicationRecord] = []

    // MARK: - Published: UI State

    var showingAddMedication = false
    var showingErrorAlert    = false
    var showingDeleteConfirmation = false
    var medicationToDelete: MedicationRecord?

    // MARK: - Loading State (HasLoadingState)

    let loadingState = LoadingStateManager()

    // MARK: - Dependencies

    private let medicationRepository: MedicationRepository

    init(medicationRepository: MedicationRepository = MedicationRepository.shared) {
        self.medicationRepository = medicationRepository
    }

    // MARK: - Load

    func loadMedications() async {
        guard let userId = AuthenticationManager.shared.currentUserId else { return }

        loadingState.startLoading()
        do {
            async let active = medicationRepository.fetchActiveMedications(userId: userId)
            async let all    = medicationRepository.fetchAllMedications(userId: userId)
            activeMedications = try await active
            allMedications    = try await all
            loadingState.stopLoading()
        } catch {
            loadingState.setError(error.localizedDescription)
            showingErrorAlert = true
        }
    }

    // MARK: - Delete

    func confirmDelete(_ medication: MedicationRecord) {
        medicationToDelete       = medication
        showingDeleteConfirmation = true
    }

    func deleteMedication(_ medication: MedicationRecord) async {
        loadingState.startSaving()
        do {
            try await medicationRepository.delete(id: medication.id)
            activeMedications.removeAll { $0.id == medication.id }
            allMedications.removeAll    { $0.id == medication.id }
            loadingState.stopSaving()
            DataSyncManager.shared.triggerRefreshAfterSave(
                operation: "Medication delete",
                dataType: .dashboard
            )
        } catch {
            loadingState.setError(error.localizedDescription)
            showingErrorAlert = true
        }
    }

    // MARK: - Convenience

    var inactiveMedications: [MedicationRecord] {
        allMedications.filter { !$0.isActive }
    }
}
