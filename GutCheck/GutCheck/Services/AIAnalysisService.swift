import Foundation
import CoreML

/// Service for handling AI/ML analysis of food and health data
class AIAnalysisService {
    static let shared = AIAnalysisService()
    
    private init() {}
    
    /// Analyzes food items to provide nutritional insights
    /// - Parameter foodItems: Array of food items to analyze
    /// - Returns: Analysis results including nutritional insights
    func analyzeFoodItems(_ foodItems: [FoodItem]) async throws -> AIAnalysisResult {
        // TODO: Implement food analysis using Core ML
        return AIAnalysisResult(
            insights: ["Placeholder insight"],
            nutritionalScore: 0.0,
            recommendations: ["Placeholder recommendation"]
        )
    }
    
    /// Analyzes health patterns over time
    /// - Parameter timeRange: The date range to analyze
    /// - Returns: Health pattern analysis results
    func analyzeHealthPatterns(timeRange: DateInterval) async throws -> AIAnalysisResult {
        // TODO: Implement health pattern analysis
        return AIAnalysisResult(
            insights: ["Placeholder health insight"],
            nutritionalScore: 0.0,
            recommendations: ["Placeholder health recommendation"]
        )
    }
    
    // MARK: - Branded Food Nutrition Estimation
    
    func estimateNutritionForBrandedFood(
        name: String,
        brand: String,
        knownCalories: Double,
        servingSize: String
    ) async throws -> NutritionEstimate {
        
        print("🤖 AI estimating nutrition for: \(brand) \(name) (\(knownCalories) calories)")
        
        // Analyze the food name and brand to categorize it
        let category = categorizeBrandedFood(name: name, brand: brand)
        let baseNutrition = getBaseNutritionForCategory(category, calories: knownCalories)
        
        // Apply brand-specific and product-specific adjustments
        let adjustedNutrition = applyBrandedFoodAdjustments(
            base: baseNutrition,
            name: name,
            brand: brand,
            category: category,
            knownCalories: knownCalories
        )
        
        let confidence = calculateBrandedFoodConfidence(category: category, brand: brand)
        
        return NutritionEstimate(
            calories: knownCalories, // Keep the known value
            protein: adjustedNutrition.protein,
            carbs: adjustedNutrition.carbs,
            fat: adjustedNutrition.fat,
            fiber: adjustedNutrition.fiber,
            sugar: adjustedNutrition.sugar,
            sodium: adjustedNutrition.sodium,
            confidence: confidence
        )
    }
    
    private func categorizeBrandedFood(name: String, brand: String) -> BrandedFoodCategory {
        let nameAndBrand = "\(brand) \(name)".lowercased()
        
        // Coffee beverages
        if nameAndBrand.contains("coffee") || nameAndBrand.contains("latte") || 
           nameAndBrand.contains("cappuccino") || nameAndBrand.contains("espresso") {
            
            if nameAndBrand.contains("cream") || nameAndBrand.contains("milk") || 
               nameAndBrand.contains("latte") || nameAndBrand.contains("cappuccino") {
                return .coffeeDrink
            } else {
                return .blackCoffee
            }
        }
        
        // Fast food items
        if ["dunkin", "starbucks", "mcdonald", "burger king", "subway", "kfc", "taco bell"].contains(where: { nameAndBrand.contains($0) }) {
            
            if nameAndBrand.contains("sandwich") || nameAndBrand.contains("burger") || nameAndBrand.contains("wrap") {
                return .fastFoodMain
            } else if nameAndBrand.contains("donut") || nameAndBrand.contains("muffin") || nameAndBrand.contains("cookie") {
                return .bakeryItem
            } else if nameAndBrand.contains("drink") || nameAndBrand.contains("soda") || nameAndBrand.contains("juice") {
                return .beverage
            }
        }
        
        // Packaged foods
        if nameAndBrand.contains("cereal") || nameAndBrand.contains("granola") {
            return .cereal
        } else if nameAndBrand.contains("yogurt") {
            return .yogurt
        } else if nameAndBrand.contains("chip") || nameAndBrand.contains("cracker") {
            return .snack
        }
        
        return .unknown
    }
    
