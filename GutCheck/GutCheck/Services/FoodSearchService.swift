//  Enhanced FoodSearchService.swift
//  GutCheck
//
//  Enhanced to capture comprehensive nutrition data from Nutritionix API

import Foundation

@MainActor
class FoodSearchService {
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
        request.setValue(NutritionixSecrets.appId, forHTTPHeaderField: "x-app-id")
        request.setValue(NutritionixSecrets.apiKey, forHTTPHeaderField: "x-app-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(NutritionixResponse.self, from: data)
            
            // Get detailed nutrition for each food item
            var detailedFoods: [NutritionixFood] = []
            
            // Process common foods (these usually have less detailed nutrition)
            if let commonFoods = decoded.common {
                for commonFood in commonFoods.prefix(3) { // Limit to avoid too many API calls
                    if let detailedFood = await getDetailedNutrition(for: commonFood) {
                        detailedFoods.append(detailedFood)
                    } else {
                        detailedFoods.append(commonFood.toNutritionixFood())
                    }
                }
            }
            
                        // Process branded foods (these usually have more complete nutrition)
            if let brandedFoods = decoded.branded {
                for brandedFood in brandedFoods.prefix(2) { // Limit to avoid too many API calls
                    detailedFoods.append(brandedFood.toNutritionixFood())
                }
            }
            
            DispatchQueue.main.async {
                self.results = detailedFoods
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
        }
    }
    
    // Get detailed nutrition data for a specific food item
    private func getDetailedNutrition(for foodItem: NutritionixCommonFood) async -> NutritionixFood? {
        let urlString = "https://trackapi.nutritionix.com/v2/natural/nutrients"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(NutritionixSecrets.appId, forHTTPHeaderField: "x-app-id")
        request.setValue(NutritionixSecrets.apiKey, forHTTPHeaderField: "x-app-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "query": foodItem.name,
            "timezone": TimeZone.current.identifier
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let foods = json["foods"] as? [[String: Any]],
               let firstFood = foods.first {
                
                        return createDetailedNutritionixFood(from: firstFood, originalItem: foodItem)
            }
        } catch {
            print("Error getting detailed nutrition: \(error)")
        }
        
        return foodItem.toNutritionixFood()
    }
    
    private func createDetailedNutritionixFood(from detailedData: [String: Any], originalItem: NutritionixCommonFood) -> NutritionixFood {
        // Extract nutrition data
        let name = detailedData["food_name"] as? String ?? originalItem.name
        let brand = detailedData["brand_name"] as? String
        
        // Basic macros
        let calories = detailedData["nf_calories"] as? Double
        let protein = detailedData["nf_protein"] as? Double
        let carbs = detailedData["nf_total_carbohydrate"] as? Double
        let fat = detailedData["nf_total_fat"] as? Double
        let fiber = detailedData["nf_dietary_fiber"] as? Double
        let sugar = detailedData["nf_sugars"] as? Double
        let sodium = detailedData["nf_sodium"] as? Double
        
        // Additional nutrition
        let saturatedFat = detailedData["nf_saturated_fat"] as? Double
        let cholesterol = detailedData["nf_cholesterol"] as? Double
        let potassium = detailedData["nf_potassium"] as? Double
        let vitaminA = detailedData["nf_vitamin_a_dv"] as? Double
        let vitaminC = detailedData["nf_vitamin_c_dv"] as? Double
        let calcium = detailedData["nf_calcium_dv"] as? Double
        let iron = detailedData["nf_iron_dv"] as? Double
        
        // Serving info
        let servingQty = detailedData["serving_qty"] as? Double
        let servingUnit = detailedData["serving_unit"] as? String
        let servingWeight = detailedData["serving_weight_grams"] as? Double

        return NutritionixFood(
            id: originalItem.id,
            name: name,
            brand: brand,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servingUnit: servingUnit,
            servingQty: servingQty,
            servingWeight: servingWeight,
            saturatedFat: saturatedFat,
            cholesterol: cholesterol,
            potassium: potassium,
            vitaminA: vitaminA,
            vitaminC: vitaminC,
            calcium: calcium,
            iron: iron
        )
    }
}

// MARK: - Enhanced Response Models

// Using models from NutritionixModels.swift
