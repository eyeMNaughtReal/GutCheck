//
//  LogSymptomViewModel.swift
//  GutCheck
//
//  Created by Mark Conley on 7/14/25.
//

import Foundation
import UserNotifications

@MainActor
@Observable class LogSymptomViewModel: HasLoadingState {
    // Form state (unchanged)
    var symptomDate = Date.now
    var selectedStoolType: StoolType?
    var selectedPainLevel: Int = 0
    var selectedUrgencyLevel: UrgencyLevel = .none
    var selectedTags: Set<String> = []
    var customTag: String = ""
    var notes: String = ""
    
    // UI state (unchanged)
    var showingSuccessAlert = false
    var showingErrorAlert = false
    
    let loadingState = LoadingStateManager()
    
    // Available predefined tags (unchanged)
    let availableTags = [
        "Bloating", "Cramping", "Gas", "Nausea", "Fatigue",
        "Stress", "After eating", "Morning", "Evening",
        "Exercise related", "Travel", "Medication"
    ]
    
    // Repository dependency
    private let symptomRepository: any SymptomRepositoryProtocol
    
    init(symptomRepository: any SymptomRepositoryProtocol = SymptomRepository.shared) {
        self.symptomRepository = symptomRepository
    }

    // MARK: - Pain Level Mapping

    /// Maps the pain picker's selected index onto `PainLevel`.
    ///
    /// The picker offers five levels (None, Mild, Moderate, Severe, Extreme)
    /// against `PainLevel`'s four cases, so Extreme is recorded as severe — the
    /// strongest value the model can represent.
    ///
    /// This used to bucket the index on a 0-10 scale (1...3 → mild,
    /// 4...6 → moderate, 7+ → severe). The picker only ever produces 0...4, so
    /// choosing "Severe" was stored as `.mild` and `.severe` was unreachable:
    /// severe pain was recorded as mild, and the dashboard's high-pain alert
    /// could never fire.
    static func painLevel(forPickerIndex index: Int) -> PainLevel {
        switch index {
        case 0: .none
        case 1: .mild
        case 2: .moderate
        default: .severe
        }
    }

    // Computed properties (unchanged)
    var isFormValid: Bool {
        selectedStoolType != nil
    }
    
    var hasChanges: Bool {
        selectedStoolType != nil ||
        selectedPainLevel > 0 ||
        selectedUrgencyLevel != .none ||
        !selectedTags.isEmpty ||
        !notes.isEmpty ||
        !Calendar.current.isDate(symptomDate, inSameDayAs: Date.now)
    }
    
    // MARK: - Tag Management (unchanged)
    
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    func addCustomTag() {
        let trimmedTag = customTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty else { return }
        
        selectedTags.insert(trimmedTag)
        customTag = ""
    }
    
    func removeTag(_ tag: String) {
        selectedTags.remove(tag)
    }
    
    // MARK: - Save Symptom (Refactored)
    
    func saveSymptom() {
        guard isFormValid else {
            loadingState.setError("Please select a stool type before saving.")
            showingErrorAlert = true
            return
        }
        
        let userId = LocalUserService.currentProfileId
        
        guard let stoolType = selectedStoolType else {
            loadingState.setError("Please select a stool type.")
            showingErrorAlert = true
            return
        }
        
        loadingState.startSaving()
        loadingState.clearError()
        
        let painLevel = Self.painLevel(forPickerIndex: selectedPainLevel)

        let symptom = Symptom(
            date: symptomDate,
            stoolType: stoolType,
            painLevel: painLevel,
            urgencyLevel: selectedUrgencyLevel,
            notes: notes.isEmpty ? nil : notes,
            tags: Array(selectedTags),
            createdBy: userId
        )
        
        
        Task {
            do {
                // Persist via the repository
                #if DEBUG
                #endif
                try await symptomRepository.save(symptom)

                // Index in Spotlight for search
                SpotlightIndexingService.shared.indexSymptom(symptom)

                // Write to HealthKit
                await self.writeToHealthKit(symptom)
                
                await MainActor.run {
                    self.loadingState.stopSaving()
                    self.showingSuccessAlert = true
                    
                    // Trigger dashboard refresh after successful save
                    DataSyncManager.shared.triggerRefreshAfterSave(operation: "Symptom save", dataType: .symptoms)
                }
            } catch {
                await MainActor.run {
                    self.loadingState.setError(error.localizedDescription)
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - HealthKit Integration
    private func writeToHealthKit(_ symptom: Symptom) async {
        guard UserDefaults.standard.bool(forKey: "healthKitWriteSymptoms") else { return }
        try? await HealthKitManager.shared.writeSymptomToHealthKit(symptom)
    }
    
    // Other methods remain unchanged
    func remindMeLater() {
        let permissionManager = PermissionManager.shared
        
        // Check permission through centralized system
        guard permissionManager.notificationStatus.isGranted else {
            return
        }
        
        let interval = UserDefaults.standard.object(forKey: "remindMeLaterInterval") as? Int ?? 15
        
        let content = UNMutableNotificationContent()
        content.title = "Symptom Reminder"
        content.body = "Don't forget to log your symptoms!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(interval * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "symptomReminder_\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func resetForm() {
        symptomDate = Date.now
        selectedStoolType = nil
        selectedPainLevel = 0
        selectedUrgencyLevel = .none
        selectedTags.removeAll()
        customTag = ""
        notes = ""
    }
}
