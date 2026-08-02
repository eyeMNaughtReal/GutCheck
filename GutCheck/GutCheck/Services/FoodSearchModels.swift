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

    /// Allergens declared by the source, already normalised to the app's
    /// vocabulary ("Dairy", "Gluten", …).
    ///
    /// A declared allergen is authoritative in a way keyword matching is not:
    /// it survives the ingredient list being in another language. Empty means
    /// "the source said nothing", not "no allergens" — callers should still run
    /// keyword detection and take the union.
    let declaredAllergens: [String]
    
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
        declaredAllergens: [String] = [],
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
        self.declaredAllergens = declaredAllergens
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
    var magnesiumMilligrams: Double? { Self.toMilligrams(magnesium) }
    var phosphorusMilligrams: Double? { Self.toMilligrams(phosphorus) }
    var zincMilligrams: Double? { Self.toMilligrams(zinc) }
    var copperMilligrams: Double? { Self.toMilligrams(copper) }
    var manganeseMilligrams: Double? { Self.toMilligrams(manganese) }
    var vitaminEMilligrams: Double? { Self.toMilligrams(vitaminE) }
    var thiaminMilligrams: Double? { Self.toMilligrams(thiamin) }
    var riboflavinMilligrams: Double? { Self.toMilligrams(riboflavin) }
    var niacinMilligrams: Double? { Self.toMilligrams(niacin) }
    var vitaminB6Milligrams: Double? { Self.toMilligrams(vitaminB6) }
    var pantothenicAcidMilligrams: Double? { Self.toMilligrams(pantothenicAcid) }
    var vitaminCMilligrams: Double? { Self.toMilligrams(vitaminC) }
    var vitaminAMicrograms: Double? { Self.toMicrograms(vitaminA) }
    var vitaminDMicrograms: Double? { Self.toMicrograms(vitaminD) }
    var vitaminKMicrograms: Double? { Self.toMicrograms(vitaminK) }
    var folateMicrograms: Double? { Self.toMicrograms(folate) }
    var vitaminB12Micrograms: Double? { Self.toMicrograms(vitaminB12) }
    var biotinMicrograms: Double? { Self.toMicrograms(biotin) }
    var seleniumMicrograms: Double? { Self.toMicrograms(selenium) }

    /// Trims the float noise that `"\(someDouble)"` leaves behind while keeping
    /// enough precision for tiny micronutrients — a converted 0.4605 g becomes
    /// 460.49999999999994, which should read as `460.5`.
    ///
    /// - Important: Formats in `en_US_POSIX`, not the user's locale. These
    ///   strings go into `nutritionDetails` and are parsed back out later by
    ///   `UnifiedFoodDetailView.parsedDetails`, which keeps only digits and
    ///   `.`. A locale that uses a comma decimal separator would render this
    ///   as `460,5`, and stripping that comma silently turns it into `4605`.
    static func amount(_ value: Double) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(0...3))
                .grouping(.never)
                .locale(Self.storageLocale)
        )
    }

    /// Fixed locale for numbers that are stored as strings and re-parsed later.
    /// Display formatting should still use the user's locale.
    static let storageLocale = Locale(identifier: "en_US_POSIX")

    /// Convert to FoodItem for logging meals
    func toFoodItem(quantity: String? = nil) -> FoodItem {
        let finalQuantity = quantity ?? {
            if let servingQty = servingQty, let servingUnit = servingUnit {
                return "\(servingQty) \(servingUnit)"
            }
            return "1 serving"
        }()
        
        var nutritionDetails: [String: String] = [:]
        
        // Add detailed nutrition data. Grams stay grams; anything labelled
        // mg/mcg is converted first so the number and suffix agree.
        func addDetail(_ label: String, _ value: Double?, unit: String, formatter: (Double) -> String = Self.amount) {
            guard let value else { return }
            nutritionDetails[label] = "\(formatter(value))\(unit)"
        }

        addDetail("Calories", calories, unit: "kcal")
        addDetail("Protein", protein, unit: "g")
        addDetail("Total Carbohydrate", carbs, unit: "g")
        addDetail("Total Fat", fat, unit: "g")
        addDetail("Dietary Fiber", fiber, unit: "g")
        addDetail("Total Sugars", sugar, unit: "g")
        addDetail("Sodium", sodiumMilligrams, unit: "mg")

        addDetail("Saturated Fat", saturatedFat, unit: "g")
        addDetail("Trans Fat", transFat, unit: "g")
        addDetail("Polyunsaturated Fat", polyunsaturatedFat, unit: "g")
        addDetail("Monounsaturated Fat", monounsaturatedFat, unit: "g")
        addDetail("Cholesterol", cholesterolMilligrams, unit: "mg")

        addDetail("Potassium", potassiumMilligrams, unit: "mg")
        addDetail("Calcium", calciumMilligrams, unit: "mg")
        addDetail("Iron", ironMilligrams, unit: "mg")
        addDetail("Magnesium", magnesiumMilligrams, unit: "mg")
        addDetail("Phosphorus", phosphorusMilligrams, unit: "mg")
        addDetail("Zinc", zincMilligrams, unit: "mg")
        addDetail("Copper", copperMilligrams, unit: "mg")
        addDetail("Manganese", manganeseMilligrams, unit: "mg")
        addDetail("Selenium", seleniumMicrograms, unit: "mcg")

        addDetail("Vitamin A", vitaminAMicrograms, unit: "mcg")
        addDetail("Vitamin C", vitaminCMilligrams, unit: "mg")
        addDetail("Vitamin D", vitaminDMicrograms, unit: "mcg")
        addDetail("Vitamin E", vitaminEMilligrams, unit: "mg")
        addDetail("Vitamin K", vitaminKMicrograms, unit: "mcg")
        addDetail("Thiamin", thiaminMilligrams, unit: "mg")
        addDetail("Riboflavin", riboflavinMilligrams, unit: "mg")
        addDetail("Niacin", niacinMilligrams, unit: "mg")
        addDetail("Vitamin B6", vitaminB6Milligrams, unit: "mg")
        addDetail("Folate", folateMicrograms, unit: "mcg")
        addDetail("Vitamin B12", vitaminB12Micrograms, unit: "mcg")
        addDetail("Biotin", biotinMicrograms, unit: "mcg")
        addDetail("Pantothenic Acid", pantothenicAcidMilligrams, unit: "mg")
        
        return FoodItem(
            name: brand != nil ? "\(brand!) \(name)" : name,
            quantity: finalQuantity,
            estimatedWeightInGrams: servingWeight,
            ingredients: IngredientTextParser.split(ingredients),
            allergens: declaredAllergens,
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
