import Foundation

class NutritionixService {
    static let shared = NutritionixService()
    private let baseURL = "https://trackapi.nutritionix.com/v2"
    
    private init() {}
    
    func getNutritionInfo(for foodName: String, weight: Double? = nil) async throws -> NutritionInfo {
        let endpoint = "\(baseURL)/natural/nutrients"
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "NutritionixService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(NutritionixSecrets.appId, forHTTPHeaderField: "x-app-id")
        request.setValue(NutritionixSecrets.apiKey, forHTTPHeaderField: "x-app-key")
        
        let query = weight != nil ? "\(foodName) \(Int(weight!))g" : foodName
        let requestBody: [String: Any] = [
            "query": query,
            "detailed": true,
            "line_delimited": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(NutritionixResponse.self, from: data)
        
        return createNutritionInfo(from: response)
    }
    
    private func createNutritionInfo(from response: NutritionixResponse) -> NutritionInfo {
        guard let food = response.foods?.first else {
            return NutritionInfo()
        }
        
        return NutritionInfo(
            calories: Int(food.calories ?? 0),
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            fiber: food.fiber,
            sugar: food.sugar,
            sodium: food.sodium
        )
    }
}

// Using models from NutritionixModels.swift