    private func getBaseNutritionForCategory(_ category: BrandedFoodCategory, calories: Double) -> BaseNutrition {
        switch category {
        case .coffeeDrink:
            // Coffee with cream/milk: mostly carbs and fat from dairy, minimal protein
            return BaseNutrition(
                proteinPercentage: 0.12,  // ~3g protein per 100 cal
                carbsPercentage: 0.50,    // ~12g carbs per 100 cal (mostly from milk sugar)
                fatPercentage: 0.30,      // ~3.3g fat per 100 cal (from cream/milk)
                fiberPercentage: 0.0,
                sugarPercentage: 0.45,    // Most carbs are sugar from milk
                sodiumMgPer100Cal: 15
            )
            
        case .blackCoffee:
            // Black coffee: virtually no macros
            return BaseNutrition(
                proteinPercentage: 0.20,  // Minimal
                carbsPercentage: 0.80,    // Any calories mostly from trace carbs
                fatPercentage: 0.0,
                fiberPercentage: 0.0,
                sugarPercentage: 0.0,
                sodiumMgPer100Cal: 2
            )
            
        case .fastFoodMain:
            // Sandwiches, burgers: balanced but higher fat
            return BaseNutrition(
                proteinPercentage: 0.20,  // ~5g protein per 100 cal
                carbsPercentage: 0.40,    // ~10g carbs per 100 cal
                fatPercentage: 0.40,      // ~4.4g fat per 100 cal
                fiberPercentage: 0.08,    // ~2g fiber per 100 cal
                sugarPercentage: 0.15,    // Some sugar in buns/sauces
                sodiumMgPer100Cal: 200
            )
            
        case .bakeryItem:
            // Donuts, muffins: high carbs and fat
            return BaseNutrition(
                proteinPercentage: 0.08,  // ~2g protein per 100 cal
                carbsPercentage: 0.50,    // ~12.5g carbs per 100 cal
                fatPercentage: 0.42,      // ~4.7g fat per 100 cal
                fiberPercentage: 0.04,    // ~1g fiber per 100 cal
                sugarPercentage: 0.35,    // High sugar content
                sodiumMgPer100Cal: 120
            )
            
        case .beverage:
            // Non-coffee drinks: mostly carbs
            return BaseNutrition(
                proteinPercentage: 0.0,
                carbsPercentage: 1.0,     // All calories from carbs
                fatPercentage: 0.0,
                fiberPercentage: 0.0,
                sugarPercentage: 0.95,    // Almost all sugar
                sodiumMgPer100Cal: 10
            )
            
        case .cereal:
            return BaseNutrition(
                proteinPercentage: 0.12,
                carbsPercentage: 0.75,
                fatPercentage: 0.13,
                fiberPercentage: 0.25,
                sugarPercentage: 0.30,
                sodiumMgPer100Cal: 150
            )
            
        case .yogurt:
            return BaseNutrition(
                proteinPercentage: 0.35,
                carbsPercentage: 0.55,
                fatPercentage: 0.10,
                fiberPercentage: 0.0,
                sugarPercentage: 0.50,
                sodiumMgPer100Cal: 50
            )
            
        case .snack:
            return BaseNutrition(
                proteinPercentage: 0.08,
                carbsPercentage: 0.52,
                fatPercentage: 0.40,
                fiberPercentage: 0.08,
                sugarPercentage: 0.05,
                sodiumMgPer100Cal: 300
            )
            
        case .unknown:
            // Generic balanced nutrition
            return BaseNutrition(
                proteinPercentage: 0.15,
                carbsPercentage: 0.50,
                fatPercentage: 0.35,
                fiberPercentage: 0.06,
                sugarPercentage: 0.20,
                sodiumMgPer100Cal: 100
            )
        }
    }
    
