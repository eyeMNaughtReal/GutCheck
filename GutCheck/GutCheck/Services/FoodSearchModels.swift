//  FoodSearchModels.swift
//  GutCheck
//
//  Generic food search result models

import Foundation

// MARK: - Food Search Result
/// Represents a food item from search results with comprehensive nutrition data
///
/// - Important: **Every nutrient on this type is in grams**, including minerals
///   and vitamins. Both sources normalize to that convention — OpenFoodFacts
///   reports `*_100g` natively, and `USDAFoodService` divides its mg/mcg values
///   down to match (see `fromMg`/`fromMcg` there).
///
///   `NutritionInfo` and the nutrition UI expect **milligrams**. Cross that
///   boundary through the `…Milligrams`/`…Micrograms` accessors below rather
///   than passing the stored value through — doing the latter is what made
///   sodium read `0 mg` for a Big Mac.
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
    
    // MARK: - Unit conversion

    /// Grams to milligrams, preserving nil.
    private static func toMilligrams(_ grams: Double?) -> Double? {
        grams.map { $0 * 1_000 }
    }

    /// Grams to micrograms, preserving nil.
    private static func toMicrograms(_ grams: Double?) -> Double? {
        grams.map { $0 * 1_000_000 }
    }

    var sodiumMilligrams: Double? { Self.toMilligrams(sodium) }
    var cholesterolMilligrams: Double? { Self.toMilligrams(cholesterol) }
    var potassiumMilligrams: Double? { Self.toMilligrams(potassium) }
    var calciumMilligrams: Double? { Self.toMilligrams(calcium) }
    var ironMilligrams: Double? { Self.toMilligrams(iron) }
    var vitaminCMilligrams: Double? { Self.toMilligrams(vitaminC) }
    var vitaminAMicrograms: Double? { Self.toMicrograms(vitaminA) }
    var vitaminDMicrograms: Double? { Self.toMicrograms(vitaminD) }

    /// Trims the float noise that `"\(someDouble)"` leaves behind — a converted
    /// 0.4605 g becomes 460.49999999999994, which should read as `460.5`.
    private static func amount(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)).grouping(.never))
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
        // Grams stay grams; anything labelled mg/mcg is converted first, so the
        // number and its suffix agree.
        if let saturatedFat = saturatedFat {
            nutritionDetails["Saturated Fat"] = "\(Self.amount(saturatedFat))g"
        }
        if let cholesterol = cholesterolMilligrams {
            nutritionDetails["Cholesterol"] = "\(Self.amount(cholesterol))mg"
        }
        if let potassium = potassiumMilligrams {
            nutritionDetails["Potassium"] = "\(Self.amount(potassium))mg"
        }
        if let calcium = calciumMilligrams {
            nutritionDetails["Calcium"] = "\(Self.amount(calcium))mg"
        }
        if let iron = ironMilligrams {
            nutritionDetails["Iron"] = "\(Self.amount(iron))mg"
        }
        if let vitaminA = vitaminAMicrograms {
            nutritionDetails["Vitamin A"] = "\(Self.amount(vitaminA))mcg"
        }
        if let vitaminC = vitaminCMilligrams {
            nutritionDetails["Vitamin C"] = "\(Self.amount(vitaminC))mg"
        }
        if let vitaminD = vitaminDMicrograms {
            nutritionDetails["Vitamin D"] = "\(Self.amount(vitaminD))mcg"
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
                sodium: sodiumMilligrams
            ),
            source: .manual,
            nutritionDetails: nutritionDetails
        )
    }
}
// MARK: - Backward Compatibility
// Type alias for existing code that references NutritionixFood
typealias NutritionixFood = FoodSearchResult

