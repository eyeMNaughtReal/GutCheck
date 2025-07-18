//  FoodSearchService.swift
//  GutCheck
//
//  Service for searching foods using Nutritionix API, with fallback to manual entry.

import Foundation

struct NutritionixFood: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String?
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let servingUnit: String?
    let servingQty: Double?
    let serving_weight_grams: Double?
    let fullData: [String: String]? // Simplified to String instead of AnyCodable
}

@MainActor
class FoodSearchService: ObservableObject {
    @Published var results: [NutritionixFood] = []
    @Published var isLoading = false
    @Published var error: String? = nil

    func searchFoods(query: String) async {
        guard !query.isEmpty else { results = []; return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        let urlString = "https://trackapi.nutritionix.com/v2/search/instant?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        guard let url = URL(string: urlString) else { error = "Invalid URL"; return }
        
        var request = URLRequest(url: url)
        request.setValue(Secrets.nutritionixAppId, forHTTPHeaderField: "x-app-id")
        request.setValue(Secrets.nutritionixApiKey, forHTTPHeaderField: "x-app-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(NutritionixResponse.self, from: data)
            let foods = (decoded.common + decoded.branded).map { $0.toNutritionixFood() }
            DispatchQueue.main.async { self.results = foods }
        } catch {
            DispatchQueue.main.async { self.error = error.localizedDescription }
        }
    }
}

// MARK: - Nutritionix API Response Models

struct NutritionixResponse: Codable {
    let common: [NutritionixFoodItem]
    let branded: [NutritionixFoodItem]
}

struct NutritionixFoodItem: Codable {
    let food_name: String
    let brand_name: String?
    let nix_item_id: String?
    let nf_calories: Double?
    let nf_protein: Double?
    let nf_total_carbohydrate: Double?
    let nf_total_fat: Double?
    let serving_unit: String?
    let serving_qty: Double?
    let nf_serving_weight_grams: Double?
    // ... add more fields as needed

    func toNutritionixFood() -> NutritionixFood {
        NutritionixFood(
            id: nix_item_id ?? UUID().uuidString,
            name: food_name,
            brand: brand_name,
            calories: nf_calories,
            protein: nf_protein,
            carbs: nf_total_carbohydrate,
            fat: nf_total_fat,
            servingUnit: serving_unit,
            servingQty: serving_qty,
            serving_weight_grams: nf_serving_weight_grams,
            fullData: nil
        )
    }
}
