import Foundation

/// Ranked item for display in summary cards
struct RankedItem: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

@MainActor
@Observable class InsightsViewModel {
    var recentInsights: [HealthInsight] = []
    var patterns: [HealthPattern] = []
    var recommendations: [HealthRecommendation] = []
    var isLoading = false
    var error: String?

    // MARK: - Weekly Summary Data

    var weeklyMealCount: Int = 0
    var weeklySymptomCount: Int = 0
    var topSymptoms: [RankedItem] = []
    var topTriggerFoods: [RankedItem] = []
    var bestDays: [RankedItem] = []
    var weeklyTriggerReport: WeeklyTriggerReport?
    var triggerPatterns: [TriggerPattern] = []
    var topTriggerPatterns: [TriggerPattern] = []
    var mealSuggestions: [MealSuggestion] = []

    private let insightsService = InsightsService.shared
    private let mealRepository: any MealRepositoryProtocol
    private let symptomRepository: any SymptomRepositoryProtocol
    private let healthKitManager: any HealthKitManagerProtocol
    private let userService = LocalUserService.shared
    
    init(mealRepository: any MealRepositoryProtocol = MealRepository.shared,
         symptomRepository: any SymptomRepositoryProtocol = SymptomRepository.shared,
         healthKitManager: any HealthKitManagerProtocol = HealthKitManager.shared) {
        self.mealRepository = mealRepository
        self.symptomRepository = symptomRepository
        self.healthKitManager = healthKitManager
    }
    
    func loadInsights() async {
        isLoading = true
        error = nil

        // Load cached insights for instant display on fresh launch
        if recentInsights.isEmpty,
           let cached = BackgroundTaskService.shared.loadCachedInsights() {
            recentInsights = cached
            patterns = convertInsightsToPatterns(cached)
            recommendations = convertInsightsToRecommendations(cached)
        }

        do {
            // Get current user ID
            let userId = getCurrentUserId()
            
            // Calculate time range for last 30 days
            let endDate = Date.now
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
            let timeRange = DateInterval(start: startDate, end: endDate)
            
            // Fetch real data
            let meals = try await mealRepository.fetchMealsForDateRange(
                startDate: startDate,
                endDate: endDate,
                userId: userId
            )
            
            let symptoms = try await symptomRepository.fetchSymptomsForDateRange(
                startDate: startDate,
                endDate: endDate,
                userId: userId
            )
            
            // Fetch health data if available
            let healthData = await fetchHealthData(for: timeRange)
            
            // Generate real insights using the service
            await insightsService.generateInsights(
                timeRange: timeRange,
                meals: meals,
                symptoms: symptoms,
                healthData: healthData
            )
            
            // Get insights from the service
            recentInsights = insightsService.recentInsights
            
            // Convert insights to patterns and recommendations
            patterns = convertInsightsToPatterns(recentInsights)
            recommendations = convertInsightsToRecommendations(recentInsights)

            // Compute weekly summary cards
            computeWeeklySummaries(meals: meals, symptoms: symptoms)

            // Compute weekly trigger report (week-over-week comparison)
            computeWeeklyTriggerReport(meals: meals, symptoms: symptoms)

            // Compute trigger patterns with scoring and severity prediction
            await computeTriggerPatterns(meals: meals, symptoms: symptoms)

            // Compute safe meal suggestions using trigger pattern data
            computeMealSuggestions(meals: meals, triggerPatterns: triggerPatterns)

        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func fetchHealthData(for timeRange: DateInterval) async -> GutHealthData? {
        // HealthKit's callback is not guaranteed to fire exactly once, and if the
        // enclosing Task is cancelled the completion can still arrive afterwards.
        // Resuming a checked continuation twice traps, so the guard below makes
        // the resume idempotent. `hasResumed` is only touched inside the callback,
        // which HealthKit delivers serially.
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            healthKitManager.fetchGutHealthData(
                from: timeRange.start,
                to: timeRange.end
            ) { healthData in
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: healthData)
            }
        }
    }
    
    private func convertInsightsToPatterns(_ insights: [HealthInsight]) -> [HealthPattern] {
        return insights.compactMap { insight -> HealthPattern? in
            // Convert insights to patterns based on their content
            let confidence = Double(insight.confidenceLevel) / 100.0
            
            return HealthPattern(
                title: insight.title,
                description: insight.summary,
                iconName: insight.iconName,
                confidence: confidence,
                dateRange: insight.dateRange,
                supportingData: [insight.detailedDescription ?? ""],
                recommendations: insight.recommendations
            )
        }
    }
    
