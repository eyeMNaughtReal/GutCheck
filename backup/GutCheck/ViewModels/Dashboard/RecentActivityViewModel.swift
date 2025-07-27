import SwiftUI
import FirebaseFirestore

@MainActor
class RecentActivityViewModel: ObservableObject {
    @Published var recentEntries: [ActivityEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Repository dependencies
    private let mealRepository: MealRepository
    private let symptomRepository: SymptomRepository
    private let maxEntries = 5
    
    init(mealRepository: MealRepository = MealRepository.shared,
         symptomRepository: SymptomRepository = SymptomRepository.shared) {
        self.mealRepository = mealRepository
        self.symptomRepository = symptomRepository
    }
    
    func loadRecentActivity(for date: Date, authService: AuthService) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let entries = try await fetchActivityEntries(for: date, authService: authService)
                await MainActor.run {
                    self.recentEntries = entries
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading recent activity: \(error)")
                }
            }
        }
    }
    
    // MARK: - Fetch Activity Entries
    
    private func fetchActivityEntries(for date: Date, authService: AuthService) async throws -> [ActivityEntry] {
        guard let currentUser = authService.currentUser else {
            throw RepositoryError.noAuthenticatedUser
        }
        
        var entries: [ActivityEntry] = []
        
        // Fetch meals using repository
        let meals = try await mealRepository.fetchMealsForDate(date, userId: currentUser.id)
        for meal in meals {
            entries.append(ActivityEntry(type: .meal(meal), timestamp: meal.date))
        }
        
        // Fetch symptoms using repository
        let symptoms = try await symptomRepository.fetchSymptomsForDate(date, userId: currentUser.id)
        for symptom in symptoms {
            entries.append(ActivityEntry(type: .symptom(symptom), timestamp: symptom.date))
        }
        
        // Sort by timestamp (most recent first) and limit
        return entries
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(maxEntries)
            .map { $0 }
    }
}
