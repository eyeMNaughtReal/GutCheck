//  Enhanced FoodSearchService.swift
//  GutCheck
//
//  Enhanced to capture comprehensive nutrition data from Nutritionix API

import Foundation

struct NutritionixFood: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String?
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let servingUnit: String?
    let servingQty: Double?
    let serving_weight_grams: Double?
    
    // Store additional nutrition data as codable strings
    let saturatedFat: Double?
    let cholesterol: Double?
    let potassium: Double?
    let vitaminA: Double?
    let vitaminC: Double?
    let calcium: Double?
    let iron: Double?
    
    init(id: String, name: String, brand: String? = nil, calories: Double? = nil,
         protein: Double? = nil, carbs: Double? = nil, fat: Double? = nil,
         fiber: Double? = nil, sugar: Double? = nil, sodium: Double? = nil,
         servingUnit: String? = nil, servingQty: Double? = nil,
         serving_weight_grams: Double? = nil, saturatedFat: Double? = nil,
         cholesterol: Double? = nil, potassium: Double? = nil,
         vitaminA: Double? = nil, vitaminC: Double? = nil,
         calcium: Double? = nil, iron: Double? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.servingUnit = servingUnit
        self.servingQty = servingQty
        self.serving_weight_grams = serving_weight_grams
        self.saturatedFat = saturatedFat
        self.cholesterol = cholesterol
        self.potassium = potassium
        self.vitaminA = vitaminA
        self.vitaminC = vitaminC
        self.calcium = calcium
        self.iron = iron
    }
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
            
            // Get detailed nutrition for each food item
            var detailedFoods: [NutritionixFood] = []
            
            // Process common foods (these usually have less detailed nutrition)
            for commonFood in decoded.common.prefix(3) { // Limit to avoid too many API calls
                if let detailedFood = await getDetailedNutrition(for: commonFood) {
                    detailedFoods.append(detailedFood)
                } else {
                    detailedFoods.append(commonFood.toNutritionixFood())
                }
            }
            
            // Process branded foods (these usually have more complete nutrition)
            for brandedFood in decoded.branded.prefix(5) { // Show more branded items
                detailedFoods.append(brandedFood.toNutritionixFood())
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
    private func getDetailedNutrition(for foodItem: NutritionixFoodItem) async -> NutritionixFood? {
        let urlString = "https://trackapi.nutritionix.com/v2/natural/nutrients"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Secrets.nutritionixAppId, forHTTPHeaderField: "x-app-id")
        request.setValue(Secrets.nutritionixApiKey, forHTTPHeaderField: "x-app-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "query": foodItem.food_name,
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
        
        return nil
    }
    
    private func createDetailedNutritionixFood(from detailedData: [String: Any], originalItem: NutritionixFoodItem) -> NutritionixFood {
        // Extract comprehensive nutrition data
        let id = originalItem.nix_item_id ?? UUID().uuidString
        let name = detailedData["food_name"] as? String ?? originalItem.food_name
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
            id: id,
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
            serving_weight_grams: servingWeight,
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
    let nf_dietary_fiber: Double?
    let nf_sugars: Double?
    let nf_sodium: Double?
    let serving_unit: String?
    let serving_qty: Double?
    let nf_serving_weight_grams: Double?

    func toNutritionixFood() -> NutritionixFood {
        NutritionixFood(
            id: nix_item_id ?? UUID().uuidString,
            name: food_name,
            brand: brand_name,
            calories: nf_calories,
            protein: nf_protein,
            carbs: nf_total_carbohydrate,
            fat: nf_total_fat,
            fiber: nf_dietary_fiber,
            sugar: nf_sugars,
            sodium: nf_sodium,
            servingUnit: serving_unit,
            servingQty: serving_qty,
            serving_weight_grams: nf_serving_weight_grams
        )
    }
}
