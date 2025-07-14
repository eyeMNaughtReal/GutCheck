//
//  SymptomLoggingCoordinator.swift
//  GutCheck
//
//  Created by Mark Conley on 7/14/25.
//


//
//  SymptomLoggingCoordinator.swift
//  GutCheck
//
//  Coordinating ViewModel that manages all symptom logging components
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

@MainActor
class SymptomLoggingCoordinator: ObservableObject {
    // Child ViewModels
    @Published var bristolScaleVM = BristolScaleViewModel()
    @Published var painLevelVM = PainLevelViewModel()
    @Published var urgencyLevelVM = UrgencyLevelViewModel()
    @Published var tagSelectionVM = TagSelectionViewModel()
    
    // Form state
    @Published var symptomDate = Date()
    @Published var notes: String = ""
    
    // UI state
    @Published var isSaving = false
    @Published var showingSuccessAlert = false
    @Published var showingErrorAlert = false
    @Published var errorMessage = ""
    
    private let firestore = Firestore.firestore()
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        bristolScaleVM.selectedStoolType != nil
    }
    
    var hasChanges: Bool {
        bristolScaleVM.selectedStoolType != nil ||
        painLevelVM.painLevel > 0 ||
        urgencyLevelVM.selectedUrgencyLevel != .none ||
        tagSelectionVM.hasSelectedTags ||
        !notes.isEmpty ||
        !Calendar.current.isDate(symptomDate, inSameDayAs: Date())
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
        
        guard let stoolType = bristolScaleVM.selectedStoolType else {
            errorMessage = "Please select a stool type."
            showingErrorAlert = true
            return
        }
        
        isSaving = true
        
        // Create symptom object
        let symptom = Symptom(
            date: symptomDate,
            stoolType: stoolType,
            painLevel: painLevelVM.painLevelEnum,
            urgencyLevel: urgencyLevelVM.selectedUrgencyLevel,
            notes: notes.isEmpty ? nil : notes,
            tags: tagSelectionVM.selectedTagsArray,
            createdBy: userId
        )
        
        Task {
            do {
                try await saveSymptomToFirestore(symptom)
                
                await MainActor.run {
                    self.isSaving = false
                    self.showingSuccessAlert = true
                    self.resetForm()
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
        notes = ""
        
        // Reset child ViewModels
        bristolScaleVM.reset()
        painLevelVM.reset()
        urgencyLevelVM.reset()
        tagSelectionVM.reset()
    }
}