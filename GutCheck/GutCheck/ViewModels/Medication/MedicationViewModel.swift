//
//  MedicationViewModel.swift
//  GutCheck
//
//  Manages medication list state, CRUD operations, add-medication form,
//  and dose logging.
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

// MARK: - Add Medication ViewModel

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

// MARK: - Log Medication Dose ViewModel

/// Handles the "Log a dose I just took" form.
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
