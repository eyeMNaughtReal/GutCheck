//
//  MedicationViewModel.swift
//  GutCheck
//
//  Manages medication list state, CRUD, add-medication form, and dose logging.
//

import Foundation
import SwiftUI

// MARK: - Medication List ViewModel

@MainActor
class MedicationViewModel: ObservableObject, HasLoadingState {

    // MARK: - Published: List
    @Published var activeMedications: [MedicationRecord] = []
    @Published var allMedications:    [MedicationRecord] = []

    // MARK: - Published: UI
    @Published var showingAddMedication      = false
    @Published var showingErrorAlert         = false
    @Published var showingDeleteConfirmation = false
    @Published var medicationToDelete: MedicationRecord?

    // MARK: - HasLoadingState
    let loadingState = LoadingStateManager()

    private let repo: MedicationRepository

    init(repo: MedicationRepository = .shared) {
        self.repo = repo
    }

    // MARK: - Load

    func loadMedications() async {
        guard let userId = AuthenticationManager.shared.currentUserId else { return }
        loadingState.startLoading()
        do {
            async let active = repo.fetchActiveMedications(userId: userId)
            async let all    = repo.fetchAllMedications(userId: userId)
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
            try await repo.delete(id: medication.id)
            activeMedications.removeAll { $0.id == medication.id }
            allMedications.removeAll    { $0.id == medication.id }
            loadingState.stopSaving()
            DataSyncManager.shared.triggerRefreshAfterSave(operation: "Medication delete", dataType: .dashboard)
        } catch {
            loadingState.setError(error.localizedDescription)
            showingErrorAlert = true
        }
    }

    var inactiveMedications: [MedicationRecord] { allMedications.filter { !$0.isActive } }
}

// MARK: - Add Medication ViewModel

@MainActor
class AddMedicationViewModel: ObservableObject, HasLoadingState {

    // MARK: - Form Fields
    @Published var name:         String              = ""
    @Published var dosageAmount: String              = ""
    @Published var dosageUnit:   String              = "mg"
    @Published var frequency:    MedicationFrequency = .onceDaily
    @Published var startDate:    Date                = Date()
    @Published var hasEndDate:   Bool                = false
    @Published var endDate:      Date                = Date()
    @Published var isActive:     Bool                = true
    @Published var notes:        String              = ""

    // MARK: - UI State
    @Published var showingSuccessAlert = false
    @Published var showingErrorAlert   = false

    // MARK: - HasLoadingState
    let loadingState = LoadingStateManager()

    private let repo: MedicationRepository

    init(repo: MedicationRepository = .shared) {
        self.repo = repo
    }

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

        let medication = MedicationRecord(
            createdBy:    userId,
            name:         name.trimmingCharacters(in: .whitespacesAndNewlines),
            dosage:       MedicationDosage(amount: Double(dosageAmount) ?? 0,
                                           unit: dosageUnit,
                                           frequency: frequency),
            startDate:    startDate,
            endDate:      hasEndDate ? endDate : nil,
            isActive:     isActive,
            notes:        notes.isEmpty ? nil : notes,
            source:       .manual,
            privacyLevel: .private
        )

        Task {
            do {
                try await repo.save(medication)
                await MainActor.run {
                    self.loadingState.stopSaving()
                    self.showingSuccessAlert = true
                    DataSyncManager.shared.triggerRefreshAfterSave(operation: "Medication save", dataType: .dashboard)
                }
            } catch {
                await MainActor.run {
                    self.loadingState.setError(error.localizedDescription)
                    self.showingErrorAlert = true
                }
            }
        }
    }

    func resetForm() {
        name = ""; dosageAmount = ""; dosageUnit = "mg"
        frequency = .onceDaily; startDate = Date()
        hasEndDate = false; endDate = Date()
        isActive = true; notes = ""
        loadingState.reset()
    }
}

// MARK: - Log Dose ViewModel

@MainActor
class LogMedicationDoseViewModel: ObservableObject, HasLoadingState {

    // MARK: - Published
    @Published var availableMedications: [MedicationRecord] = []
    @Published var selectedMedication:   MedicationRecord?
    @Published var dateTaken:            Date               = Date()
    @Published var notes:                String             = ""

    @Published var showingSuccessAlert = false
    @Published var showingErrorAlert   = false

    // MARK: - HasLoadingState
    let loadingState = LoadingStateManager()

    private let medRepo:  MedicationRepository
    private let doseRepo: MedicationDoseRepository

    init(medRepo: MedicationRepository = .shared,
         doseRepo: MedicationDoseRepository = .shared) {
        self.medRepo  = medRepo
        self.doseRepo = doseRepo
    }

    var isFormValid: Bool { selectedMedication != nil }

    // MARK: - Load

    func loadActiveMedications() async {
        guard let userId = AuthenticationManager.shared.currentUserId else { return }
        loadingState.startLoading()
        do {
            availableMedications = try await medRepo.fetchActiveMedications(userId: userId)
            if selectedMedication == nil { selectedMedication = availableMedications.first }
            loadingState.stopLoading()
        } catch {
            loadingState.setError(error.localizedDescription)
            showingErrorAlert = true
        }
    }

    // MARK: - Save

    func saveDose() {
        guard let medication = selectedMedication else {
            loadingState.setError("Please select a medication.")
            showingErrorAlert = true; return
        }
        guard let userId = AuthenticationManager.shared.currentUserId else {
            loadingState.setError("You must be signed in to log a dose.")
            showingErrorAlert = true; return
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
                try await doseRepo.save(log)
                await MainActor.run {
                    self.loadingState.stopSaving()
                    self.showingSuccessAlert = true
                    DataSyncManager.shared.triggerRefreshAfterSave(operation: "Dose log", dataType: .dashboard)
                }
            } catch {
                await MainActor.run {
                    self.loadingState.setError(error.localizedDescription)
                    self.showingErrorAlert = true
                }
            }
        }
    }

    func resetForm() {
        selectedMedication = availableMedications.first
        dateTaken = Date(); notes = ""
        loadingState.reset()
    }
}