    private func convertInsightsToRecommendations(_ insights: [HealthInsight]) -> [HealthRecommendation] {
        return insights.compactMap { insight -> HealthRecommendation? in
            // Determine priority based on confidence level
            let priority: HealthRecommendation.RecommendationPriority
            if insight.confidenceLevel >= 80 {
                priority = .high
            } else if insight.confidenceLevel >= 60 {
                priority = .medium
            } else {
                priority = .low
            }
            
            return HealthRecommendation(
                title: insight.title,
                description: insight.summary,
                iconName: insight.iconName,
                priority: priority,
                actionItems: insight.recommendations,
                source: "AI Analysis",
                dateCreated: Date.now
            )
        }
    }
    
    private func getCurrentUserId() -> String {
        if let currentUser = userService.currentUser {
            return currentUser.id
        } else {
            return "default_user"
        }
    }

    // MARK: - Weekly Summary Computation

    private func computeWeeklySummaries(meals: [Meal], symptoms: [Symptom]) {
        let calendar = Calendar.current
        let now = Date.now
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        let weekMeals = meals.filter { $0.date >= weekAgo }
        let weekSymptoms = symptoms.filter { $0.date >= weekAgo }

        weeklyMealCount = weekMeals.count
        weeklySymptomCount = weekSymptoms.count

        computeTopSymptoms(from: weekSymptoms)
        computeTriggerFoods(meals: meals, symptoms: symptoms)
        computeBestDays(symptoms: symptoms)
    }

    /// Rank symptom characteristics by frequency this week
    private func computeTopSymptoms(from symptoms: [Symptom]) {
        var counts: [String: Int] = [:]

        for symptom in symptoms {
            if symptom.painLevel != .none {
                let label: String
                switch symptom.painLevel {
                case .mild: label = "Mild Pain"
                case .moderate: label = "Moderate Pain"
                case .severe: label = "Severe Pain"
                case .none: continue
                }
                counts[label, default: 0] += 1
            }

            if symptom.urgencyLevel != .none {
                let label: String
                switch symptom.urgencyLevel {
                case .mild: label = "Mild Urgency"
                case .moderate: label = "Moderate Urgency"
                case .urgent: label = "High Urgency"
                case .none: continue
                }
                counts[label, default: 0] += 1
            }

            // Count abnormal stool types (Bristol 1-2 = constipation, 6-7 = diarrhea)
            switch symptom.stoolType {
            case .type1, .type2:
                counts["Constipation", default: 0] += 1
            case .type6, .type7:
                counts["Loose Stool", default: 0] += 1
            default:
                break
            }
        }

        topSymptoms = counts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { RankedItem(name: $0.key, count: $0.value) }
    }

    /// Find foods eaten 2-8 hours before symptoms, rank by frequency
    private func computeTriggerFoods(meals: [Meal], symptoms: [Symptom]) {
        var foodCounts: [String: Int] = [:]

        for symptom in symptoms {
            // Only consider symptoms with actual issues
            guard symptom.painLevel != .none || symptom.urgencyLevel != .none
                    || symptom.stoolType == .type1 || symptom.stoolType == .type2
                    || symptom.stoolType == .type6 || symptom.stoolType == .type7 else {
                continue
            }

            // Find meals eaten 2-8 hours before this symptom
            let windowStart = symptom.date.addingTimeInterval(-8 * 3600)
            let windowEnd = symptom.date.addingTimeInterval(-2 * 3600)

            let precedingMeals = meals.filter { $0.date >= windowStart && $0.date <= windowEnd }

            for meal in precedingMeals {
                for item in meal.foodItems {
                    foodCounts[item.name, default: 0] += 1
                }
            }
        }

        topTriggerFoods = foodCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { RankedItem(name: $0.key, count: $0.value) }
    }

    // MARK: - Weekly Trigger Report

