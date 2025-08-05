//  Enhanced FoodSearchService.swift
//  GutCheck
//
//  Enhanced to capture comprehensive nutrition data from Nutritionix API

import Foundation

@MainActor
class FoodSearchService: ObservableObject, HasLoadingState {
    @Published var results: [NutritionixFood] = []
    
    let loadingState = LoadingStateManager()
    
    private let baseURL = "https://trackapi.nutritionix.com/v2"
    private let appId = NutritionixSecrets.appId
    private let apiKey = NutritionixSecrets.apiKey
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
        
        print("🔍 FoodSearchService: Starting enhanced search for '\(query)'")
        print("🔍 Will search both Nutritionix and OpenFoodFacts APIs")
        
        // Search both APIs concurrently
        async let nutritionixResults = searchNutritionix(query: query)
        async let openFoodFactsResults = searchOpenFoodFacts(query: query)
        
        do {
            let (nxResults, offResults) = try await (nutritionixResults, openFoodFactsResults)
            
            print("🔍 Nutritionix returned: \(nxResults.count) foods")
            print("🔍 OpenFoodFacts returned: \(offResults.count) foods")
            
            // Merge and deduplicate results, with data merging
            let mergedResults = await mergeSearchResults(nutritionixResults: nxResults, openFoodFactsResults: offResults)
            
            print("🔍 Final merged results: \(mergedResults.count) foods")
            results = mergedResults
            
        } catch {
            print("🔍 Combined search error: \(error)")
            throw error
        }
        print("🔍 Enhanced search complete. Final results count: \(results.count)")
    }
    
    // MARK: - Individual API Search Methods
    
    private func searchNutritionix(query: String) async throws -> [NutritionixFood] {
        let url = URL(string: "\(baseURL)/search/instant")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appId, forHTTPHeaderField: "x-app-id")
        request.setValue(apiKey, forHTTPHeaderField: "x-app-key")
        
        let requestBody: [String: Any] = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw NSError(domain: "NutritionixAPI", code: httpResponse.statusCode, userInfo: nil)
        }
        
        let searchResponse = try JSONDecoder().decode(NutritionixResponse.self, from: data)
        var allFoods: [NutritionixFood] = []
        
        // Add common foods with detailed nutrition
        if let commonFoods = searchResponse.common {
            for commonFood in commonFoods.prefix(5) {
                if let detailedFood = await getDetailedNutrition(for: commonFood) {
                    allFoods.append(detailedFood)
                }
            }
        }
        
        // Add branded foods with basic info
        if let brandedFoods = searchResponse.branded {
            allFoods.append(contentsOf: brandedFoods.prefix(10).map { brandedFood in
                NutritionixFood(
                    id: brandedFood.id,
                    name: brandedFood.name,
                    brand: brandedFood.brand,
                    calories: brandedFood.calories,
                    servingUnit: brandedFood.servingUnit,
                    servingQty: brandedFood.servingQty,
                    servingWeight: 100
                )
            })
        }
        
        return allFoods
    }
    
    private func searchOpenFoodFacts(query: String) async throws -> [NutritionixFood] {
        do {
            let products = try await openFoodFactsService.searchFoods(query: query, pageSize: 15)
            return products.map { openFoodFactsService.convertToNutritionixFood($0) }
        } catch {
            print("🥫 OpenFoodFacts search failed: \(error), continuing with Nutritionix only")
            return [] // Don't let OpenFoodFacts failure break the entire search
        }
    }
    
    // MARK: - Data Merging Logic
    
    private func mergeSearchResults(nutritionixResults: [NutritionixFood], openFoodFactsResults: [NutritionixFood]) async -> [NutritionixFood] {
        var mergedResults: [NutritionixFood] = []
        var processedNames: Set<String> = []
        
        // Add Nutritionix results first (generally more accurate for US foods)
        for nxFood in nutritionixResults {
            let normalizedName = normalizeProductName(nxFood.name)
            
            // Look for matching OpenFoodFacts item to merge data
            if let matchingOFF = findBestMatch(for: nxFood, in: openFoodFactsResults) {
                let mergedFood = mergeNutritionData(primary: nxFood, secondary: matchingOFF)
                mergedResults.append(mergedFood)
                print("🔗 Merged data for: '\(nxFood.name)' with OpenFoodFacts match")
            } else {
                mergedResults.append(nxFood)
            }
            
            processedNames.insert(normalizedName)
        }
        
        // Add unique OpenFoodFacts results that weren't matched
        for offFood in openFoodFactsResults {
            let normalizedName = normalizeProductName(offFood.name)
            if !processedNames.contains(normalizedName) {
                mergedResults.append(offFood)
                processedNames.insert(normalizedName)
            }
        }
        
        // Sort by relevance - branded items with more complete nutrition data first
        return mergedResults.sorted { food1, food2 in
            let score1 = calculateNutritionCompletenessScore(food1)
            let score2 = calculateNutritionCompletenessScore(food2)
            return score1 > score2
        }
    }
    
    private func findBestMatch(for primaryFood: NutritionixFood, in candidates: [NutritionixFood]) -> NutritionixFood? {
        let primaryName = normalizeProductName(primaryFood.name)
        
        return candidates.first { candidate in
            let candidateName = normalizeProductName(candidate.name)
            return calculateSimilarity(primaryName, candidateName) > 0.7
        }
    }
    
    private func mergeNutritionData(primary: NutritionixFood, secondary: NutritionixFood) -> NutritionixFood {
        return NutritionixFood(
            id: primary.id,
            name: primary.name,
            brand: primary.brand ?? secondary.brand,
            calories: primary.calories ?? secondary.calories,
            protein: primary.protein ?? secondary.protein,
            carbs: primary.carbs ?? secondary.carbs,
            fat: primary.fat ?? secondary.fat,
            fiber: primary.fiber ?? secondary.fiber,
            sugar: primary.sugar ?? secondary.sugar,
            sodium: primary.sodium ?? secondary.sodium,
            servingUnit: primary.servingUnit ?? secondary.servingUnit,
            servingQty: primary.servingQty ?? secondary.servingQty,
            servingWeight: primary.servingWeight ?? secondary.servingWeight,
            ingredients: primary.ingredients ?? secondary.ingredients,
            saturatedFat: primary.saturatedFat ?? secondary.saturatedFat,
            transFat: primary.transFat ?? secondary.transFat,
            polyunsaturatedFat: primary.polyunsaturatedFat ?? secondary.polyunsaturatedFat,
            monounsaturatedFat: primary.monounsaturatedFat ?? secondary.monounsaturatedFat,
            cholesterol: primary.cholesterol ?? secondary.cholesterol,
            potassium: primary.potassium ?? secondary.potassium,
            calcium: primary.calcium ?? secondary.calcium,
            iron: primary.iron ?? secondary.iron,
            magnesium: primary.magnesium ?? secondary.magnesium,
            phosphorus: primary.phosphorus ?? secondary.phosphorus,
            zinc: primary.zinc ?? secondary.zinc,
            copper: primary.copper ?? secondary.copper,
            manganese: primary.manganese ?? secondary.manganese,
            selenium: primary.selenium ?? secondary.selenium,
            vitaminA: primary.vitaminA ?? secondary.vitaminA,
            vitaminC: primary.vitaminC ?? secondary.vitaminC,
            vitaminD: primary.vitaminD ?? secondary.vitaminD,
            vitaminE: primary.vitaminE ?? secondary.vitaminE,
            vitaminK: primary.vitaminK ?? secondary.vitaminK,
            thiamin: primary.thiamin ?? secondary.thiamin,
            riboflavin: primary.riboflavin ?? secondary.riboflavin,
            niacin: primary.niacin ?? secondary.niacin,
            vitaminB6: primary.vitaminB6 ?? secondary.vitaminB6,
            folate: primary.folate ?? secondary.folate,
            vitaminB12: primary.vitaminB12 ?? secondary.vitaminB12,
            biotin: primary.biotin ?? secondary.biotin,
            pantothenicAcid: primary.pantothenicAcid ?? secondary.pantothenicAcid
        )
    }
    
    // MARK: - Helper Methods
    
    private func normalizeProductName(_ name: String) -> String {
        return name.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        let words1 = Set(str1.components(separatedBy: " "))
        let words2 = Set(str2.components(separatedBy: " "))
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        return union.isEmpty ? 0 : Double(intersection.count) / Double(union.count)
    }
    
    private func calculateNutritionCompletenessScore(_ food: NutritionixFood) -> Int {
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
