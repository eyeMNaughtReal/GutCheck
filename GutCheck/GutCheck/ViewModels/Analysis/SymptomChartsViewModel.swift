import Foundation

@MainActor
@Observable class SymptomChartsViewModel {

    // MARK: - Published State

    var timelineData: [TimelineDataPoint] = []
    var severityData: [SeverityLineDataPoint] = []
    var weeklyData: [WeeklyBarDataPoint] = []
    var ingredientData: [IngredientSliceDataPoint] = []

    var selectedTimeRange: ChartTimeRange = .last30Days
    var selectedFilter: SymptomChartFilter = .all
    var selectedTab: ChartTab = .timeline

    var isLoading = false
    var error: String?

    // MARK: - Dependencies

    private let mealRepository: any MealRepositoryProtocol
    private let symptomRepository: any SymptomRepositoryProtocol
    private let userService = LocalUserService.shared
    
    init(mealRepository: any MealRepositoryProtocol = MealRepository.shared,
         symptomRepository: any SymptomRepositoryProtocol = SymptomRepository.shared) {
        self.mealRepository = mealRepository
        self.symptomRepository = symptomRepository
    }

    // Cached raw data for re-filtering without re-fetching
    private var allSymptoms: [Symptom] = []
    private var allMeals: [Meal] = []

    // MARK: - Load Data

    func loadData() async {
        isLoading = true
        error = nil

        do {
            let userId = userService.currentUser?.id ?? "default_user"
            let endDate = Date.now
            let startDate = Calendar.current.date(
                byAdding: .day, value: -selectedTimeRange.days, to: endDate
            ) ?? endDate

            async let symptomsTask = symptomRepository.fetchSymptomsForDateRange(
                startDate: startDate, endDate: endDate, userId: userId
            )
            async let mealsTask = mealRepository.fetchMealsForDateRange(
                startDate: startDate, endDate: endDate, userId: userId
            )

            allSymptoms = try await symptomsTask
            allMeals = try await mealsTask

            recomputeChartData()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Recompute on Filter Change

    func recomputeChartData() {
        let filtered = filterSymptoms(allSymptoms)
        computeTimelineData(from: filtered)
        computeSeverityData(from: filtered)
        computeWeeklyData(from: filtered)
        computeIngredientData(from: allMeals)
    }

    // MARK: - Filter

    private func filterSymptoms(_ symptoms: [Symptom]) -> [Symptom] {
        switch selectedFilter {
        case .all:
            return symptoms
        case .pain:
            return symptoms.filter { $0.painLevel != .none }
        case .urgency:
            return symptoms.filter { $0.urgencyLevel != .none }
        case .stool:
            return symptoms.filter {
                $0.stoolType == .type1 || $0.stoolType == .type2
                    || $0.stoolType == .type6 || $0.stoolType == .type7
            }
        }
    }

    // MARK: - Timeline Computation

    private func computeTimelineData(from symptoms: [Symptom]) {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: symptoms) { symptom in
            calendar.startOfDay(for: symptom.date)
        }

        timelineData = grouped.map { (day, daySymptoms) in
            let maxSeverity = daySymptoms.map { maxSeverityLevel($0) }.max() ?? 0
            return TimelineDataPoint(
                date: day,
                severityLevel: maxSeverity,
                symptomCount: daySymptoms.count,
                label: severityLabel(maxSeverity)
            )
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: - Severity Line Computation

    private func computeSeverityData(from symptoms: [Symptom]) {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: symptoms) { symptom in
            calendar.startOfDay(for: symptom.date)
        }

        var points: [SeverityLineDataPoint] = []

        for (day, daySymptoms) in grouped {
            let maxPain = daySymptoms.map { $0.painLevel.rawValue }.max() ?? 0
            let maxUrgency = daySymptoms.map { $0.urgencyLevel.rawValue }.max() ?? 0

            points.append(SeverityLineDataPoint(
                date: day, value: maxPain, series: "Pain"
            ))
            points.append(SeverityLineDataPoint(
                date: day, value: maxUrgency, series: "Urgency"
            ))
        }

        severityData = points.sorted { $0.date < $1.date }
    }

    // MARK: - Weekly Bar Computation

    private func computeWeeklyData(from symptoms: [Symptom]) {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let grouped = Dictionary(grouping: symptoms) { symptom -> Date in
            let components = calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: symptom.date
            )
            return calendar.date(from: components) ?? symptom.date
        }

        weeklyData = grouped.map { (weekStart, weekSymptoms) in
            WeeklyBarDataPoint(
                weekLabel: formatter.string(from: weekStart),
                weekStart: weekStart,
                count: weekSymptoms.count
            )
        }
        .sorted { $0.weekStart < $1.weekStart }
    }

    // MARK: - Ingredient Pie Computation

    private func computeIngredientData(from meals: [Meal]) {
        var ingredientCounts: [String: Int] = [:]

        for meal in meals {
            for item in meal.foodItems {
                if item.ingredients.isEmpty {
                    ingredientCounts[item.name, default: 0] += 1
                } else {
                    for ingredient in item.ingredients {
                        let normalized = ingredient
                            .trimmingCharacters(in: .whitespaces)
                            .capitalized
                        ingredientCounts[normalized, default: 0] += 1
                    }
                }
            }
        }

        ingredientData = ingredientCounts
            .sorted { $0.value > $1.value }
            .prefix(8)
            .map { IngredientSliceDataPoint(name: $0.key, count: $0.value) }
    }

    // MARK: - Helpers

    private func maxSeverityLevel(_ symptom: Symptom) -> Int {
        max(symptom.painLevel.rawValue, symptom.urgencyLevel.rawValue)
    }

    private func severityLabel(_ level: Int) -> String {
        switch level {
        case 0: return "None"
        case 1: return "Mild"
        case 2: return "Moderate"
        default: return "Severe"
        }
    }
}