    private func computeWeeklyTriggerReport(meals: [Meal], symptoms: [Symptom]) {
        let calendar = Calendar.current
        let now = Date.now
        let currentWeekStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let previousWeekStart = calendar.date(byAdding: .day, value: -14, to: now) ?? now

        let currentWeekMeals = meals.filter { $0.date >= currentWeekStart }
        let currentWeekSymptoms = symptoms.filter { $0.date >= currentWeekStart }
        let previousWeekMeals = meals.filter { $0.date >= previousWeekStart && $0.date < currentWeekStart }
        let previousWeekSymptoms = symptoms.filter { $0.date >= previousWeekStart && $0.date < currentWeekStart }

        let currentTriggers = computeTriggerEntries(meals: currentWeekMeals, symptoms: currentWeekSymptoms)
        let previousTriggers = computeTriggerEntries(meals: previousWeekMeals, symptoms: previousWeekSymptoms)

        let currentFoodNames = Set(currentTriggers.keys)
        let previousFoodNames = Set(previousTriggers.keys)

        let newTriggers = currentFoodNames.subtracting(previousFoodNames)
            .compactMap { currentTriggers[$0] }
            .sorted { $0.correlationCount > $1.correlationCount }
        let recurringTriggers = currentFoodNames.intersection(previousFoodNames)
            .compactMap { currentTriggers[$0] }
            .sorted { $0.correlationCount > $1.correlationCount }
        let resolvedTriggers = previousFoodNames.subtracting(currentFoodNames)
            .compactMap { previousTriggers[$0] }
            .sorted { $0.correlationCount > $1.correlationCount }

        // Only produce a report if there is meaningful data
        guard !newTriggers.isEmpty || !recurringTriggers.isEmpty || !resolvedTriggers.isEmpty else {
            weeklyTriggerReport = nil
            return
        }

        weeklyTriggerReport = WeeklyTriggerReport(
            id: UUID(),
            generatedDate: now,
            weekStart: currentWeekStart,
            weekEnd: now,
            newTriggers: newTriggers,
            recurringTriggers: recurringTriggers,
            resolvedTriggers: resolvedTriggers,
            currentWeekSymptomCount: currentWeekSymptoms.count,
            previousWeekSymptomCount: previousWeekSymptoms.count,
            currentWeekMealCount: currentWeekMeals.count,
            previousWeekMealCount: previousWeekMeals.count
        )
    }

    // MARK: - Trigger Pattern Computation

    private func computeTriggerPatterns(meals: [Meal], symptoms: [Symptom]) async {
        let patterns = await PatternRecognitionService.shared.analyzeTriggerPatterns(
            meals: meals,
            symptoms: symptoms
        )
        self.triggerPatterns = patterns
        self.topTriggerPatterns = Array(patterns.prefix(3))
    }

    /// Compute trigger entries for a given set of meals and symptoms using 2-8 hour correlation.
    private func computeTriggerEntries(meals: [Meal], symptoms: [Symptom]) -> [String: TriggerEntry] {
        var foodData: [String: (count: Int, onsetHours: [Double], symptomTypes: Set<String>)] = [:]

        for symptom in symptoms {
            guard symptom.painLevel != .none || symptom.urgencyLevel != .none
                    || symptom.stoolType == .type1 || symptom.stoolType == .type2
                    || symptom.stoolType == .type6 || symptom.stoolType == .type7 else {
                continue
            }

            // Determine symptom labels
            var symptomLabels: [String] = []
            switch symptom.painLevel {
            case .mild: symptomLabels.append("Mild Pain")
            case .moderate: symptomLabels.append("Moderate Pain")
            case .severe: symptomLabels.append("Severe Pain")
            case .none: break
            }
            switch symptom.urgencyLevel {
            case .mild: symptomLabels.append("Mild Urgency")
            case .moderate: symptomLabels.append("Moderate Urgency")
            case .urgent: symptomLabels.append("High Urgency")
            case .none: break
            }
            switch symptom.stoolType {
            case .type1, .type2: symptomLabels.append("Constipation")
            case .type6, .type7: symptomLabels.append("Loose Stool")
            default: break
            }

            // Find meals eaten 2-8 hours before this symptom
            let windowStart = symptom.date.addingTimeInterval(-8 * 3600)
            let windowEnd = symptom.date.addingTimeInterval(-2 * 3600)
            let precedingMeals = meals.filter { $0.date >= windowStart && $0.date <= windowEnd }

            for meal in precedingMeals {
                let onsetHours = symptom.date.timeIntervalSince(meal.date) / 3600
                for item in meal.foodItems {
                    var entry = foodData[item.name] ?? (count: 0, onsetHours: [], symptomTypes: Set())
                    entry.count += 1
                    entry.onsetHours.append(onsetHours)
                    symptomLabels.forEach { entry.symptomTypes.insert($0) }
                    foodData[item.name] = entry
                }
            }
        }

        var result: [String: TriggerEntry] = [:]
        for (name, data) in foodData {
            let avgOnset = data.onsetHours.isEmpty ? 0 : data.onsetHours.reduce(0, +) / Double(data.onsetHours.count)
            let confidence = min(0.95, Double(data.count) / 10.0 + 0.3)

            var recommendations = ["Consider reducing \(name) intake for 2-4 weeks"]
            if data.count >= 3 {
                recommendations.append("Strong correlation detected — consult a dietitian")
            }
            recommendations.append("Reintroduce gradually to confirm sensitivity")

            result[name] = TriggerEntry(
                id: UUID(),
                foodName: name,
                correlationCount: data.count,
                confidence: confidence,
                averageOnsetHours: avgOnset,
                associatedSymptoms: Array(data.symptomTypes).sorted(),
                recommendations: recommendations
            )
        }
        return result
    }

    // MARK: - Meal Suggestions

