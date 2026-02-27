//  USDAFoodService.swift
//  GutCheck
//
//  Food search using the USDA FoodData Central API.
//  API key is stored in Secrets.swift (excluded from version control).

import Foundation

class USDAFoodService {
    static let shared = USDAFoodService()
    private let baseURL = "https://api.nal.usda.gov/fdc/v1"

    private var apiKey: String { Secrets.usdaAPIKey }

    private init() {}

    // MARK: - Search

    func searchFoods(query: String, pageSize: Int = 25) async throws -> [USDAFood] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/foods/search?query=\(encodedQuery)&pageSize=\(pageSize)&api_key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw USDAFoodError.invalidURL
        }

        print("🥗 USDA: Searching for '\(query)'")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                print("🥗 USDA HTTP Status: \(httpResponse.statusCode)")
                switch httpResponse.statusCode {
                case 200: break
                case 403: throw USDAFoodError.invalidAPIKey
                default: throw USDAFoodError.httpError(httpResponse.statusCode)
                }
            }

            let searchResponse = try JSONDecoder().decode(USDASearchResponse.self, from: data)
            print("🥗 USDA: Found \(searchResponse.foods.count) foods")
            return searchResponse.foods

        } catch let decodingError as DecodingError {
            print("🥗 USDA JSON decoding error: \(decodingError)")
            throw USDAFoodError.decodingError(decodingError)
        } catch let usdaError as USDAFoodError {
            throw usdaError
        } catch {
            print("🥗 USDA search error: \(error)")
            throw USDAFoodError.networkError(error)
        }
    }

    // MARK: - Conversion

    func convertToFoodSearchResult(_ food: USDAFood) -> FoodSearchResult {
        // Build nutrient lookup by ID for O(1) access
        var nutrients: [Int: Double] = [:]
        for nutrient in food.foodNutrients {
            nutrients[nutrient.nutrientId] = nutrient.value
        }

        // USDA nutrient values are per 100g. Scale to the food's serving size.
        let servingQty: Double
        let servingUnit: String

        if let size = food.servingSize, let unit = food.servingSizeUnit, size > 0 {
            servingQty = size
            servingUnit = unit.lowercased()
        } else {
            servingQty = 100.0
            servingUnit = "g"
        }

        let multiplier = servingQty / 100.0

        // Helpers that apply unit conversions to match OpenFoodFacts convention (grams per serving)
        func grams(_ id: Int) -> Double? {
            nutrients[id].map { $0 * multiplier }           // already g/100g
        }
        func fromMg(_ id: Int) -> Double? {
            nutrients[id].map { ($0 / 1_000.0) * multiplier }     // mg/100g → g/serving
        }
        func fromMcg(_ id: Int) -> Double? {
            nutrients[id].map { ($0 / 1_000_000.0) * multiplier } // mcg/100g → g/serving
        }

        let name = food.description
            .capitalized
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return FoodSearchResult(
            id: String(food.fdcId),
            name: name,
            brand: food.brandOwner ?? food.brandName,
            // Macronutrients (g/100g)
            calories: grams(1008),
            protein: grams(1003),
            carbs: grams(1005),
            fat: grams(1004),
            fiber: grams(1079),
            sugar: grams(2000),
            // Sodium (mg → g to match OpenFoodFacts)
            sodium: fromMg(1093),
            servingUnit: servingUnit,
            servingQty: servingQty,
            servingWeight: servingQty,
            ingredients: food.ingredients,
            // Additional fats (g/100g)
            saturatedFat: grams(1258),
            transFat: grams(1257),
            polyunsaturatedFat: grams(1292),
            monounsaturatedFat: grams(1293),
            // Cholesterol (mg → g)
            cholesterol: fromMg(1253),
            // Minerals (mg → g)
            potassium: fromMg(1092),
            calcium: fromMg(1087),
            iron: fromMg(1089),
            magnesium: fromMg(1090),
            phosphorus: fromMg(1091),
            zinc: fromMg(1095),
            copper: fromMg(1098),
            manganese: fromMg(1101),
            // Selenium (mcg → g)
            selenium: fromMcg(1103),
            // Vitamins
            vitaminA: fromMcg(1106),    // mcg RAE → g
            vitaminC: fromMg(1162),     // mg → g
            vitaminD: fromMcg(1114),    // mcg → g
            vitaminE: fromMg(1109),     // mg → g
            vitaminK: fromMcg(1185),    // mcg → g
            thiamin: fromMg(1165),
            riboflavin: fromMg(1166),
            niacin: fromMg(1167),
            vitaminB6: fromMg(1175),
            folate: fromMcg(1177),      // mcg → g
            vitaminB12: fromMcg(1178),  // mcg → g
            biotin: fromMcg(1176),      // mcg → g
            pantothenicAcid: fromMg(1170),
            // Essential amino acids (g/100g)
            histidine: grams(1221),
            isoleucine: grams(1212),
            leucine: grams(1213),
            lysine: grams(1214),
            methionine: grams(1215),
            phenylalanine: grams(1217),
            threonine: grams(1211),
            tryptophan: grams(1210),
            valine: grams(1219),
            // Non-essential amino acids (g/100g)
            alanine: grams(1222),
            arginine: grams(1220),
            asparticAcid: grams(1223),
            cysteine: grams(1216),
            glutamicAcid: grams(1224),
            glycine: grams(1225),
            proline: grams(1226),
            serine: grams(1227),
            tyrosine: grams(1218),
            // Other
            water: grams(1051),
            ash: grams(1007),
            caffeine: fromMg(1057),
            theobromine: fromMg(1058)
        )
    }
}

// MARK: - Errors

enum USDAFoodError: LocalizedError {
    case invalidURL
    case invalidAPIKey
    case httpError(Int)
    case decodingError(DecodingError)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for USDA FoodData Central API"
        case .invalidAPIKey:
            return "USDA API key is invalid or unauthorized"
        case .httpError(let code):
            return "HTTP error \(code) from USDA FoodData Central API"
        case .decodingError(let error):
            return "Failed to decode USDA response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Response Models

private struct USDASearchResponse: Codable {
    let totalHits: Int
    let currentPage: Int
    let totalPages: Int
    let foods: [USDAFood]
}

struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let dataType: String?
    let brandOwner: String?
    let brandName: String?
    let ingredients: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let householdServingFullText: String?
    let foodNutrients: [USDAFoodNutrient]
}

struct USDAFoodNutrient: Codable {
    let nutrientId: Int
    let nutrientName: String?
    let unitName: String?
    let value: Double
}
