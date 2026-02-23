//  FoodSearchService.swift
//  GutCheck
//
//  Food search using OpenFoodFacts database

import Foundation

@MainActor
class FoodSearchService: ObservableObject, HasLoadingState {
    @Published var results: [FoodSearchResult] = []
    
    let loadingState = LoadingStateManager()
    
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
        print("🔍 FoodSearchService: Starting search for '\(query)'")
        
        do {
            let products = try await openFoodFactsService.searchFoods(query: query, pageSize: 30)
            let searchResults = products.map { openFoodFactsService.convertToFoodSearchResult($0) }
            
            print("🔍 OpenFoodFacts returned: \(searchResults.count) foods")
            
            // Sort by nutrition completeness
            results = searchResults.sorted { food1, food2 in
                let score1 = calculateNutritionCompletenessScore(food1)
                let score2 = calculateNutritionCompletenessScore(food2)
                return score1 > score2
            }
            
            print("🔍 Search complete. Final results count: \(results.count)")
            
        } catch {
            print("🔍 Search error: \(error)")
            throw error
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
