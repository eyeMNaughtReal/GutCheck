//
//  AddMedicationViewModel.swift
//  GutCheck
//
//  Manages the add-medication form state and validation.
//

import Foundation
import SwiftUI

@MainActor
@Observable class AddMedicationViewModel: HasLoadingState {

    // MARK: - Form Fields

    var name:          String             = ""
    var dosageAmount:  String             = ""
    var dosageUnit:    String             = "mg"
    var frequency:     MedicationFrequency = .onceDaily
    var startDate:     Date               = Date.now
    var hasEndDate:    Bool               = false
    var endDate:       Date               = Date.now
    var isActive:      Bool               = true
    var notes:         String             = ""

    // MARK: - UI State

    var showingSuccessAlert = false
    var showingErrorAlert   = false

    // MARK: - Loading State (HasLoadingState)

    let loadingState = LoadingStateManager()

    // MARK: - Dependencies

    private let medicationRepository: MedicationRepository

    init(medicationRepository: MedicationRepository = MedicationRepository.shared) {
        self.medicationRepository = medicationRepository
    }

    // MARK: - Validation

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Save

    func saveMedication() {
        guard isFormValid else {
            loadingState.setError("Please enter a medication name.")
            showingErrorAlert = true
            return
        }

        guard let userId = AuthenticationManager.shared.currentUserId else {
            loadingState.setError("You must be signed in to save medications.")
            showingErrorAlert = true
            return
        }

        loadingState.startSaving()

        let amount  = Double(dosageAmount) ?? 0.0
        let dosage  = MedicationDosage(amount: amount, unit: dosageUnit, frequency: frequency)
        let medication = MedicationRecord(
            createdBy:    userId,
            name:         name.trimmingCharacters(in: .whitespacesAndNewlines),
            dosage:       dosage,
            startDate:    startDate,
            endDate:      hasEndDate ? endDate : nil,
            isActive:     isActive,
            notes:        notes.isEmpty ? nil : notes,
            source:       .manual,
            privacyLevel: .private
        )

        Task {
            do {
                try await medicationRepository.save(medication)
                await MainActor.run {
                    self.loadingState.stopSaving()
                    self.showingSuccessAlert = true
                    DataSyncManager.shared.triggerRefreshAfterSave(
                        operation: "Medication save",
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
        name         = ""
        dosageAmount = ""
        dosageUnit   = "mg"
        frequency    = .onceDaily
        startDate    = Date.now
        hasEndDate   = false
        endDate      = Date.now
        isActive     = true
        notes        = ""
        loadingState.reset()
    }
}
