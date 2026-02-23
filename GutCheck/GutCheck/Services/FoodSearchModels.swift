//  FoodSearchModels.swift
//  GutCheck
//
//  Generic food search result models

import Foundation

// MARK: - Food Search Result
/// Represents a food item from search results with comprehensive nutrition data
struct FoodSearchResult: Identifiable, Codable {
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
    let servingWeight: Double?
    
    // Ingredients
    let ingredients: String?
    
    // Additional macronutrients
    let saturatedFat: Double?
    let transFat: Double?
    let polyunsaturatedFat: Double?
    let monounsaturatedFat: Double?
    let cholesterol: Double?
    
    // Minerals
    let potassium: Double?
    let calcium: Double?
    let iron: Double?
    let magnesium: Double?
    let phosphorus: Double?
    let zinc: Double?
    let copper: Double?
    let manganese: Double?
    let selenium: Double?
    
    // Vitamins
    let vitaminA: Double?
    let vitaminC: Double?
    let vitaminD: Double?
    let vitaminE: Double?
    let vitaminK: Double?
    let thiamin: Double?
    let riboflavin: Double?
    let niacin: Double?
    let vitaminB6: Double?
    let folate: Double?
    let vitaminB12: Double?
    let biotin: Double?
    let pantothenicAcid: Double?
    
    // Amino acids (essential)
    let histidine: Double?
    let isoleucine: Double?
    let leucine: Double?
    let lysine: Double?
    let methionine: Double?
    let phenylalanine: Double?
    let threonine: Double?
    let tryptophan: Double?
    let valine: Double?
    
    // Amino acids (non-essential)
    let alanine: Double?
    let arginine: Double?
    let asparticAcid: Double?
    let cysteine: Double?
    let glutamicAcid: Double?
    let glycine: Double?
    let proline: Double?
    let serine: Double?
    let tyrosine: Double?
    
    // Other nutrients
    let water: Double?
    let ash: Double?
    let caffeine: Double?
    let theobromine: Double?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        brand: String? = nil,
        calories: Double? = nil,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil,
        servingUnit: String? = nil,
        servingQty: Double? = nil,
        servingWeight: Double? = nil,
        ingredients: String? = nil,
        saturatedFat: Double? = nil,
        transFat: Double? = nil,
        polyunsaturatedFat: Double? = nil,
        monounsaturatedFat: Double? = nil,
        cholesterol: Double? = nil,
        potassium: Double? = nil,
        calcium: Double? = nil,
        iron: Double? = nil,
        magnesium: Double? = nil,
        phosphorus: Double? = nil,
        zinc: Double? = nil,
        copper: Double? = nil,
        manganese: Double? = nil,
        selenium: Double? = nil,
        vitaminA: Double? = nil,
        vitaminC: Double? = nil,
        vitaminD: Double? = nil,
        vitaminE: Double? = nil,
        vitaminK: Double? = nil,
        thiamin: Double? = nil,
        riboflavin: Double? = nil,
        niacin: Double? = nil,
        vitaminB6: Double? = nil,
        folate: Double? = nil,
        vitaminB12: Double? = nil,
        biotin: Double? = nil,
        pantothenicAcid: Double? = nil,
        histidine: Double? = nil,
        isoleucine: Double? = nil,
        leucine: Double? = nil,
        lysine: Double? = nil,
        methionine: Double? = nil,
        phenylalanine: Double? = nil,
        threonine: Double? = nil,
        tryptophan: Double? = nil,
        valine: Double? = nil,
        alanine: Double? = nil,
        arginine: Double? = nil,
        asparticAcid: Double? = nil,
        cysteine: Double? = nil,
        glutamicAcid: Double? = nil,
        glycine: Double? = nil,
        proline: Double? = nil,
        serine: Double? = nil,
        tyrosine: Double? = nil,
        water: Double? = nil,
        ash: Double? = nil,
        caffeine: Double? = nil,
        theobromine: Double? = nil
    ) {
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
        self.servingWeight = servingWeight
        self.ingredients = ingredients
        self.saturatedFat = saturatedFat
        self.transFat = transFat
        self.polyunsaturatedFat = polyunsaturatedFat
        self.monounsaturatedFat = monounsaturatedFat
        self.cholesterol = cholesterol
        self.potassium = potassium
        self.calcium = calcium
        self.iron = iron
        self.magnesium = magnesium
        self.phosphorus = phosphorus
        self.zinc = zinc
        self.copper = copper
        self.manganese = manganese
        self.selenium = selenium
        self.vitaminA = vitaminA
        self.vitaminC = vitaminC
        self.vitaminD = vitaminD
        self.vitaminE = vitaminE
        self.vitaminK = vitaminK
        self.thiamin = thiamin
        self.riboflavin = riboflavin
        self.niacin = niacin
        self.vitaminB6 = vitaminB6
        self.folate = folate
        self.vitaminB12 = vitaminB12
        self.biotin = biotin
        self.pantothenicAcid = pantothenicAcid
        self.histidine = histidine
        self.isoleucine = isoleucine
        self.leucine = leucine
        self.lysine = lysine
        self.methionine = methionine
        self.phenylalanine = phenylalanine
        self.threonine = threonine
        self.tryptophan = tryptophan
        self.valine = valine
        self.alanine = alanine
        self.arginine = arginine
        self.asparticAcid = asparticAcid
        self.cysteine = cysteine
        self.glutamicAcid = glutamicAcid
        self.glycine = glycine
        self.proline = proline
        self.serine = serine
        self.tyrosine = tyrosine
        self.water = water
        self.ash = ash
        self.caffeine = caffeine
        self.theobromine = theobromine
    }
    
    /// Convert to FoodItem for logging meals
    func toFoodItem(quantity: String? = nil) -> FoodItem {
        let finalQuantity = quantity ?? {
            if let servingQty = servingQty, let servingUnit = servingUnit {
                return "\(servingQty) \(servingUnit)"
            }
            return "1 serving"
        }()
        
        var nutritionDetails: [String: String] = [:]
        
        // Add detailed nutrition data
        if let saturatedFat = saturatedFat {
            nutritionDetails["Saturated Fat"] = "\(saturatedFat)g"
        }
        if let cholesterol = cholesterol {
            nutritionDetails["Cholesterol"] = "\(cholesterol)mg"
        }
        if let potassium = potassium {
            nutritionDetails["Potassium"] = "\(potassium)mg"
        }
        if let calcium = calcium {
            nutritionDetails["Calcium"] = "\(calcium)mg"
        }
        if let iron = iron {
            nutritionDetails["Iron"] = "\(iron)mg"
        }
        if let vitaminA = vitaminA {
            nutritionDetails["Vitamin A"] = "\(vitaminA)mcg"
        }
        if let vitaminC = vitaminC {
            nutritionDetails["Vitamin C"] = "\(vitaminC)mg"
        }
        if let vitaminD = vitaminD {
            nutritionDetails["Vitamin D"] = "\(vitaminD)mcg"
        }
        
        return FoodItem(
            name: brand != nil ? "\(brand!) \(name)" : name,
            quantity: finalQuantity,
            estimatedWeightInGrams: servingWeight,
            ingredients: ingredients?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            nutrition: NutritionInfo(
                calories: calories.map { Int($0) },
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                sugar: sugar,
                sodium: sodium
            ),
            source: .manual,
            nutritionDetails: nutritionDetails
        )
    }
}
// MARK: - Backward Compatibility
// Type alias for existing code that references NutritionixFood
typealias NutritionixFood = FoodSearchResult

