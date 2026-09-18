import Foundation

class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    private let baseURL = "https://world.openfoodfacts.org"
    private let rateLimiter = RateLimitingService.shared

    private init() {}
    
    // Search for foods in OpenFoodFacts database
    func searchFoods(query: String, page: Int = 1, pageSize: Int = 20) async throws -> [OpenFoodFactsProduct] {
        try rateLimiter.checkLimit(for: .foodSearchOpenFoodFacts)

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        // `lc=en` asks OpenFoodFacts for the English field variants where a
        // record has them. Without it the API returns each product in its own
        // language, which is how a Big Mac came back with a French ingredient
        // list the allergen matcher could not read.
        let urlString = "\(baseURL)/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&page=\(page)&page_size=\(pageSize)&lc=en&json=1"
        
        guard let url = URL(string: urlString) else {
            throw OpenFoodFactsError.invalidURL
        }
        
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    throw OpenFoodFactsError.httpError(httpResponse.statusCode)
                }
            }
            
            let searchResponse = try JSONDecoder().decode(OpenFoodFactsSearchResponse.self, from: data)
            
            // Filter out products without names or basic nutrition data
            let validProducts = searchResponse.products.filter { product in
                product.productName != nil && 
                !product.productName!.isEmpty &&
                product.nutriments?.energyKcal100g != nil
            }
            
            return validProducts
            
        } catch let decodingError as DecodingError {
            throw OpenFoodFactsError.decodingError(decodingError)
        } catch {
            throw OpenFoodFactsError.networkError(error)
        }
    }
    
    // Get detailed product information by barcode
    func getProduct(by barcode: String) async throws -> OpenFoodFactsProduct? {
        try rateLimiter.checkLimit(for: .foodSearchOpenFoodFacts)

        let urlString = "\(baseURL)/api/v0/product/\(barcode).json?lc=en"
        
        guard let url = URL(string: urlString) else {
            throw OpenFoodFactsError.invalidURL
        }
        
        
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
    
    // Convert OpenFoodFacts product to app's FoodSearchResult format
    func convertToFoodSearchResult(_ product: OpenFoodFactsProduct) -> FoodSearchResult {
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

        let servings = servingOptions(
            for: product,
            baseGrams: servingQty,
            baseUnit: servingUnit
        )
        
        // Basic macronutrients
        let calories = nutriments?.energyKcal100g.map { $0 * multiplier }
        let protein = nutriments?.proteins100g.map { $0 * multiplier }
        let carbs = nutriments?.carbohydrates100g.map { $0 * multiplier }
        let fat = nutriments?.fat100g.map { $0 * multiplier }
        let fiber = nutriments?.fiber100g.map { $0 * multiplier }
        let sugar = nutriments?.sugars100g.map { $0 * multiplier }
        let sodium = nutriments?.sodium100g.map { $0 * multiplier }
        let saturatedFat = nutriments?.saturatedFat100g.map { $0 * multiplier }
        let transFat = nutriments?.transFat100g.map { $0 * multiplier }
        let cholesterol = nutriments?.cholesterol100g.map { $0 * multiplier }
        
        // Minerals
        let potassium = nutriments?.potassium100g.map { $0 * multiplier }
        let calcium = nutriments?.calcium100g.map { $0 * multiplier }
        let iron = nutriments?.iron100g.map { $0 * multiplier }
        let magnesium = nutriments?.magnesium100g.map { $0 * multiplier }
        let phosphorus = nutriments?.phosphorus100g.map { $0 * multiplier }
        let zinc = nutriments?.zinc100g.map { $0 * multiplier }
        let copper = nutriments?.copper100g.map { $0 * multiplier }
        let manganese = nutriments?.manganese100g.map { $0 * multiplier }
        let selenium = nutriments?.selenium100g.map { $0 * multiplier }
        
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
        let biotin = nutriments?.biotin100g.map { $0 * multiplier }
        let pantothenicAcid = nutriments?.pantothenicAcid100g.map { $0 * multiplier }
        
        return FoodSearchResult(
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
            servingOptions: servings.options,
            defaultServing: servings.defaultOption,
            ingredients: product.bestIngredientsText,
            declaredAllergens: product.normalizedAllergens,
            saturatedFat: saturatedFat,
            transFat: transFat,
            cholesterol: cholesterol,
            potassium: potassium,
            calcium: calcium,
            iron: iron,
            magnesium: magnesium,
            phosphorus: phosphorus,
            zinc: zinc,
            copper: copper,
            manganese: manganese,
            selenium: selenium,
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
            vitaminB12: vitaminB12,
            biotin: biotin,
            pantothenicAcid: pantothenicAcid
        )
    }
    
    // MARK: - Serving sizes

    /// Heaviest whole product still treated as one portion when the record
    /// declares no serving size.
    ///
    /// A judgement call, and the reason it exists: fast-food records routinely
    /// carry only `product_quantity` (a Big Mac is 220 g with no serving size),
    /// and defaulting those to 100 g is the bug in #359. Above this a package
    /// is far more likely to be a jar or a bag that nobody eats in one sitting,
    /// where guessing "the whole thing" would be the larger error. The picker
    /// still offers the whole package either way.
    private static let maxSingleServingPackageGrams: Double = 500

    /// Reads the portions an OpenFoodFacts record offers.
    ///
    /// - Parameter baseGrams: the weight the caller has already scaled this
    ///   product's nutrition to, offered as the fallback choice.
    private func servingOptions(
        for product: OpenFoodFactsProduct,
        baseGrams: Double,
        baseUnit: String
    ) -> (options: [ServingOption], defaultOption: ServingOption?) {

        var options: [ServingOption] = []

        // The record's declared serving, kept as written ("30 g", "1 biscuit
        // (25 g)") so the user sees the source's own words.
        let declaredServing = product.servingSize
            .flatMap { text -> ServingOption? in
                guard let grams = Self.weightInGrams(from: text) else { return nil }
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                // A record that writes its serving size as a bare "219" gets a
                // unit added; keeping it verbatim renders as "219 · 219 g".
                return trimmed.contains(where: \.isLetter)
                    ? ServingOption(label: trimmed, gramWeight: grams)
                    : ServingOption.grams(grams)
            }
        if let declaredServing { options.append(declaredServing) }

        let wholePackage = product.productWeightInGrams
            .flatMap { ServingOption(label: "Whole package", gramWeight: $0) }
        if let wholePackage { options.append(wholePackage) }

        // The baseline the nutrition was scaled to — usually 100 g, and always
        // available as an escape hatch. Labelled in the source's own unit so a
        // drink measured in millilitres is not silently relabelled as grams.
        let baselineWeight = baseGrams > 0 ? baseGrams : 100
        let baseline = ServingOption(
            label: "\(ServingOption.formattedWeight(baselineWeight)) \(baseUnit)",
            gramWeight: baselineWeight
        )
        if let baseline { options.append(baseline) }

        let normalized = ServingSizeResolver.normalize(options)

        // Declared serving first — it is the source stating what one portion
        // is. Otherwise the whole package, but only when it is small enough to
        // plausibly be one. Failing both, the baseline, so the picker always
        // shows the portion the figures actually describe.
        let defaultOption: ServingOption? = declaredServing
            ?? wholePackage.flatMap { $0.gramWeight <= Self.maxSingleServingPackageGrams ? $0 : nil }
            ?? baseline

        return (normalized, defaultOption)
    }

    /// Grams from a free-text weight, or `nil` when the text names a unit that
    /// is not a weight.
    ///
    /// A bare number is read as grams: OpenFoodFacts records a serving size of
    /// `"219"` for the European Big Mac, and that is what the contributor meant.
    /// Volumes are rejected rather than assumed to weigh the same — a serving
    /// option prints its gram weight, and printing one for millilitres would
    /// assert a density the record never gave.
    static func weightInGrams(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^(\d+(?:[.,]\d+)?)\s*([a-zA-Z]*)"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let numberRange = Range(match.range(at: 1), in: trimmed),
              let unitRange = Range(match.range(at: 2), in: trimmed),
              let value = Double(String(trimmed[numberRange]).replacingOccurrences(of: ",", with: ".")),
              value > 0
        else { return nil }

        let unit = String(trimmed[unitRange]).lowercased()
        let gramUnits: Set<String> = ["", "g", "gr", "gram", "grams", "gramme", "grammes"]
        return gramUnits.contains(unit) ? value : nil
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
