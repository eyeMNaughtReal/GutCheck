//
//  MealRiskPredictionService.swift
//  GutCheck
//
//  Predicts meal risk using historical trigger patterns and compound analysis.
//

import Foundation

@MainActor
@Observable class MealRiskPredictionService {
    static let shared = MealRiskPredictionService()

    // MARK: - Cached State

    private(set) var cachedTriggerPatterns: [TriggerPattern] = []
    private(set) var isLoaded: Bool = false
    private(set) var isLoading: Bool = false

    private let patternService = PatternRecognitionService.shared
    private let compoundDatabase = FoodCompoundDatabase.shared
    private let mealRepository = MealRepository.shared
    private let symptomRepository = SymptomRepository.shared

    private init() {}

    // MARK: - Data Loading

    /// Load user's 30-day history and compute trigger patterns.
    /// Call once when MealBuilderView appears.
    func loadHistoricalData() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let userId = LocalUserService.currentProfileId
            let endDate = Date.now
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate

            async let mealsTask = mealRepository.fetchMealsForDateRange(
                startDate: startDate, endDate: endDate, userId: userId
            )
            async let symptomsTask = symptomRepository.fetchSymptomsForDateRange(
                startDate: startDate, endDate: endDate, userId: userId
            )

            let meals = try await mealsTask
            let symptoms = try await symptomsTask

            cachedTriggerPatterns = await patternService.analyzeTriggerPatterns(
                meals: meals, symptoms: symptoms
            )
            isLoaded = true
        } catch {
            // Gracefully degrade — compound analysis still works
            cachedTriggerPatterns = []
            isLoaded = true
        }
    }

    /// Reset cached data
    func resetCache() {
        cachedTriggerPatterns = []
        isLoaded = false
    }

    // MARK: - Prediction

    /// Predict risk for the given food items. Returns nil if no food items provided.
    func predictRisk(for foodItems: [FoodItem]) -> MealRiskAssessment? {
        guard !foodItems.isEmpty else { return nil }

        var itemRisks: [FoodItemRiskDetail] = []

        for item in foodItems {
            let detail = assessFoodItem(item)
            itemRisks.append(detail)
        }

        let overallScore = computeOverallScore(from: itemRisks)
        let overallLevel = riskLevel(for: overallScore)
        let explanation = generateOverallExplanation(itemRisks: itemRisks, overallLevel: overallLevel)

        return MealRiskAssessment(
            overallRiskScore: overallScore,
            overallRiskLevel: overallLevel,
            foodItemRisks: itemRisks,
            overallExplanation: explanation,
            assessedAt: Date.now,
            hasHistoricalData: !cachedTriggerPatterns.isEmpty
        )
    }

    // MARK: - Per-Food Assessment

    private func assessFoodItem(_ item: FoodItem) -> FoodItemRiskDetail {
        let key = item.name.lowercased().trimmingCharacters(in: .whitespaces)

        // 1. Look for a matching TriggerPattern from user's history
        let matchedPattern = cachedTriggerPatterns.first { pattern in
            pattern.foodName.lowercased().trimmingCharacters(in: .whitespaces) == key
        }

        // 2. Get compound risk from FoodCompoundDatabase
        let compounds = compoundDatabase.getCompoundsForFood(
            name: item.name, ingredients: item.ingredients
        )
        let highCompounds = compounds.filter { $0.severity == .high }
        let medCompounds = compounds.filter { $0.severity == .medium }

        // 3. Compute score
        var score: Int
        var explanation: String
        var dataSource: RiskDataSource

        if let pattern = matchedPattern {
            let historicalScore = pattern.triggerScore.overall
            let compoundScore = computeCompoundOnlyScore(high: highCompounds.count, med: medCompounds.count)

            if compoundScore > 0 {
                score = Int(Double(historicalScore) * 0.7 + Double(compoundScore) * 0.3)
                dataSource = .combined
            } else {
                score = historicalScore
                dataSource = .historicalCorrelation
            }

            explanation = generateHistoricalExplanation(
                foodName: item.name,
                pattern: pattern
            )
        } else if !compounds.isEmpty {
            score = computeCompoundOnlyScore(high: highCompounds.count, med: medCompounds.count)
            dataSource = .compoundAnalysis
            explanation = generateCompoundExplanation(
                foodName: item.name,
                highCount: highCompounds.count,
                medCount: medCompounds.count,
                compounds: compounds
            )
        } else {
            score = 0
            dataSource = .compoundAnalysis
            explanation = "No known risk factors for \(item.name)"
        }

        score = min(100, max(0, score))

        return FoodItemRiskDetail(
            id: UUID(),
            foodName: item.name,
            riskScore: score,
            riskLevel: riskLevel(for: score),
            explanation: explanation,
            matchedTriggerPattern: matchedPattern,
            flaggedCompounds: compounds,
            dataSource: dataSource
        )
    }

    // MARK: - Score Computation

    private func computeCompoundOnlyScore(high: Int, med: Int) -> Int {
        let raw = high * 15 + med * 8
        return min(75, raw)
    }

    private func computeOverallScore(from itemRisks: [FoodItemRiskDetail]) -> Int {
        guard !itemRisks.isEmpty else { return 0 }
        let maxScore = itemRisks.map(\.riskScore).max() ?? 0
        let avgScore = itemRisks.map(\.riskScore).reduce(0, +) / itemRisks.count
        return min(100, Int(Double(maxScore) * 0.6 + Double(avgScore) * 0.4))
    }

    private func riskLevel(for score: Int) -> MealRiskLevel {
        switch score {
        case 0..<30: return .low
        case 30..<60: return .moderate
        default: return .high
        }
    }

    // MARK: - Explanation Generation

    private func generateHistoricalExplanation(foodName: String, pattern: TriggerPattern) -> String {
        let triggeringPct = pattern.totalObservations > 0
            ? Int(Double(pattern.triggeringObservations) / Double(pattern.totalObservations) * 100)
            : 0

        let painDesc: String
        switch pattern.severityPrediction.mostLikelyPainLevel {
        case .severe: painDesc = "severe pain"
        case .moderate: painDesc = "moderate pain"
        case .mild: painDesc = "mild discomfort"
        case .none: painDesc = "symptoms"
        }

        return "\(foodName) caused \(painDesc) in \(pattern.triggeringObservations) of \(pattern.totalObservations) meals (\(triggeringPct)%)"
    }

    private func generateCompoundExplanation(foodName: String, highCount: Int, medCount: Int, compounds: [FoodCompound]) -> String {
        if highCount > 0 {
            let names = compounds.filter { $0.severity == .high }.prefix(2).map(\.name).joined(separator: ", ")
            return "\(foodName) contains \(names) which may cause digestive issues"
        } else if medCount > 0 {
            return "\(foodName) contains \(medCount) compound(s) with moderate sensitivity risk"
        }
        return "\(foodName) has low compound risk"
    }

    private func generateOverallExplanation(itemRisks: [FoodItemRiskDetail], overallLevel: MealRiskLevel) -> String {
        let highCount = itemRisks.filter { $0.riskLevel == .high }.count
        let modCount = itemRisks.filter { $0.riskLevel == .moderate }.count

        switch overallLevel {
        case .high:
            return "\(highCount) high-risk item(s) detected. Consider alternatives."
        case .moderate:
            if highCount > 0 {
                return "\(highCount) high-risk and \(modCount) moderate-risk item(s) in this meal."
            }
            return "\(modCount) item(s) with moderate risk based on your history."
        case .low:
            return "This meal looks safe based on your history."
        }
    }
}
