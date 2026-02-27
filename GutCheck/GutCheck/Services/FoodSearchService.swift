//  FoodSearchService.swift
//  GutCheck
//
//  Food search combining USDA FoodData Central and OpenFoodFacts.
//  Both sources are queried concurrently; results are merged and deduplicated.

import Foundation

@MainActor
class FoodSearchService: ObservableObject, HasLoadingState {
    @Published var results: [FoodSearchResult] = []

    let loadingState = LoadingStateManager()

    private let usdaFoodService = USDAFoodService.shared
    private let openFoodFactsService = OpenFoodFactsService.shared

    func searchFoods(query: String) async {
        results = []
        loadingState.startLoading()

        do {
            try await performSearch(query: query)
            loadingState.clearError()
        } catch {
            print("❌ FoodSearchService: Search failed with error: \(error)")
            loadingState.setError(error.localizedDescription)
        }

        loadingState.stopLoading()
    }

    private func performSearch(query: String) async throws {
        print("🔍 FoodSearchService: Starting parallel search for '\(query)'")

        // Launch both searches concurrently
        async let usdaResults = fetchUSDAResults(query: query)
        async let offResults = fetchOpenFoodFactsResults(query: query)

        let (usda, off) = await (usdaResults, offResults)

        print("🔍 USDA returned: \(usda.count) | OpenFoodFacts returned: \(off.count)")

        // USDA first so its results take priority during deduplication
        let combined = usda + off

        guard !combined.isEmpty else {
            throw FoodSearchError.noResults
        }

        // Deduplicate by normalized name (first occurrence wins)
        var seen = Set<String>()
        let deduplicated = combined.filter { food in
            let key = food.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return seen.insert(key).inserted
        }

        // Sort by nutrition data completeness
        results = deduplicated.sorted {
            calculateNutritionCompletenessScore($0) > calculateNutritionCompletenessScore($1)
        }

        print("🔍 Search complete. Final results count: \(results.count)")
    }

    // MARK: - Per-source fetch helpers (soft-fail)

    private func fetchUSDAResults(query: String) async -> [FoodSearchResult] {
        do {
            let foods = try await usdaFoodService.searchFoods(query: query)
            return foods.map { usdaFoodService.convertToFoodSearchResult($0) }
        } catch {
            print("🔍 USDA search failed (continuing with OpenFoodFacts): \(error.localizedDescription)")
            return []
        }
    }

    private func fetchOpenFoodFactsResults(query: String) async -> [FoodSearchResult] {
        do {
            let products = try await openFoodFactsService.searchFoods(query: query, pageSize: 30)
            return products.map { openFoodFactsService.convertToFoodSearchResult($0) }
        } catch {
            print("🔍 OpenFoodFacts search failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Helper Methods

    private func calculateNutritionCompletenessScore(_ food: FoodSearchResult) -> Int {
        var score = 0
        if food.calories != nil { score += 3 }
        if food.protein != nil { score += 2 }
        if food.carbs != nil { score += 2 }
        if food.fat != nil { score += 2 }
        if food.fiber != nil { score += 1 }
        if food.sugar != nil { score += 1 }
        if food.sodium != nil { score += 1 }
        if food.brand != nil { score += 1 }
        if food.ingredients != nil { score += 1 }
        return score
    }
}

// MARK: - Errors

enum FoodSearchError: LocalizedError {
    case noResults

    var errorDescription: String? {
        switch self {
        case .noResults:
            return "No foods found. Try a different search term."
        }
    }
}
