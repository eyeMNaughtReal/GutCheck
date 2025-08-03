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
    private let appId = NutritionixSecrets.appId
    private let apiKey = NutritionixSecrets.apiKey

    func searchFoods(query: String) async {
        results = []
        isLoading = true
        errorMessage = nil
        
        print("🍎 FoodSearchService: Starting search for '\(query)'")
        print("🍎 Search executing in async context")
        
        let url = URL(string: "\(baseURL)/search/instant")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appId, forHTTPHeaderField: "x-app-id")
        request.setValue(apiKey, forHTTPHeaderField: "x-app-key")
        
        print("🍎 API URL: \(url)")
        print("🍎 API Headers: x-app-id=\(appId), x-app-key=\(String(apiKey.prefix(8)))...")
        
        let requestBody: [String: Any] = [
            "query": query
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
            
            // Process results with detailed nutrition data
            var allFoods: [NutritionixFood] = []
            
            // Add common foods first (they're usually more accurate)
            if let commonFoods = searchResponse.common {
                for commonFood in commonFoods.prefix(5) { // Limit to first 5 to avoid too many API calls
                    if let detailedFood = await getDetailedNutrition(for: commonFood) {
                        allFoods.append(detailedFood)
                    }
                }
            }
            
            // Add branded foods with basic info (some nutrition data already included)
            if let brandedFoods = searchResponse.branded {
                allFoods.append(contentsOf: brandedFoods.prefix(10).map { brandedFood in
                    NutritionixFood(
                        id: brandedFood.id,
                        name: brandedFood.name,
                        brand: brandedFood.brand,
                        calories: brandedFood.calories ?? 0,
                        protein: nil, // Branded foods might not have all details
                        carbs: nil,
                        fat: nil,
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
        
        print("🍎 Getting detailed nutrition for: \(foodItem.name)")
        
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
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🍎 Detailed nutrition HTTP Status: \(httpResponse.statusCode)")
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let foods = json["foods"] as? [[String: Any]],
               let firstFood = foods.first {
                
                print("🍎 Got detailed nutrition data for: \(foodItem.name)")
                return createDetailedNutritionixFood(from: firstFood, originalItem: foodItem)
            } else {
                print("🍎 No detailed nutrition data found for: \(foodItem.name)")
            }
        } catch {
            print("🍎 Error getting detailed nutrition for \(foodItem.name): \(error)")
        }
        
        // Return basic food info if detailed lookup fails
        return NutritionixFood(
            id: UUID().uuidString,
            name: foodItem.name,
            brand: "Common",
            calories: nil,
            servingUnit: foodItem.servingUnit,
            servingQty: foodItem.servingQty,
            servingWeight: 100
        )
    }
    
    private func createDetailedNutritionixFood(from detailedData: [String: Any], originalItem: NutritionixCommonFood) -> NutritionixFood {
        // Extract nutrition data
        let name = detailedData["food_name"] as? String ?? originalItem.name
        let brand = detailedData["brand_name"] as? String ?? "Common"
        
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
        let servingQty = detailedData["serving_qty"] as? Double ?? originalItem.servingQty
        let servingUnit = detailedData["serving_unit"] as? String ?? originalItem.servingUnit
        let servingWeight = detailedData["serving_weight_grams"] as? Double
        
        print("🍎 Created detailed nutrition: \(name) - Cal: \(calories ?? 0), Protein: \(protein ?? 0)g, Carbs: \(carbs ?? 0)g, Fat: \(fat ?? 0)g")

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
            calcium: calcium,
            iron: iron,
            vitaminA: vitaminA,
            vitaminC: vitaminC
        )
    }
}