    /// Compute safe meal suggestions using constraint satisfaction:
    /// hard filter out meals with high-trigger foods, score remaining by safety, apply variety penalty.
    private func computeMealSuggestions(meals: [Meal], triggerPatterns: [TriggerPattern]) {
        // Build trigger score lookup: lowercased food name → overall score (0-100)
        var triggerScoreMap: [String: Int] = [:]
        for pattern in triggerPatterns {
            let key = pattern.foodName.lowercased().trimmingCharacters(in: .whitespaces)
            triggerScoreMap[key] = pattern.triggerScore.overall
        }

        // Group meals by name (case-insensitive)
        let grouped = Dictionary(grouping: meals) { $0.name.lowercased().trimmingCharacters(in: .whitespaces) }

        let now = Date.now
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now
        var suggestions: [MealSuggestion] = []

        for (_, mealGroup) in grouped {
            guard let representative = mealGroup.first else { continue }

            // Collect unique food item names for this meal
            let allFoodItems = representative.foodItems.map { $0.name }
            guard !allFoodItems.isEmpty else { continue }

            // Hard constraint: skip meals with any high-trigger food (score >= 60)
            let hasHighTrigger = allFoodItems.contains { item in
                let key = item.lowercased().trimmingCharacters(in: .whitespaces)
                return (triggerScoreMap[key] ?? 0) >= 60
            }
            guard !hasHighTrigger else { continue }

            // Compute safety score: average of (100 - triggerScore) per food item
            let itemScores = allFoodItems.map { item -> Int in
                let key = item.lowercased().trimmingCharacters(in: .whitespaces)
                let triggerScore = triggerScoreMap[key] ?? 0
                return 100 - triggerScore
            }
            var safetyScore = itemScores.reduce(0, +) / max(1, itemScores.count)

            let timesEaten = mealGroup.count
            let lastEaten = mealGroup.map(\.date).max() ?? now

            // Soft boost: meals eaten 3+ times with no trigger correlation get +10
            let hasTriggerCorrelation = allFoodItems.contains { item in
                let key = item.lowercased().trimmingCharacters(in: .whitespaces)
                return triggerScoreMap[key] != nil
            }
            if timesEaten >= 3 && !hasTriggerCorrelation {
                safetyScore = min(100, safetyScore + 10)
            }

            // Variety penalty: if eaten in last 3 days, subtract 15
            if lastEaten >= threeDaysAgo {
                safetyScore = max(0, safetyScore - 15)
            }

            // Generate reasoning
            let reasoning: String
            if !hasTriggerCorrelation {
                reasoning = "No symptom correlations detected across \(timesEaten) meal\(timesEaten == 1 ? "" : "s")"
            } else if safetyScore >= 80 {
                reasoning = "All items have low trigger scores"
            } else {
                reasoning = "Most items are well-tolerated based on your history"
            }

            suggestions.append(MealSuggestion(
                id: UUID(),
                mealName: representative.name,
                mealType: representative.type,
                foodItems: allFoodItems,
                safetyScore: safetyScore,
                timesEaten: timesEaten,
                lastEaten: lastEaten,
                reasoning: reasoning
            ))
        }

        // Sort by safety score descending, take top 8
        self.mealSuggestions = suggestions
            .sorted { $0.safetyScore > $1.safetyScore }
            .prefix(8)
            .map { $0 }
    }

    /// Rank days of the week by lowest symptom count (last 30 days)
    private func computeBestDays(symptoms: [Symptom]) {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let dayNames = formatter.weekdaySymbols ?? ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        // Count symptoms per weekday
        var dayCounts: [Int: Int] = [:]  // weekday (1=Sun..7=Sat) → count
        var dayOccurrences: [Int: Int] = [:]  // how many of each weekday are in the 30-day range

        let now = Date.now
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        // Count occurrences of each weekday in the range
        var cursor = thirtyDaysAgo
        while cursor <= now {
            let weekday = calendar.component(.weekday, from: cursor)
            dayOccurrences[weekday, default: 0] += 1
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? now.addingTimeInterval(86400)
        }

        for symptom in symptoms {
            let weekday = calendar.component(.weekday, from: symptom.date)
            dayCounts[weekday, default: 0] += 1
        }

        // Rank by lowest average symptoms per day occurrence
        bestDays = (1...7)
            .map { weekday -> (String, Double) in
                let count = Double(dayCounts[weekday] ?? 0)
                let occurrences = Double(dayOccurrences[weekday] ?? 1)
                let avg = occurrences > 0 ? count / occurrences : 0
                return (dayNames[weekday - 1], avg)
            }
            .sorted { $0.1 < $1.1 }
            .prefix(3)
            .map { RankedItem(name: $0.0, count: Int($0.1 * 10)) }  // Store avg * 10 for display precision
    }
}
