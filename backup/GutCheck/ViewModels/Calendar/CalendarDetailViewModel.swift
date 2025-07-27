import Foundation
import FirebaseFirestore

@MainActor
class CalendarDetailViewModel: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var symptoms: [Symptom] = []
    @Published var potentialTriggers: [FoodTrigger]?
    @Published var patterns: [String]?
    
    var hasAnalysis: Bool {
        potentialTriggers != nil || patterns != nil
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
    
    private func analyzeDayData() async {
        do {
            // For now, use the existing analyzeFoodItems method
            let analysis = try await AIAnalysisService.shared.analyzeFoodItems(
                meals.flatMap { $0.foodItems }
            )
            
            // Convert AIAnalysisResult to patterns and triggers
            patterns = analysis.insights
            // For triggers, we would need a more sophisticated analysis
            potentialTriggers = []
        } catch {
            print("Error analyzing day data: \(error)")
            potentialTriggers = nil
            patterns = nil
        }
    }
}
