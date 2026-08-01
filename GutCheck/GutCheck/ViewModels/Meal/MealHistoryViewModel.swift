//
//  MealHistoryViewModel.swift
//  GutCheck
//
//  Paginated meal history view model
//

import SwiftUI

enum MealFilter: String, CaseIterable {
    case all = "all"
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"

    var displayName: String {
        switch self {
        case .all: return "All"
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }
}

@MainActor
@Observable class MealHistoryViewModel: HasLoadingState {
    var groupedMeals: [Date: [Meal]] = [:]
    var hasMoreData = true
    var error: Error?
    var selectedFilter: MealFilter = .all
    var startDate: Date?
    var endDate: Date?

    let loadingState = LoadingStateManager()

    private let mealRepository = MealRepository.shared

    /// How many records have been read so far. Replaces the Firestore cursor
    /// the previous implementation carried between pages.
    private var loadedCount = 0
    private let pageSize = 20

    func loadMeals(filter: MealFilter = .all, refresh: Bool = false) async {
        if refresh {
            await refreshMeals(filter: filter)
            return
        }

        guard !isLoading else { return }

        isLoading = true
        selectedFilter = filter
        error = nil

        do {
            let page = try await fetchPage(offset: 0)
            loadedCount = page.count
            hasMoreData = page.count == pageSize
            groupedMeals = Self.grouped(Self.applying(filter, to: page))
        } catch {
            self.error = error
        }

        self.isLoading = false
    }

    func loadMoreMeals() async {
        guard !loadingState.isLoadingMore && hasMoreData && !isLoading else { return }

        loadingState.startLoadingMore()

        do {
            let page = try await fetchPage(offset: loadedCount)
            loadedCount += page.count
            hasMoreData = page.count == pageSize

            for (date, meals) in Self.grouped(Self.applying(selectedFilter, to: page)) {
                groupedMeals[date, default: []].append(contentsOf: meals)
            }
        } catch {
            self.error = error
        }

        loadingState.stopLoadingMore()
    }

    /// Reads one page, honouring the optional date range.
    ///
    /// The range variant fetches the whole window and slices it rather than
    /// pushing the offset into the query — a bounded window is small enough
    /// that this stays cheap, and it keeps one code path for both cases.
    private func fetchPage(offset: Int) async throws -> [Meal] {
        let profileId = LocalUserService.currentProfileId

        guard let startDate, let endDate else {
            return try await mealRepository.fetchMealsPage(
                userId: profileId,
                offset: offset,
                limit: pageSize
            )
        }

        let inRange = try await mealRepository.fetchMealsForDateRange(
            startDate: startDate,
            endDate: endDate,
            userId: profileId
        )
        .sorted { $0.date > $1.date }

        guard offset < inRange.count else { return [] }
        return Array(inRange[offset ..< min(offset + pageSize, inRange.count)])
    }

    func refreshMeals(filter: MealFilter = .all) async {
        loadedCount = 0
        hasMoreData = true
        groupedMeals.removeAll()
        await loadMeals(filter: filter)
    }

    func setDateRange(start: Date?, end: Date?) {
        startDate = start
        endDate = end
    }

    func clearDateRange() {
        startDate = nil
        endDate = nil
    }

    func deleteMeal(_ meal: Meal) async {
        do {
            try await mealRepository.delete(id: meal.id)
            SpotlightIndexingService.shared.removeMeal(id: meal.id)

            // Remove from grouped meals
            for (date, meals) in groupedMeals {
                if let index = meals.firstIndex(where: { $0.id == meal.id }) {
                    groupedMeals[date]?.remove(at: index)
                    if groupedMeals[date]?.isEmpty == true {
                        groupedMeals.removeValue(forKey: date)
                    }
                    break
                }
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Helpers

    private static func grouped(_ meals: [Meal]) -> [Date: [Meal]] {
        Dictionary(grouping: meals) { Calendar.current.startOfDay(for: $0.date) }
    }

    private static func applying(_ filter: MealFilter, to meals: [Meal]) -> [Meal] {
        guard filter != .all else { return meals }
        return meals.filter { $0.type.rawValue == filter.rawValue }
    }

    // MARK: - Analytics Support

    var totalMealsCount: Int {
        groupedMeals.values.reduce(0) { $0 + $1.count }
    }

    var dateRange: String {
        let dates = groupedMeals.keys.sorted()
        guard let firstDate = dates.first, let lastDate = dates.last else {
            return "No data"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        if Calendar.current.isDate(firstDate, inSameDayAs: lastDate) {
            return formatter.string(from: firstDate)
        } else {
            return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
        }
    }

    func getMealsByType() -> [MealFilter: Int] {
        var counts: [MealFilter: Int] = [:]

        for meals in groupedMeals.values {
            for meal in meals {
                if let mealType = MealFilter(rawValue: meal.type.rawValue) {
                    counts[mealType, default: 0] += 1
                }
            }
        }

        return counts
    }
}
