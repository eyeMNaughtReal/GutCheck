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

    // MARK: - Edit Mode

    /// The record being edited, or nil when adding a new one. Held so the save
    /// can reuse its id (writing the same id updates rather than duplicates) and
    /// preserve fields the form doesn't expose, like `source` and `healthKitUUID`.
    private(set) var editingMedication: MedicationRecord?

    var isEditing: Bool { editingMedication != nil }

    /// HealthKit-sourced records are owned by Apple Health. Editing them here
    /// would be overwritten on the next sync, so the form stays read-only for
    /// them and the UI hides the edit affordance.
    var isEditable: Bool {
        editingMedication.map { $0.source != .healthKit } ?? true
    }

    // MARK: - Dependencies

    private let medicationRepository: any MedicationRepositoryProtocol

    init(medicationRepository: any MedicationRepositoryProtocol = MedicationRepository.shared) {
        self.medicationRepository = medicationRepository
    }

    /// Populates the form from an existing record so it can be edited in place.
    func load(_ medication: MedicationRecord) {
        editingMedication = medication
        name         = medication.name
        dosageAmount = medication.dosage.amount > 0 ? trimmedAmount(medication.dosage.amount) : ""
        dosageUnit   = medication.dosage.unit
        frequency    = medication.dosage.frequency
        startDate    = medication.startDate
        hasEndDate   = medication.endDate != nil
        endDate      = medication.endDate ?? Date.now
        isActive     = medication.isActive
        notes        = medication.notes ?? ""
    }

    /// "20" rather than "20.0" so the field round-trips what the user typed.
    private func trimmedAmount(_ value: Double) -> String {
        value == value.rounded()
            ? String(Int(value))
            : value.formatted(.number.precision(.fractionLength(1)))
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

        let userId = LocalUserService.currentProfileId

        loadingState.startSaving()

        let amount  = Double(dosageAmount) ?? 0.0
        let dosage  = MedicationDosage(amount: amount, unit: dosageUnit, frequency: frequency)
        let existing = editingMedication

        // Reusing the existing id makes this an update rather than a duplicate.
        // `source`, `healthKitUUID` and `createdAt` are carried over because the
        // form doesn't expose them and they'd otherwise be reset on every edit.
        let medication = MedicationRecord(
            id:            existing?.id ?? UUID().uuidString,
            createdBy:     existing?.createdBy ?? userId,
            name:          name.trimmingCharacters(in: .whitespacesAndNewlines),
            dosage:        dosage,
            startDate:     startDate,
            endDate:       hasEndDate ? endDate : nil,
            isActive:      isActive,
            notes:         notes.isEmpty ? nil : notes,
            source:        existing?.source ?? .manual,
            privacyLevel:  existing?.privacyLevel ?? .private,
            healthKitUUID: existing?.healthKitUUID,
            createdAt:     existing?.createdAt ?? Date.now,
            updatedAt:     Date.now
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
