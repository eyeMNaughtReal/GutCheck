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
    
    func getDetailedNutritionInfo(for foodName: String, weight: Double? = nil) async throws -> (NutritionInfo, [String: String]) {
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
        
        let nutritionInfo = createNutritionInfo(from: response)
        let nutritionDetails = extractDetailedNutritionData(from: response)
        
        return (nutritionInfo, nutritionDetails)
    }
    
    private func extractDetailedNutritionData(from response: NutritionixResponse) -> [String: String] {
        guard let food = response.foods?.first else {
            return [:]
        }
        
        var details: [String: String] = [:]
        
        // Basic info
        if let brand = food.brand { details["brand"] = brand }
        if let ingredients = food.ingredients { details["ingredients"] = ingredients }
        
        // Additional macronutrients
        if let saturatedFat = food.saturatedFat { details["saturated_fat"] = String(saturatedFat) }
        if let transFat = food.transFat { details["trans_fat"] = String(transFat) }
        if let polyunsaturatedFat = food.polyunsaturatedFat { details["polyunsaturated_fat"] = String(polyunsaturatedFat) }
        if let monounsaturatedFat = food.monounsaturatedFat { details["monounsaturated_fat"] = String(monounsaturatedFat) }
        if let cholesterol = food.cholesterol { details["cholesterol"] = String(cholesterol) }
        
        // Minerals
        if let potassium = food.potassium { details["potassium"] = String(potassium) }
        if let calcium = food.calcium { details["calcium"] = String(calcium) }
        if let iron = food.iron { details["iron"] = String(iron) }
        if let magnesium = food.magnesium { details["magnesium"] = String(magnesium) }
        if let phosphorus = food.phosphorus { details["phosphorus"] = String(phosphorus) }
        if let zinc = food.zinc { details["zinc"] = String(zinc) }
        if let copper = food.copper { details["copper"] = String(copper) }
        if let manganese = food.manganese { details["manganese"] = String(manganese) }
        if let selenium = food.selenium { details["selenium"] = String(selenium) }
        
        // Vitamins
        if let vitaminA = food.vitaminA { details["vitamin_a"] = String(vitaminA) }
        if let vitaminC = food.vitaminC { details["vitamin_c"] = String(vitaminC) }
        if let vitaminD = food.vitaminD { details["vitamin_d"] = String(vitaminD) }
        if let vitaminE = food.vitaminE { details["vitamin_e"] = String(vitaminE) }
        if let vitaminK = food.vitaminK { details["vitamin_k"] = String(vitaminK) }
        if let thiamin = food.thiamin { details["thiamin"] = String(thiamin) }
        if let riboflavin = food.riboflavin { details["riboflavin"] = String(riboflavin) }
        if let niacin = food.niacin { details["niacin"] = String(niacin) }
        if let vitaminB6 = food.vitaminB6 { details["vitamin_b6"] = String(vitaminB6) }
        if let folate = food.folate { details["folate"] = String(folate) }
        if let vitaminB12 = food.vitaminB12 { details["vitamin_b12"] = String(vitaminB12) }
        if let biotin = food.biotin { details["biotin"] = String(biotin) }
        if let pantothenicAcid = food.pantothenicAcid { details["pantothenic_acid"] = String(pantothenicAcid) }
        
        // Essential amino acids
        if let histidine = food.histidine { details["histidine"] = String(histidine) }
        if let isoleucine = food.isoleucine { details["isoleucine"] = String(isoleucine) }
        if let leucine = food.leucine { details["leucine"] = String(leucine) }
        if let lysine = food.lysine { details["lysine"] = String(lysine) }
        if let methionine = food.methionine { details["methionine"] = String(methionine) }
        if let phenylalanine = food.phenylalanine { details["phenylalanine"] = String(phenylalanine) }
        if let threonine = food.threonine { details["threonine"] = String(threonine) }
        if let tryptophan = food.tryptophan { details["tryptophan"] = String(tryptophan) }
        if let valine = food.valine { details["valine"] = String(valine) }
        
        // Non-essential amino acids
        if let alanine = food.alanine { details["alanine"] = String(alanine) }
        if let arginine = food.arginine { details["arginine"] = String(arginine) }
        if let asparticAcid = food.asparticAcid { details["aspartic_acid"] = String(asparticAcid) }
        if let cysteine = food.cysteine { details["cysteine"] = String(cysteine) }
        if let glutamicAcid = food.glutamicAcid { details["glutamic_acid"] = String(glutamicAcid) }
        if let glycine = food.glycine { details["glycine"] = String(glycine) }
        if let proline = food.proline { details["proline"] = String(proline) }
        if let serine = food.serine { details["serine"] = String(serine) }
        if let tyrosine = food.tyrosine { details["tyrosine"] = String(tyrosine) }
        
        // Other nutrients
        if let water = food.water { details["water"] = String(water) }
        if let ash = food.ash { details["ash"] = String(ash) }
        if let caffeine = food.caffeine { details["caffeine"] = String(caffeine) }
        if let theobromine = food.theobromine { details["theobromine"] = String(theobromine) }
        
        return details
    }
}

// Using models from NutritionixModels.swift
