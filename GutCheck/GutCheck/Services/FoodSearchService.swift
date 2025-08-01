//  Enhanced FoodSearchService.swift
//  GutCheck
//
//  Enhanced to capture comprehensive nutrition data from Nutritionix API

import Foundation

@MainActor
class FoodSearchService: ObservableObject {
    @Published var results: [NutritionixFood] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let baseURL = "https://trackapi.nutritionix.com/v2"
    private let appId = "0f4298bb"
    private let apiKey = "239f65a9165bbaa7be71fd1d7f040973"

    func searchFoods(query: String) async {
        results = []
        isLoading = true
        errorMessage = nil
        
        print("🍎 FoodSearchService: Starting search for '\(query)'")
        
        let url = URL(string: "\(baseURL)/search/instant")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appId, forHTTPHeaderField: "x-app-id")
        request.setValue(apiKey, forHTTPHeaderField: "x-app-key")
        
        print("🍎 API URL: \(url)")
        print("🍎 API Headers: x-app-id=\(appId), x-app-key=\(String(apiKey.prefix(8)))...")
        
        let requestBody: [String: Any] = [
            "query": query,
            "detailed": true,
            "line_delimited": true
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🍎 HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("🍎 Error response: \(String(data: data, encoding: .utf8) ?? "No data")")
                }
            }
            
            print("🍎 Raw response data length: \(data.count) bytes")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🍎 Raw response: \(responseString.prefix(200))...")
            }
            
            let decoder = JSONDecoder()
            let searchResponse = try decoder.decode(NutritionixResponse.self, from: data)
            print("🍎 Decoded \(searchResponse.branded?.count ?? 0) branded + \(searchResponse.common?.count ?? 0) common foods")
            
            // Process results
            var allFoods: [NutritionixFood] = []
            
            // Add common foods first (they're usually more accurate)
            if let commonFoods = searchResponse.common {
                allFoods.append(contentsOf: commonFoods.map { commonFood in
                    NutritionixFood(
                        id: UUID().uuidString,
                        name: commonFood.name,
                        brand: "Common",
                        calories: 0, // Will be filled when getting detailed info
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                        servingUnit: commonFood.servingUnit,
                        servingQty: commonFood.servingQty,
                        servingWeight: 100
                    )
                })
            }
            
            // Add branded foods
            if let brandedFoods = searchResponse.branded {
                allFoods.append(contentsOf: brandedFoods.map { brandedFood in
                    NutritionixFood(
                        id: brandedFood.id,
                        name: brandedFood.name,
                        brand: brandedFood.brand,
                        calories: brandedFood.calories ?? 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                        servingUnit: brandedFood.servingUnit,
                        servingQty: brandedFood.servingQty,
                        servingWeight: 100
                    )
                })
            }
            
            print("🍎 Processed \(allFoods.count) total foods")
            results = allFoods
            
        } catch {
            print("🍎 Search error: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        print("🍎 Search complete. Final results count: \(results.count)")
    }
    
    // Get detailed nutrition data for a specific food item
    private func getDetailedNutrition(for foodItem: NutritionixCommonFood) async -> NutritionixFood? {
        let urlString = "https://trackapi.nutritionix.com/v2/natural/nutrients"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(appId, forHTTPHeaderField: "x-app-id")
        request.setValue(apiKey, forHTTPHeaderField: "x-app-key")
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
        
        return NutritionixFood(
            id: UUID().uuidString,
            name: foodItem.name,
            brand: "Common",
            servingUnit: foodItem.servingUnit,
            servingQty: foodItem.servingQty,
            servingWeight: 100
        )
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
            id: UUID().uuidString,
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
