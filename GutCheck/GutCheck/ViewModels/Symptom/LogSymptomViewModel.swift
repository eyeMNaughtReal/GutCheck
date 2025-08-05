//
//  LogSymptomViewModel.swift
//  GutCheck
//
//  Created by Mark Conley on 7/14/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

@MainActor
class LogSymptomViewModel: ObservableObject {
    // Form state (unchanged)
    @Published var symptomDate = Date()
    @Published var selectedStoolType: StoolType?
    @Published var selectedPainLevel: Int = 0
    @Published var selectedUrgencyLevel: UrgencyLevel = .none
    @Published var selectedTags: Set<String> = []
    @Published var customTag: String = ""
    @Published var notes: String = ""
    
    // UI state (unchanged)
    @Published var isSaving = false
    @Published var showingSuccessAlert = false
    @Published var showingErrorAlert = false
    @Published var errorMessage = ""
    
    // Available predefined tags (unchanged)
    let availableTags = [
        "Bloating", "Cramping", "Gas", "Nausea", "Fatigue",
        "Stress", "After eating", "Morning", "Evening",
        "Exercise related", "Travel", "Medication"
    ]
    
    // Repository dependency
    private let symptomRepository: SymptomRepository
    
    init(symptomRepository: SymptomRepository = SymptomRepository.shared) {
        self.symptomRepository = symptomRepository
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
        !Calendar.current.isDate(symptomDate, inSameDayAs: Date())
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
            errorMessage = "Please select a stool type before saving."
            showingErrorAlert = true
            return
        }
        
        guard let userId = AuthenticationManager.shared.currentUserId else {
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
        errorMessage = ""
        
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
        
        let symptom = Symptom(
            date: symptomDate,
            stoolType: stoolType,
            painLevel: painLevel,
            urgencyLevel: selectedUrgencyLevel,
            notes: notes.isEmpty ? nil : notes,
            tags: Array(selectedTags),
            createdBy: userId
        )
        
        print("🕐 LogSymptom: Symptom date: \(symptomDate)")
        print("📝 LogSymptom: Current date: \(Date())")
        print("🗓️ LogSymptom: Same day check: \(Calendar.current.isDate(symptomDate, inSameDayAs: Date()))")
        
        Task {
            do {
                // Use repository instead of direct Firestore calls
                print("💾 LogSymptom: Saving symptom with ID: \(symptom.id), date: \(symptom.date), user: \(symptom.createdBy)")
                try await symptomRepository.save(symptom)
                print("✅ LogSymptom: Successfully saved symptom to Firebase")
                
                // Write to HealthKit
                await self.writeToHealthKit(symptom)
                
                await MainActor.run {
                    self.isSaving = false
                    self.showingSuccessAlert = true
                    
                    // Trigger dashboard refresh after successful save
                    NavigationCoordinator.shared.refreshDashboard()
                }
            } catch {
                print("❌ LogSymptom: Error saving symptom: \(error)")
                await MainActor.run {
                    self.isSaving = false
                    self.errorMessage = error.localizedDescription
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - HealthKit Integration
    private func writeToHealthKit(_ symptom: Symptom) async {
        await withCheckedContinuation { continuation in
            HealthKitManager.shared.writeSymptomToHealthKit(symptom) { success, error in
                if success {
                    print("✅ LogSymptomViewModel: Successfully wrote symptom to HealthKit")
                } else if let error = error {
                    print("⚠️ LogSymptomViewModel: HealthKit write failed: \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }
    
    // Other methods remain unchanged
    func remindMeLater() {
        let interval = UserDefaults.standard.object(forKey: "remindMeLaterInterval") as? Int ?? 15
        
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
