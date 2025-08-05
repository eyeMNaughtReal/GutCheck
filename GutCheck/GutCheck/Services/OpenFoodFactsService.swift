import Foundation

class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    private let baseURL = "https://world.openfoodfacts.org"
    
    private init() {}
    
    // Search for foods in OpenFoodFacts database
    func searchFoods(query: String, page: Int = 1, pageSize: Int = 20) async throws -> [OpenFoodFactsProduct] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&page=\(page)&page_size=\(pageSize)&json=1"
        
        guard let url = URL(string: urlString) else {
            throw OpenFoodFactsError.invalidURL
        }
        
        print("🥫 OpenFoodFacts: Searching for '\(query)' at URL: \(urlString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🥫 OpenFoodFacts HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    throw OpenFoodFactsError.httpError(httpResponse.statusCode)
                }
            }
            
            let searchResponse = try JSONDecoder().decode(OpenFoodFactsSearchResponse.self, from: data)
            print("🥫 OpenFoodFacts: Found \(searchResponse.products.count) products")
            
            // Filter out products without names or basic nutrition data
            let validProducts = searchResponse.products.filter { product in
                product.productName != nil && 
                !product.productName!.isEmpty &&
                product.nutriments?.energyKcal100g != nil
            }
            
            print("🥫 OpenFoodFacts: \(validProducts.count) valid products after filtering")
            return validProducts
            
        } catch let decodingError as DecodingError {
            print("🥫 OpenFoodFacts JSON decoding error: \(decodingError)")
            throw OpenFoodFactsError.decodingError(decodingError)
        } catch {
            print("🥫 OpenFoodFacts search error: \(error)")
            throw OpenFoodFactsError.networkError(error)
        }
    }
    
    // Get detailed product information by barcode
    func getProduct(by barcode: String) async throws -> OpenFoodFactsProduct? {
        let urlString = "\(baseURL)/api/v0/product/\(barcode).json"
        
        guard let url = URL(string: urlString) else {
            throw OpenFoodFactsError.invalidURL
        }
        
        print("🥫 OpenFoodFacts: Getting product by barcode \(barcode)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    return nil // Product not found
                } else if httpResponse.statusCode != 200 {
                    throw OpenFoodFactsError.httpError(httpResponse.statusCode)
                }
            }
            
            let productResponse = try JSONDecoder().decode(OpenFoodFactsProductResponse.self, from: data)
            return productResponse.status == 1 ? productResponse.product : nil
            
        } catch {
            throw OpenFoodFactsError.networkError(error)
        }
    }
    
    // Convert OpenFoodFacts product to app's NutritionixFood format for consistency
    func convertToNutritionixFood(_ product: OpenFoodFactsProduct) -> NutritionixFood {
        let nutriments = product.nutriments
        
        // Parse serving size (OpenFoodFacts uses various formats)
        var servingQty: Double = 100.0 // Default to 100g
        var servingUnit: String = "g"
        
        if let servingSize = product.servingSize {
            let (qty, unit) = parseServingSize(servingSize)
            servingQty = qty
            servingUnit = unit
        }
        
        // Convert per-100g values to per-serving values
        let multiplier = servingQty / 100.0
        
        // Pre-calculate nutrition values to help compiler
        let brandName = product.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines)
        let productNameSafe = product.productName ?? "Unknown Product"
        
        // Basic macronutrients
        let calories = nutriments?.energyKcal100g.map { $0 * multiplier }
        let protein = nutriments?.proteins100g.map { $0 * multiplier }
        let carbs = nutriments?.carbohydrates100g.map { $0 * multiplier }
        let fat = nutriments?.fat100g.map { $0 * multiplier }
        let fiber = nutriments?.fiber100g.map { $0 * multiplier }
        let sugar = nutriments?.sugars100g.map { $0 * multiplier }
        let sodium = nutriments?.sodium100g.map { $0 * multiplier }
        let saturatedFat = nutriments?.saturatedFat100g.map { $0 * multiplier }
        
        // Minerals
        let potassium = nutriments?.potassium100g.map { $0 * multiplier }
        let calcium = nutriments?.calcium100g.map { $0 * multiplier }
        let iron = nutriments?.iron100g.map { $0 * multiplier }
        let magnesium = nutriments?.magnesium100g.map { $0 * multiplier }
        let phosphorus = nutriments?.phosphorus100g.map { $0 * multiplier }
        let zinc = nutriments?.zinc100g.map { $0 * multiplier }
        
        // Vitamins
        let vitaminA = nutriments?.vitaminA100g.map { $0 * multiplier }
        let vitaminC = nutriments?.vitaminC100g.map { $0 * multiplier }
        let vitaminD = nutriments?.vitaminD100g.map { $0 * multiplier }
        let vitaminE = nutriments?.vitaminE100g.map { $0 * multiplier }
        let vitaminK = nutriments?.vitaminK100g.map { $0 * multiplier }
        let thiamin = nutriments?.vitaminB1100g.map { $0 * multiplier }
        let riboflavin = nutriments?.vitaminB2100g.map { $0 * multiplier }
        let niacin = nutriments?.vitaminB3100g.map { $0 * multiplier }
        let vitaminB6 = nutriments?.vitaminB6100g.map { $0 * multiplier }
        let vitaminB12 = nutriments?.vitaminB12100g.map { $0 * multiplier }
        let folate = nutriments?.folates100g.map { $0 * multiplier }
        
        return NutritionixFood(
            id: product.id,
            name: productNameSafe,
            brand: brandName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servingUnit: servingUnit,
            servingQty: servingQty,
            servingWeight: servingQty,
            ingredients: product.ingredientsText,
            saturatedFat: saturatedFat,
            potassium: potassium,
            calcium: calcium,
            iron: iron,
            magnesium: magnesium,
            phosphorus: phosphorus,
            zinc: zinc,
            vitaminA: vitaminA,
            vitaminC: vitaminC,
            vitaminD: vitaminD,
            vitaminE: vitaminE,
            vitaminK: vitaminK,
            thiamin: thiamin,
            riboflavin: riboflavin,
            niacin: niacin,
            vitaminB6: vitaminB6,
            folate: folate,
            vitaminB12: vitaminB12
        )
    }
    
    // Helper method to parse serving size strings like "100g", "1 cup", "30 ml"
    private func parseServingSize(_ servingSize: String) -> (quantity: Double, unit: String) {
        let trimmed = servingSize.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to extract number and unit
        let pattern = #"(\d+(?:\.\d+)?)\s*([a-zA-Z]+)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {
            
            if let quantityRange = Range(match.range(at: 1), in: trimmed),
               let unitRange = Range(match.range(at: 2), in: trimmed),
               let quantity = Double(String(trimmed[quantityRange])) {
                let unit = String(trimmed[unitRange]).lowercased()
                return (quantity, unit)
            }
        }
        
        // Fallback: assume 100g if we can't parse
        return (100.0, "g")
    }
    
    // Helper method to parse ingredients text
    private func parseIngredientsText(_ ingredientsText: String?) -> String? {
        guard let text = ingredientsText, !text.isEmpty else { return nil }
        
        // Clean up the ingredients text - remove percentages and other formatting
        let cleaned = text
            .replacingOccurrences(of: #"\([^)]*\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\*[^*]*\*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned.isEmpty ? nil : cleaned
    }
}

// MARK: - Errors

enum OpenFoodFactsError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case decodingError(DecodingError)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for OpenFoodFacts API"
        case .httpError(let code):
            return "HTTP error \(code) from OpenFoodFacts API"
        case .decodingError(let error):
            return "Failed to decode OpenFoodFacts response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Product Response (for barcode lookup)

private struct OpenFoodFactsProductResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}