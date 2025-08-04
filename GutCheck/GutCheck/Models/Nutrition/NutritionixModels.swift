import Foundation

// MARK: - Nutritionix API Models
struct NutritionixResponse: Codable {
    let foods: [NutritionixFood]?  // For detailed nutrition queries
    let common: [NutritionixCommonFood]?  // For instant search
    let branded: [NutritionixBrandedFood]?  // For instant search
}

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
    let servingWeight: Double?
    
    // Ingredients
    let ingredients: String?  // Full ingredients text from Nutritionix
    
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
    
    private enum CodingKeys: String, CodingKey {
        case id = "nix_item_id"
        case name = "food_name"
        case brand = "brand_name"
        case calories = "nf_calories"
        case protein = "nf_protein"
        case carbs = "nf_total_carbohydrate"
        case fat = "nf_total_fat"
        case fiber = "nf_dietary_fiber"
        case sugar = "nf_sugars"
        case sodium = "nf_sodium"
        case servingWeight = "serving_weight_grams"
        case servingUnit = "serving_unit"
        case servingQty = "serving_qty"
        case ingredients = "nf_ingredient_statement"
        
        // Additional macronutrients
        case saturatedFat = "nf_saturated_fat"
        case transFat = "nf_trans_fatty_acid"
        case polyunsaturatedFat = "nf_polyunsaturated_fat"
        case monounsaturatedFat = "nf_monounsaturated_fat"
        case cholesterol = "nf_cholesterol"
        
        // Minerals
        case potassium = "nf_potassium"
        case calcium = "nf_calcium_dv"
        case iron = "nf_iron_dv"
        case magnesium = "nf_magnesium"
        case phosphorus = "nf_phosphorus"
        case zinc = "nf_zinc"
        case copper = "nf_copper"
        case manganese = "nf_manganese"
        case selenium = "nf_selenium"
        
        // Vitamins
        case vitaminA = "nf_vitamin_a_dv"
        case vitaminC = "nf_vitamin_c_dv"
        case vitaminD = "nf_vitamin_d"
        case vitaminE = "nf_vitamin_e"
        case vitaminK = "nf_vitamin_k"
        case thiamin = "nf_thiamin"
        case riboflavin = "nf_riboflavin"
        case niacin = "nf_niacin"
        case vitaminB6 = "nf_vitamin_b6"
        case folate = "nf_folate_dfe"
        case vitaminB12 = "nf_vitamin_b12"
        case biotin = "nf_biotin"
        case pantothenicAcid = "nf_pantothenic_acid"
        
        // Amino acids (essential)
        case histidine = "nf_histidine"
        case isoleucine = "nf_isoleucine"
        case leucine = "nf_leucine"
        case lysine = "nf_lysine"
        case methionine = "nf_methionine"
        case phenylalanine = "nf_phenylalanine"
        case threonine = "nf_threonine"
        case tryptophan = "nf_tryptophan"
        case valine = "nf_valine"
        
        // Amino acids (non-essential)
        case alanine = "nf_alanine"
        case arginine = "nf_arginine"
        case asparticAcid = "nf_aspartic_acid"
        case cysteine = "nf_cystine"
        case glutamicAcid = "nf_glutamic_acid"
        case glycine = "nf_glycine"
        case proline = "nf_proline"
        case serine = "nf_serine"
        case tyrosine = "nf_tyrosine"
        
        // Other nutrients
        case water = "nf_water"
        case ash = "nf_ash"
        case caffeine = "nf_caffeine"
        case theobromine = "nf_theobromine"
    }
    
    init(id: String, name: String, brand: String? = nil, calories: Double? = nil,
         protein: Double? = nil, carbs: Double? = nil, fat: Double? = nil,
         fiber: Double? = nil, sugar: Double? = nil, sodium: Double? = nil,
         servingUnit: String? = nil, servingQty: Double? = nil,
         servingWeight: Double? = nil, ingredients: String? = nil, saturatedFat: Double? = nil,
         transFat: Double? = nil, polyunsaturatedFat: Double? = nil,
         monounsaturatedFat: Double? = nil, cholesterol: Double? = nil,
         potassium: Double? = nil, calcium: Double? = nil, iron: Double? = nil,
         magnesium: Double? = nil, phosphorus: Double? = nil, zinc: Double? = nil,
         copper: Double? = nil, manganese: Double? = nil, selenium: Double? = nil,
         vitaminA: Double? = nil, vitaminC: Double? = nil, vitaminD: Double? = nil,
         vitaminE: Double? = nil, vitaminK: Double? = nil, thiamin: Double? = nil,
         riboflavin: Double? = nil, niacin: Double? = nil, vitaminB6: Double? = nil,
         folate: Double? = nil, vitaminB12: Double? = nil, biotin: Double? = nil,
         pantothenicAcid: Double? = nil, histidine: Double? = nil,
         isoleucine: Double? = nil, leucine: Double? = nil, lysine: Double? = nil,
         methionine: Double? = nil, phenylalanine: Double? = nil,
         threonine: Double? = nil, tryptophan: Double? = nil, valine: Double? = nil,
         alanine: Double? = nil, arginine: Double? = nil, asparticAcid: Double? = nil,
         cysteine: Double? = nil, glutamicAcid: Double? = nil, glycine: Double? = nil,
         proline: Double? = nil, serine: Double? = nil, tyrosine: Double? = nil,
         water: Double? = nil, ash: Double? = nil, caffeine: Double? = nil,
         theobromine: Double? = nil) {
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
}

struct NutritionixCommonFood: Codable, Identifiable {
    let id = UUID().uuidString // Common foods don't have IDs from API
    let name: String
    let servingUnit: String
    let servingQty: Double
    let photo: NutritionixPhoto?
    
    private enum CodingKeys: String, CodingKey {
        case name = "food_name"
        case servingUnit = "serving_unit"
        case servingQty = "serving_qty"
        case photo
    }
    
    func toNutritionixFood() -> NutritionixFood {
        return NutritionixFood(
            id: id,
            name: name,
            servingUnit: servingUnit,
            servingQty: servingQty
        )
    }
}

struct NutritionixBrandedFood: Codable, Identifiable {
    let id: String
    let name: String
    let brand: String
    let servingUnit: String
    let servingQty: Double
    let calories: Double?
    
    private enum CodingKeys: String, CodingKey {
        case id = "nix_item_id"
        case name = "food_name"
        case brand = "brand_name"
        case servingUnit = "serving_unit"
        case servingQty = "serving_qty"
        case calories = "nf_calories"
    }
    
    func toNutritionixFood() -> NutritionixFood {
        return NutritionixFood(
            id: id,
            name: name,
            brand: brand,
            calories: calories,
            servingUnit: servingUnit,
            servingQty: servingQty
        )
    }
}

struct NutritionixPhoto: Codable {
    let thumb: String?
}
