import Foundation

@MainActor
@Observable class SymptomExplorerViewModel {

    // MARK: - Published State

    var recentSymptoms: [Symptom] = []
    var selectedSymptom: Symptom? = nil
    var suspectedMeals: [SuspectedMeal] = []
    var isLoading = false
    var isLoadingMeals = false
    var error: String?

    // MARK: - Dependencies

    private let mealRepository: any MealRepositoryProtocol
    private let symptomRepository: any SymptomRepositoryProtocol
    private let authService = AuthService()
    private let compoundDatabase = FoodCompoundDatabase.shared
    
    init(mealRepository: any MealRepositoryProtocol = MealRepository.shared,
         symptomRepository: any SymptomRepositoryProtocol = SymptomRepository.shared) {
        self.mealRepository = mealRepository
        self.symptomRepository = symptomRepository
    }

    // Cached data for quick re-computation on symptom change
    private var triggerPatterns: [TriggerPattern] = []
    private var allMeals: [Meal] = []

    // MARK: - Load Data

    func loadData() async {
        isLoading = true
        error = nil

        do {
            let userId = getCurrentUserId()
            let endDate = Date.now
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate

            async let symptomsTask = symptomRepository.fetchSymptomsForDateRange(
                startDate: startDate, endDate: endDate, userId: userId
            )
            async let mealsTask = mealRepository.fetchMealsForDateRange(
                startDate: startDate, endDate: endDate, userId: userId
            )

            let symptoms = try await symptomsTask
            let meals = try await mealsTask

            recentSymptoms = symptoms
                .filter { hasSignificantSymptoms($0) }
                .sorted { $0.date > $1.date }

            allMeals = meals

            triggerPatterns = await PatternRecognitionService.shared
                .analyzeTriggerPatterns(meals: meals, symptoms: symptoms)

            // Auto-select the most recent symptom
            if let first = recentSymptoms.first {
                selectSymptom(first)
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Symptom Selection

    func selectSymptom(_ symptom: Symptom) {
        selectedSymptom = symptom
        computeSuspectedMeals(for: symptom)
    }

    // MARK: - Core Computation

    private func computeSuspectedMeals(for symptom: Symptom) {
        isLoadingMeals = true

        let windowStart = symptom.date.addingTimeInterval(-24 * 3600) // 24hrs before
        let windowEnd = symptom.date.addingTimeInterval(-6 * 3600)    // 6hrs before

        let precedingMeals = allMeals.filter { $0.date >= windowStart && $0.date <= windowEnd }

        // Build lookup of known trigger foods by name
        let knownTriggerFoods: [String: TriggerPattern] = Dictionary(
            triggerPatterns.map { ($0.foodName.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        var results: [SuspectedMeal] = []

        for meal in precedingMeals {
            let timeBefore = symptom.date.timeIntervalSince(meal.date) / 3600.0
            var mealScore: Double = 0
            var suspectedFoods: [SuspectedFood] = []

            for item in meal.foodItems {
                let foodKey = item.name.lowercased().trimmingCharacters(in: .whitespaces)
                var foodScore: Double = 0
                var reasons: [String] = []
                var compoundRisks: [String] = []

                // 1) Known trigger pattern match (40% weight)
                if let pattern = knownTriggerFoods[foodKey] {
                    foodScore += Double(pattern.triggerScore.overall) / 100.0 * 0.40
                    reasons.append("Known trigger (score: \(pattern.triggerScore.overall))")
                }

                // 2) Compound risk from FoodCompoundDatabase (30% weight)
                let compounds = compoundDatabase.getCompoundsForFood(
                    name: item.name, ingredients: item.ingredients
                )
                let highRisk = compounds.filter { $0.severity == .high }
                let medRisk = compounds.filter { $0.severity == .medium }
                let compoundScore = min(1.0, Double(highRisk.count) * 0.3 + Double(medRisk.count) * 0.15)
                foodScore += compoundScore * 0.30
                compoundRisks = (highRisk + medRisk).map { $0.name }
                if !highRisk.isEmpty {
                    reasons.append("\(highRisk.count) high-risk compound(s)")
                }
                if !medRisk.isEmpty {
                    reasons.append("\(medRisk.count) medium-risk compound(s)")
                }

                // 3) Time proximity (30% weight) — closer to 6hr = higher
                let proximityScore = 1.0 - ((timeBefore - 6.0) / 18.0)
                foodScore += max(0, min(1.0, proximityScore)) * 0.30

                let finalScore = Int(min(100, max(0, foodScore * 100)))

                if finalScore > 10 || !compoundRisks.isEmpty {
                    suspectedFoods.append(SuspectedFood(
                        id: UUID(),
                        foodItem: item,
                        triggerScore: finalScore,
                        compoundRisks: compoundRisks,
                        reason: reasons.isEmpty ? "Time proximity" : reasons.joined(separator: "; ")
                    ))
                }

                mealScore = max(mealScore, foodScore)
            }

            suspectedFoods.sort { $0.triggerScore > $1.triggerScore }

            results.append(SuspectedMeal(
                id: UUID(),
                meal: meal,
                timeBefore: timeBefore,
                triggerLikelihood: Int(min(100, max(0, mealScore * 100))),
                suspectedFoods: suspectedFoods
            ))
        }

        suspectedMeals = results.sorted { $0.triggerLikelihood > $1.triggerLikelihood }
        isLoadingMeals = false
    }

    // MARK: - Helpers

    private func getCurrentUserId() -> String {
        authService.currentUser?.id ?? "default_user"
    }

    private func hasSignificantSymptoms(_ symptom: Symptom) -> Bool {
        symptom.painLevel != .none
            || symptom.urgencyLevel != .none
            || symptom.stoolType == .type1 || symptom.stoolType == .type2
            || symptom.stoolType == .type6 || symptom.stoolType == .type7
    }

    /// Format a symptom for display in the picker
    func symptomLabel(for symptom: Symptom) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        var parts = [formatter.string(from: symptom.date)]

        switch symptom.painLevel {
        case .mild: parts.append("Mild Pain")
        case .moderate: parts.append("Moderate Pain")
        case .severe: parts.append("Severe Pain")
        case .none: break
        }

        switch symptom.urgencyLevel {
        case .mild: parts.append("Mild Urgency")
        case .moderate: parts.append("Moderate Urgency")
        case .urgent: parts.append("Urgent")
        case .none: break
        }

        return parts.joined(separator: " · ")
    }
}
