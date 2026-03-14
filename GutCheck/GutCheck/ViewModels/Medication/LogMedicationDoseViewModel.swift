//
//  LogMedicationDoseViewModel.swift
//  GutCheck
//
//  Handles the "Log a dose I just took" form.
//

import Foundation
import SwiftUI

@MainActor
@Observable class LogMedicationDoseViewModel: HasLoadingState {

    // MARK: - Published: Medication Picker

    /// Active medications the user can select from.
    var availableMedications: [MedicationRecord] = []
    var selectedMedication: MedicationRecord?

    // MARK: - Published: Form Fields

    /// Date and time the dose was taken (defaults to now).
    var dateTaken: Date = Date.now
    var notes: String   = ""

    // MARK: - Published: UI State

    var showingSuccessAlert = false
    var showingErrorAlert   = false

    // MARK: - Loading State

    let loadingState = LoadingStateManager()

    // MARK: - Dependencies

    private let medicationRepository:     MedicationRepository
    private let medicationDoseRepository: MedicationDoseRepository

    init(
        medicationRepository:     MedicationRepository     = MedicationRepository.shared,
        medicationDoseRepository: MedicationDoseRepository = MedicationDoseRepository.shared
    ) {
        self.medicationRepository     = medicationRepository
        self.medicationDoseRepository = medicationDoseRepository
    }

    // MARK: - Load Medications

    func loadActiveMedications() async {
        guard let userId = AuthenticationManager.shared.currentUserId else { return }
        loadingState.startLoading()
        do {
            availableMedications = try await medicationRepository.fetchActiveMedications(userId: userId)
            // Pre-select the first medication if none chosen yet
            if selectedMedication == nil { selectedMedication = availableMedications.first }
            loadingState.stopLoading()
        } catch {
            loadingState.setError(error.localizedDescription)
            showingErrorAlert = true
        }
    }

    // MARK: - Validation

    var isFormValid: Bool { selectedMedication != nil }

    // MARK: - Save Dose

    func saveDose() {
        guard let medication = selectedMedication else {
            loadingState.setError("Please select a medication.")
            showingErrorAlert = true
            return
        }
        guard let userId = AuthenticationManager.shared.currentUserId else {
            loadingState.setError("You must be signed in to log a dose.")
            showingErrorAlert = true
            return
        }

        loadingState.startSaving()

        let log = MedicationDoseLog(
            createdBy:      userId,
            medicationId:   medication.id,
            medicationName: medication.name,
            dosageAmount:   medication.dosage.amount,
            dosageUnit:     medication.dosage.unit,
            dateTaken:      dateTaken,
            notes:          notes.isEmpty ? nil : notes,
            privacyLevel:   .private
        )

        Task {
            do {
                try await medicationDoseRepository.save(log)
                await MainActor.run {
                    self.loadingState.stopSaving()
                    self.showingSuccessAlert = true
                    DataSyncManager.shared.triggerRefreshAfterSave(
                        operation: "Medication dose log",
                        dataType: .dashboard
                    )
                }
            } catch {
                await MainActor.run {
                    self.loadingState.setError(error.localizedDescription)
                    self.showingErrorAlert = true
                }
            }
        }
    }

    // MARK: - Reset

    func resetForm() {
        selectedMedication = availableMedications.first
        dateTaken          = Date.now
        notes              = ""
        loadingState.reset()
    }
}
