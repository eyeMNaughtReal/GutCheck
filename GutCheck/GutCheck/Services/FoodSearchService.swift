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
            #if DEBUG
            #endif
            loadingState.setError(error.localizedDescription)
        }

        loadingState.stopLoading()
    }

    private func performSearch(query: String) async throws {
        #if DEBUG
        #endif

        // Launch both searches concurrently
        async let usdaResults = fetchUSDAResults(query: query)
        async let offResults = fetchOpenFoodFactsResults(query: query)

        let (usda, off) = await (usdaResults, offResults)

        #if DEBUG
        #endif

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

        #if DEBUG
        #endif
    }

    // MARK: - Per-source fetch helpers (soft-fail)

    private func fetchUSDAResults(query: String) async -> [FoodSearchResult] {
        do {
            let foods = try await usdaFoodService.searchFoods(query: query)
            return foods.map { usdaFoodService.convertToFoodSearchResult($0) }
        } catch {
            #if DEBUG
            #endif
            return []
        }
    }

    private func fetchOpenFoodFactsResults(query: String) async -> [FoodSearchResult] {
        do {
            let products = try await openFoodFactsService.searchFoods(query: query, pageSize: 30)
            return products.map { openFoodFactsService.convertToFoodSearchResult($0) }
        } catch {
            #if DEBUG
            #endif
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

    // MARK: - Ingredient Enhancement

    /// Fetches ingredient data from OpenFoodFacts and returns a copy of the item with ingredients populated.
    /// Returns the original item unchanged if it already has ingredients or the lookup fails.
    func enhanceFoodItemWithIngredients(_ foodItem: FoodItem) async -> FoodItem {
        guard foodItem.ingredients.isEmpty else {
            return foodItem
        }

        do {
            let products = try await openFoodFactsService.searchFoods(query: foodItem.name, pageSize: 1)
            guard let firstProduct = products.first,
                  let ingredientsText = firstProduct.ingredientsText,
                  !ingredientsText.isEmpty else {
                return foodItem
            }

            var enhancedItem = foodItem
            enhancedItem.ingredients = parseIngredients(from: ingredientsText)
            return enhancedItem
        } catch {
            #if DEBUG
            #endif
            return foodItem
        }
    }

    // MARK: - Ingredient Parsing

    private func parseIngredients(from ingredientsString: String) -> [String] {
        let cleanedString = ingredientsString
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ";", with: ",")
            .replacingOccurrences(of: " and ", with: ", ")
            .replacingOccurrences(of: " & ", with: ", ")

        return cleanedString
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
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
