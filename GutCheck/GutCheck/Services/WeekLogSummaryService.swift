//
//  WeekLogSummaryService.swift
//  GutCheck
//
//  Builds per-day logging summaries for a span of days.
//
//  Three range queries, not one query per day. The dashboard week strip shows
//  seven days across three categories; asking per day would be twenty-one
//  round trips on a view that re-renders whenever the selection changes. The
//  strip is also the one place in the app that reads several days at once,
//  which is why this exists separately from DashboardDataStore's single-day
//  loading rather than inside it.
//

import Foundation

@MainActor
@Observable final class WeekLogSummaryService {

    static let shared = WeekLogSummaryService()

    @ObservationIgnored private let mealRepository: any MealRepositoryProtocol
    @ObservationIgnored private let symptomRepository: any SymptomRepositoryProtocol
    @ObservationIgnored private let doseRepository: any MedicationDoseRepositoryProtocol

    init(
        mealRepository: any MealRepositoryProtocol = MealRepository.shared,
        symptomRepository: any SymptomRepositoryProtocol = SymptomRepository.shared,
        doseRepository: any MedicationDoseRepositoryProtocol = MedicationDoseRepository.shared
    ) {
        self.mealRepository = mealRepository
        self.symptomRepository = symptomRepository
        self.doseRepository = doseRepository
    }

    /// Summaries for every day covered by `dates`, keyed by start of day.
    ///
    /// Keys are normalised to `startOfDay` so a caller can look up with any
    /// instant during the day. Days with nothing logged are present in the
    /// result with an empty summary rather than absent, so the caller does not
    /// have to distinguish "no data" from "not fetched".
    ///
    /// Returns an empty dictionary on a query failure rather than throwing.
    /// A missing indicator is a far better outcome than a dashboard that fails
    /// to render, and the strip remains fully usable without it.
    func summaries(for dates: [Date], userId: String) async -> [Date: DayLogSummary] {
        let calendar = Calendar.current
        let days = Set(dates.map { calendar.startOfDay(for: $0) }).sorted()

        guard let first = days.first, let last = days.last,
              let exclusiveEnd = calendar.date(byAdding: .day, value: 1, to: last) else {
            return [:]
        }

        // Every day starts present and empty, so an absent key always means
        // "not loaded" rather than "nothing logged".
        var result = Dictionary(uniqueKeysWithValues: days.map { ($0, DayLogSummary()) })

        do {
            // Three concurrent queries. They touch different stores and none
            // depends on another's result.
            async let meals = mealRepository.fetchMealsForDateRange(
                startDate: first, endDate: exclusiveEnd, userId: userId
            )
            async let symptoms = symptomRepository.fetchSymptomsForDateRange(
                startDate: first, endDate: exclusiveEnd, userId: userId
            )
            async let doses = doseRepository.fetchDosesForDateRange(
                startDate: first, endDate: exclusiveEnd, userId: userId
            )

            for meal in try await meals {
                let day = calendar.startOfDay(for: meal.date)
                result[day]?.hasMeal = true
            }
            for symptom in try await symptoms {
                let day = calendar.startOfDay(for: symptom.date)
                result[day]?.hasSymptom = true
            }
            for dose in try await doses {
                let day = calendar.startOfDay(for: dose.dateTaken)
                result[day]?.hasMedication = true
            }
        } catch {
            return [:]
        }

        return result
    }
}
