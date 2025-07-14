//
//  LogSymptomViewModel.swift
//  GutCheck
//
//  Created by Mark Conley on 7/14/25.
//


//
//  LogSymptomViewModel.swift
//  GutCheck
//
//  ViewModel for symptom logging with validation and Firebase integration
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

@MainActor
class LogSymptomViewModel: ObservableObject {
    // Form state
    @Published var symptomDate = Date()
    @Published var selectedStoolType: StoolType?
    @Published var selectedPainLevel: Int = 0
    @Published var selectedUrgencyLevel: UrgencyLevel = .none
    @Published var selectedTags: Set<String> = []
    @Published var customTag: String = ""
    @Published var notes: String = ""
    
    // UI state
    @Published var isSaving = false
    @Published var showingSuccessAlert = false
    @Published var showingErrorAlert = false
    @Published var errorMessage = ""
    
    // Available predefined tags
    let availableTags = [
        "Bloating", "Cramping", "Gas", "Nausea", "Fatigue",
        "Stress", "After eating", "Morning", "Evening",
        "Exercise related", "Travel", "Medication"
    ]
    
    private let firestore = Firestore.firestore()
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        selectedStoolType != nil
    }
    
    var hasChanges: Bool {
        selectedStoolType != nil ||
        selectedPainLevel > 0 ||
        selectedUrgencyLevel != .none ||
        !selectedTags.isEmpty ||
        !notes.isEmpty ||
        !Calendar.current.isDate(symptomDate, inSameDayAs: Date())
    }
    
    // MARK: - Tag Management
    
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
    
    // MARK: - Save Symptom
    
    func saveSymptom() {
        guard isFormValid else {
            errorMessage = "Please select a stool type before saving."
            showingErrorAlert = true
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be signed in to save symptoms."
            showingErrorAlert = true
            return
        }
        
        guard let stoolType = selectedStoolType else {
            errorMessage = "Please select a stool type."
            showingErrorAlert = true
            return
        }
        
        isSaving = true
        
        // Convert pain level to PainLevel enum
        let painLevel: PainLevel
        switch selectedPainLevel {
        case 0:
            painLevel = .none
        case 1...3:
            painLevel = .mild
        case 4...6:
            painLevel = .moderate
        default:
            painLevel = .severe
        }
        
        // Create symptom object
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
                try await saveSymptomToFirestore(symptom)
                
                await MainActor.run {
                    self.isSaving = false
                    self.showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.errorMessage = "Failed to save symptom: \(error.localizedDescription)"
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    private func saveSymptomToFirestore(_ symptom: Symptom) async throws {
        let symptomData = symptom.toFirestoreData()
        try await firestore.collection("symptoms").document(symptom.id).setData(symptomData)
    }
    
    // MARK: - Remind Me Later
    
    func remindMeLater() {
        // Get the remind me later interval from user settings (defaulting to 15 minutes)
        let interval = UserDefaults.standard.object(forKey: "remindMeLaterInterval") as? Int ?? 15
        
        // Schedule a local notification
        let content = UNMutableNotificationContent()
        content.title = "Symptom Reminder"
        content.body = "Don't forget to log your symptoms!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(interval * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "symptomReminder_\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling reminder: \(error)")
            }
        }
    }
    
    // MARK: - Reset Form
    
    func resetForm() {
        symptomDate = Date()
        selectedStoolType = nil
        selectedPainLevel = 0
        selectedUrgencyLevel = .none
        selectedTags.removeAll()
        customTag = ""
        notes = ""
    }
}