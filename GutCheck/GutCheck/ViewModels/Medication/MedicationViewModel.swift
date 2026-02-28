//
//  MedicationViewModel.swift
//  GutCheck
//
//  Manages medication list state, CRUD operations, and add-medication form.
//

import Foundation
import SwiftUI

// MARK: - Medication List ViewModel

@MainActor
class MedicationViewModel: ObservableObject, HasLoadingState {

    // MARK: - Published: List State

    @Published var activeMedications: [MedicationRecord] = []
    @Published var allMedications: [MedicationRecord] = []

    // MARK: - Published: UI State

    @Published var showingAddMedication = false
    @Published var showingErrorAlert    = false
    @Published var showingDeleteConfirmation = false
    @Published var medicationToDelete: MedicationRecord?

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
class AddMedicationViewModel: ObservableObject, HasLoadingState {

    // MARK: - Form Fields

    @Published var name:          String             = ""
    @Published var dosageAmount:  String             = ""
    @Published var dosageUnit:    String             = "mg"
    @Published var frequency:     MedicationFrequency = .onceDaily
    @Published var startDate:     Date               = Date()
    @Published var hasEndDate:    Bool               = false
    @Published var endDate:       Date               = Date()
    @Published var isActive:      Bool               = true
    @Published var notes:         String             = ""

    // MARK: - UI State

    @Published var showingSuccessAlert = false
    @Published var showingErrorAlert   = false

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
        startDate    = Date()
        hasEndDate   = false
        endDate      = Date()
        isActive     = true
        notes        = ""
        loadingState.reset()
    }
}