    private func applyBrandedFoodAdjustments(
        base: BaseNutrition,
        name: String,
        brand: String,
        category: BrandedFoodCategory,
        knownCalories: Double
    ) -> DetailedNutrition {
        
        let nameLower = name.lowercased()
        let brandLower = brand.lowercased()
        
        var adjustedBase = base
        
        // Brand-specific adjustments
        if brandLower.contains("dunkin") {
            // Dunkin' tends to have higher sugar content
            adjustedBase.sugarPercentage = min(adjustedBase.sugarPercentage * 1.2, 0.8)
            adjustedBase.sodiumMgPer100Cal = adjustedBase.sodiumMgPer100Cal * 1.1
        }
        
        // Product name adjustments
        if nameLower.contains("large") {
            // Large sizes might have slightly different ratios due to more liquid
            if category == .coffeeDrink {
                adjustedBase.carbsPercentage = adjustedBase.carbsPercentage * 0.9
                adjustedBase.fatPercentage = adjustedBase.fatPercentage * 0.9
            }
        }
        
        if nameLower.contains("sugar") || nameLower.contains("sweet") {
            adjustedBase.sugarPercentage = min(adjustedBase.sugarPercentage * 1.3, 0.9)
            adjustedBase.carbsPercentage = min(adjustedBase.carbsPercentage * 1.1, 0.9)
        }
        
        if nameLower.contains("cream") {
            adjustedBase.fatPercentage = min(adjustedBase.fatPercentage * 1.2, 0.6)
            adjustedBase.proteinPercentage = min(adjustedBase.proteinPercentage * 1.1, 0.3)
        }
        
        // Calculate final nutrition values
        return DetailedNutrition(
            protein: (knownCalories * adjustedBase.proteinPercentage) / 4.0,  // 4 cal/g protein
            carbs: (knownCalories * adjustedBase.carbsPercentage) / 4.0,      // 4 cal/g carbs
            fat: (knownCalories * adjustedBase.fatPercentage) / 9.0,          // 9 cal/g fat
            fiber: (knownCalories * adjustedBase.fiberPercentage) / 4.0,      // Estimated
            sugar: (knownCalories * adjustedBase.sugarPercentage) / 4.0,      // Part of carbs
            sodium: adjustedBase.sodiumMgPer100Cal * (knownCalories / 100.0)  // Scale with calories
        )
    }
    
    private func calculateBrandedFoodConfidence(category: BrandedFoodCategory, brand: String) -> Double {
        switch category {
        case .coffeeDrink:
            return 0.85  // High confidence for coffee drinks
        case .blackCoffee:
            return 0.95  // Very high confidence for black coffee
        case .fastFoodMain, .bakeryItem:
            return 0.75  // Good confidence for common fast food
        case .beverage:
            return 0.90  // High confidence for drinks
        case .cereal, .yogurt, .snack:
            return 0.70  // Moderate confidence for packaged goods
        case .unknown:
            return 0.60  // Lower confidence for unknown categories
        }
    }
}

// MARK: - Supporting Types for Branded Food AI

enum BrandedFoodCategory {
    case coffeeDrink
    case blackCoffee
    case fastFoodMain
    case bakeryItem
    case beverage
    case cereal
    case yogurt
    case snack
    case unknown
}

struct NutritionEstimate {
    let calories: Double
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let confidence: Double
}

struct BaseNutrition {
    var proteinPercentage: Double      // Percentage of calories from protein
    var carbsPercentage: Double        // Percentage of calories from carbs
    var fatPercentage: Double          // Percentage of calories from fat
    var fiberPercentage: Double        // Estimated fiber as percentage of carbs
    var sugarPercentage: Double        // Percentage of carbs that are sugar
    var sodiumMgPer100Cal: Double      // Sodium per 100 calories
}

struct DetailedNutrition {
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
}

/// Structure representing AI analysis results
struct AIAnalysisResult {
    let insights: [String]
    let nutritionalScore: Double
    let recommendations: [String]
}
