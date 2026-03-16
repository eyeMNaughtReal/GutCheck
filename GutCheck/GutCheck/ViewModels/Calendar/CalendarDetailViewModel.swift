import Foundation
import FirebaseFirestore

@MainActor
@Observable class CalendarDetailViewModel {
    var meals: [Meal] = []
    var symptoms: [Symptom] = []
    var patterns: [String]?
    var potentialTriggers: [String]?
    
    private let mealRepository: any MealRepositoryProtocol
    private let symptomRepository: any SymptomRepositoryProtocol
    
    init(mealRepository: any MealRepositoryProtocol = MealRepository.shared,
         symptomRepository: any SymptomRepositoryProtocol = SymptomRepository.shared) {
        self.mealRepository = mealRepository
        self.symptomRepository = symptomRepository
    }
    
    var hasAnalysis: Bool {
        (patterns != nil && !patterns!.isEmpty) || (potentialTriggers != nil && !potentialTriggers!.isEmpty)
    }
    
    var isEmpty: Bool {
        meals.isEmpty && symptoms.isEmpty && !hasAnalysis
    }
    
    func loadData(for date: Date, authService: AuthService) async {
        do {
            // Load meals for the day using MealRepository
            meals = try await mealRepository.fetchMealsForDate(
                date, 
                userId: authService.currentUser?.id ?? ""
            )
            
            // Load symptoms for the day using SymptomRepository
            symptoms = try await symptomRepository.fetchSymptomsForDate(
                date,
                userId: authService.currentUser?.id ?? ""
            )
            
            // Analyze the data for the day
            await analyzeDayData()
        } catch {
            meals = []
            symptoms = []
        }
    }
    
    func deleteSymptom(_ symptom: Symptom) async {
        do {
            try await symptomRepository.delete(id: symptom.id)
            // Remove from local array
            symptoms.removeAll { $0.id == symptom.id }
        } catch {
        }
    }
    
    func updateSymptom(_ updatedSymptom: Symptom) async {
        do {
            try await symptomRepository.save(updatedSymptom)
            // Update in local array
            if let index = symptoms.firstIndex(where: { $0.id == updatedSymptom.id }) {
                symptoms[index] = updatedSymptom
            }
        } catch {
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
            patterns = nil
        }
    }
}
