import Foundation
import FirebaseFirestore

@MainActor
class CalendarDetailViewModel: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var symptoms: [Symptom] = []
    @Published var patterns: [String]?
    @Published var potentialTriggers: [String]?
    
    var hasAnalysis: Bool {
        (patterns != nil && !patterns!.isEmpty) || (potentialTriggers != nil && !potentialTriggers!.isEmpty)
    }
    
    var isEmpty: Bool {
        meals.isEmpty && symptoms.isEmpty && !hasAnalysis
    }
    
    func loadData(for date: Date, authService: AuthService) async {
        do {
            // Load meals for the day using MealRepository
            meals = try await MealRepository.shared.fetchMealsForDate(
                date, 
                userId: authService.currentUser?.id ?? ""
            )
            
            // Load symptoms for the day using SymptomRepository
            symptoms = try await SymptomRepository.shared.fetchSymptomsForDate(
                date,
                userId: authService.currentUser?.id ?? ""
            )
            
            // Analyze the data for the day
            await analyzeDayData()
        } catch {
            print("Error loading calendar data: \(error)")
            meals = []
            symptoms = []
        }
    }
    
    func deleteSymptom(_ symptom: Symptom) async {
        do {
            try await SymptomRepository.shared.delete(id: symptom.id)
            // Remove from local array
            symptoms.removeAll { $0.id == symptom.id }
        } catch {
            print("Error deleting symptom: \(error)")
        }
    }
    
    func updateSymptom(_ updatedSymptom: Symptom) async {
        do {
            try await SymptomRepository.shared.save(updatedSymptom)
            // Update in local array
            if let index = symptoms.firstIndex(where: { $0.id == updatedSymptom.id }) {
                symptoms[index] = updatedSymptom
            }
        } catch {
            print("Error updating symptom: \(error)")
        }
    }
    
    private func analyzeDayData() async {
        do {
            // For now, use the existing analyzeFoodItems method
            let analysis = try await AIAnalysisService.shared.analyzeFoodItems(
                meals.flatMap { $0.foodItems }
            )
            
                        // Convert AIAnalysisResult to patterns and triggers
            patterns = analysis.insights
            potentialTriggers = analysis.recommendations
        } catch {
            print("Error analyzing day data: \(error)")
            patterns = nil
        }
    }
}
