//
//  HealthScoreService.swift
//  GutCheck
//
//  Single source of truth for the daily health score.
//
//  The scoring rules used to live privately inside DashboardDataStore, which
//  meant App Intents (Siri) and the widgets had no way to ask for the score
//  without duplicating the formula. The calculation now lives here and
//  DashboardDataStore delegates to it, so every surface reports the same number.
//

import Foundation

// MARK: - Calculator

/// Pure scoring rules — no I/O, so they can be unit tested and reused by the
/// dashboard, App Intents and the widget sync service alike.
enum HealthScoreCalculator {

    /// Calculate the health score for a day's meals and symptoms.
    ///
    /// Score ranges from 1-10 with the following logic:
    /// - Base score: 7 (neutral)
    /// - No symptoms: +2 points
    /// - Symptom severity: -1 to -4 points based on pain/urgency levels
    /// - Meal frequency: +1 point for 2+ meals
    /// - Final score clamped to 1-10 range
    static func score(meals: [Meal], symptoms: [Symptom]) -> Int {
        var score = 7 // Base neutral score

        // Bonus for no symptoms
        if symptoms.isEmpty {
            score += 2
        } else {
            // Penalty based on symptom severity
            let totalSeverity = symptoms.reduce(0) { total, symptom in
                total + symptom.painLevel.rawValue + symptom.urgencyLevel.rawValue
            }
            let averageSeverity = totalSeverity / max(symptoms.count, 1)

            if averageSeverity >= 8 {
                score -= 4
            } else if averageSeverity >= 6 {
                score -= 3
            } else if averageSeverity >= 4 {
                score -= 2
            } else {
                score -= 1
            }
        }

        // Bonus for regular meals
        if meals.count >= 2 {
            score += 1
        }

        // Clamp score to 1-10 range
        return max(1, min(10, score))
    }

    /// Short qualitative descriptor used in spoken Siri responses.
    static func descriptor(for score: Int) -> String {
        switch score {
        case 8...10: return "great"
        case 6...7: return "good"
        case 4...5: return "fair"
        default: return "rough"
        }
    }
}

// MARK: - Summary

/// The score for a given day plus the context other surfaces need alongside it.
struct HealthScoreSummary: Equatable, Sendable {
    let date: Date
    let score: Int
    /// Previous day's score, when it could be computed.
    let previousScore: Int?
    let mealCount: Int
    let symptomCount: Int
    let lastMealName: String?
    let lastMealDate: Date?

    /// Short qualitative descriptor, e.g. "good".
    var descriptor: String {
        HealthScoreCalculator.descriptor(for: score)
    }
}

// MARK: - Service

/// Fetches the data a health score needs and computes it.
///
/// Follows the repository-injection style used by the ViewModels so it can be
/// exercised with the existing mock repositories.
@MainActor
final class HealthScoreService {
    static let shared = HealthScoreService()

    private let mealRepository: any MealRepositoryProtocol
    private let symptomRepository: any SymptomRepositoryProtocol

    init(
        mealRepository: any MealRepositoryProtocol = MealRepository.shared,
        symptomRepository: any SymptomRepositoryProtocol = SymptomRepository.shared
    ) {
        self.mealRepository = mealRepository
        self.symptomRepository = symptomRepository
    }

    /// Compute the score summary for a date, including the previous day's score
    /// so callers can render a trend.
    /// - Throws: `RepositoryError.noAuthenticatedUser` when nobody is signed in.
    func summary(for date: Date = Date.now) async throws -> HealthScoreSummary {
        guard let userId = AuthenticationManager.shared.currentUserId else {
            throw RepositoryError.noAuthenticatedUser
        }

        let calendar = Calendar.current
        let previousDay = calendar.date(byAdding: .day, value: -1, to: date) ?? date

        let meals = try await mealRepository.fetchMealsForDate(date, userId: userId)
        let symptoms = try await symptomRepository.fetchSymptomsForDate(date, userId: userId)

        // The previous day is best-effort: a trend arrow is not worth failing
        // the whole request for.
        var previousScore: Int?
        do {
            let previousMeals = try await mealRepository.fetchMealsForDate(previousDay, userId: userId)
            let previousSymptoms = try await symptomRepository.fetchSymptomsForDate(previousDay, userId: userId)
            previousScore = HealthScoreCalculator.score(meals: previousMeals, symptoms: previousSymptoms)
        } catch {
            previousScore = nil
        }

        let lastMeal = meals.max(by: { $0.date < $1.date })

        return HealthScoreSummary(
            date: date,
            score: HealthScoreCalculator.score(meals: meals, symptoms: symptoms),
            previousScore: previousScore,
            mealCount: meals.count,
            symptomCount: symptoms.count,
            lastMealName: lastMeal?.name,
            lastMealDate: lastMeal?.date
        )
    }
}
