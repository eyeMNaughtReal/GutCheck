//
//  FoodCompoundDatabase.swift
//  GutCheck
//
//  Comprehensive database of food compounds and their health implications

import Foundation
import SwiftUI

// MARK: - Models

enum HealthSeverity: Int, CaseIterable {
    case low = 1
    case medium = 2  
    case high = 3
    
    var borderColor: Color {
        switch self {
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct FoodCompound {
    let name: String
    let category: CompoundCategory
    let severity: HealthSeverity
    let description: String
    let icon: String
    let color: String // Color name for consistency
}

enum CompoundCategory: String, CaseIterable {
    // Primary Categories - Allergens & Warnings
    case majorAllergen = "Major Allergens"
    case foodIntolerance = "Food Intolerances"
    case toxicCompound = "Toxic Compounds"
    case inflammatoryCompound = "Inflammatory Compounds"
    case metabolicDisruptor = "Metabolic Disruptors"
    case neurologicalTrigger = "Neurological Triggers"
    
    // Secondary Categories - Chemical Classifications
    case alkaloid = "Alkaloids"
    case biogenicAmine = "Biogenic Amines"
    case phenolic = "Phenolic Compounds"
    case heavyMetal = "Heavy Metals"
    case preservative = "Preservatives & Additives"
    case naturalToxin = "Natural Toxins"
}

struct FoodCompoundMapping {
    let foodKeywords: [String]
    let compounds: [FoodCompound]
}

struct IngredientMapping {
    let keywords: [String]
    let compounds: [FoodCompound]
    let ingredientName: String
}

struct CompositeFood {
    let keywords: [String]
    let likelyIngredients: [String]
    let description: String
}

// MARK: - Food Compound Database

class FoodCompoundDatabase {
    static let shared = FoodCompoundDatabase()
    
    private init() {}
    
    // MARK: - Compound Definitions
    
    private let compounds: [String: FoodCompound] = [
        // Alkaloids
        "solanine": FoodCompound(
            name: "Solanine",
            category: .toxicCompound,
            severity: .high,
            description: "Glycoalkaloid toxin found in nightshades. Can cause digestive issues, neurological symptoms, and cellular damage at high doses.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "chaconine": FoodCompound(
            name: "α-Chaconine",
            category: .toxicCompound,
            severity: .high,
            description: "Toxic glycoalkaloid that works synergistically with solanine. Found in potatoes and can cause gastrointestinal distress.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "tomatine": FoodCompound(
            name: "α-Tomatine",
            category: .toxicCompound,
            severity: .medium,
            description: "Glycoalkaloid found in tomatoes, particularly green tomatoes. Can cause digestive upset in sensitive individuals.",
            icon: "exclamationmark.triangle",
            color: "orange"
        ),
        "capsaicin": FoodCompound(
            name: "Capsaicin",
            category: .inflammatoryCompound,
            severity: .medium,
            description: "Vanillamide compound that creates heat sensation. Can irritate digestive tract and mucous membranes.",
            icon: "flame.fill",
            color: "red"
        ),
        "caffeine": FoodCompound(
            name: "Caffeine",
            category: .neurologicalTrigger,
            severity: .low,
            description: "Stimulant alkaloid that can cause jitters, insomnia, and digestive issues in sensitive individuals.",
            icon: "bolt.fill",
            color: "orange"
        ),
        "theobromine": FoodCompound(
            name: "Theobromine",
            category: .neurologicalTrigger,
            severity: .low,
            description: "Methylxanthine found in chocolate. Can cause headaches and digestive issues in sensitive people.",
            icon: "heart.fill",
            color: "orange"
        ),
        
        // Biogenic Amines
        "histamine": FoodCompound(
            name: "Histamine",
            category: .foodIntolerance,
            severity: .high,
            description: "Inflammatory compound formed during fermentation. Can trigger allergic-like reactions, headaches, and digestive issues.",
            icon: "allergens",
            color: "red"
        ),
        "tyramine": FoodCompound(
            name: "Tyramine",
            category: .neurologicalTrigger,
            severity: .high,
            description: "Monoamine that can trigger migraines and hypertensive crises, especially with MAOI medications.",
            icon: "brain.head.profile",
            color: "red"
        ),
        "phenylethylamine": FoodCompound(
            name: "Phenylethylamine",
            category: .neurologicalTrigger,
            severity: .medium,
            description: "Trace amine that can trigger migraines and mood changes in sensitive individuals.",
            icon: "brain.head.profile",
            color: "orange"
        ),
        "putrescine": FoodCompound(
            name: "Putrescine",
            category: .foodIntolerance,
            severity: .medium,
            description: "Polyamine formed during protein breakdown. Can enhance histamine toxicity and cause digestive issues.",
            icon: "multiply.circle.fill",
            color: "orange"
        ),
        
        // Phenolic Compounds
        "salicylates": FoodCompound(
            name: "Salicylates",
            category: .inflammatoryCompound,
            severity: .medium,
            description: "Natural aspirin-like compounds that can trigger asthma, skin reactions, and digestive issues in sensitive individuals.",
            icon: "leaf.fill",
            color: "orange"
        ),
        "tannins": FoodCompound(
            name: "Tannins",
            category: .metabolicDisruptor,
            severity: .low,
            description: "Polyphenolic compounds that can interfere with iron absorption and cause digestive irritation.",
            icon: "drop.fill",
            color: "yellow"
        ),
        "quercetin": FoodCompound(
            name: "Quercetin",
            category: .inflammatoryCompound,
            severity: .low,
            description: "Flavonoid that can cause headaches and interact with certain medications in high doses.",
            icon: "sparkles",
            color: "yellow"
        ),
        
        // Proteins & Allergens
        "profilins": FoodCompound(
            name: "Profilins",
            category: .majorAllergen,
            severity: .high,
            description: "Pan-allergen proteins that cause cross-reactivity between pollens and foods. Can trigger oral allergy syndrome.",
            icon: "allergens",
            color: "red"
        ),
        "lipidTransferProteins": FoodCompound(
            name: "Lipid Transfer Proteins (LTPs)",
            category: .majorAllergen,
            severity: .high,
            description: "Heat-stable allergen proteins that can cause severe allergic reactions including anaphylaxis.",
            icon: "allergens",
            color: "red"
        ),
        "lectins": FoodCompound(
            name: "Lectins",
            category: .inflammatoryCompound,
            severity: .medium,
            description: "Carbohydrate-binding proteins that can cause digestive issues and inflammatory responses.",
            icon: "link",
            color: "orange"
        ),
        "gluten": FoodCompound(
            name: "Gluten",
            category: .majorAllergen,
            severity: .high,
            description: "Storage protein complex that triggers celiac disease and non-celiac gluten sensitivity.",
            icon: "allergens",
            color: "red"
        ),
        "casein": FoodCompound(
            name: "Casein",
            category: .foodIntolerance,
            severity: .medium,
            description: "Milk protein that can cause digestive issues and inflammatory responses in sensitive individuals.",
            icon: "drop.fill",
            color: "orange"
        ),
        
        // Enzymes
        "betaFructofuranosidase": FoodCompound(
            name: "β-Fructofuranosidase (Sola l 2)",
            category: .majorAllergen,
            severity: .medium,
            description: "Tomato-specific allergen enzyme that can trigger allergic reactions and cross-react with birch pollen.",
            icon: "leaf.fill",
            color: "orange"
        ),
        "bromelain": FoodCompound(
            name: "Bromelain",
            category: .inflammatoryCompound,
            severity: .low,
            description: "Proteolytic enzyme in pineapple that can cause mouth irritation and digestive upset.",
            icon: "scissors",
            color: "yellow"
        ),
        "ficin": FoodCompound(
            name: "Ficin",
            category: .inflammatoryCompound,
            severity: .low,
            description: "Proteolytic enzyme in figs that can cause skin and mouth irritation.",
            icon: "scissors",
            color: "yellow"
        ),
        
        // Antinutrients
        "oxalates": FoodCompound(
            name: "Oxalates",
            category: .metabolicDisruptor,
            severity: .medium,
            description: "Compounds that can bind minerals and contribute to kidney stone formation in susceptible individuals.",
            icon: "diamond.fill",
            color: "orange"
        ),
        "phyticAcid": FoodCompound(
            name: "Phytic Acid",
            category: .metabolicDisruptor,
            severity: .low,
            description: "Phosphorus storage compound that can bind minerals and reduce their absorption.",
            icon: "minus.circle.fill",
            color: "yellow"
        ),
        "goitrogens": FoodCompound(
            name: "Goitrogens",
            category: .metabolicDisruptor,
            severity: .medium,
            description: "Compounds that can interfere with thyroid function and iodine uptake.",
            icon: "circle.dotted",
            color: "orange"
        ),
        
        // Heavy Metals
        "mercury": FoodCompound(
            name: "Mercury",
            category: .toxicCompound,
            severity: .high,
            description: "Neurotoxic heavy metal that accumulates in large predatory fish. Can cause neurological damage.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "lead": FoodCompound(
            name: "Lead",
            category: .toxicCompound,
            severity: .high,
            description: "Toxic heavy metal found in some foods. Can cause neurological damage, especially in children.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "cadmium": FoodCompound(
            name: "Cadmium",
            category: .toxicCompound,
            severity: .high,
            description: "Toxic heavy metal that can damage kidneys and bones. Found in leafy greens and organ meats.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "arsenic": FoodCompound(
            name: "Arsenic",
            category: .toxicCompound,
            severity: .high,
            description: "Carcinogenic metalloid commonly found in rice and rice products. Can cause skin lesions and cancer.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        
        // Preservatives & Additives
        "sulfites": FoodCompound(
            name: "Sulfites",
            category: .foodIntolerance,
            severity: .high,
            description: "Preservative compounds that can trigger asthma attacks and allergic reactions in sensitive individuals.",
            icon: "wind",
            color: "red"
        ),
        "nitrates": FoodCompound(
            name: "Nitrates/Nitrites",
            category: .toxicCompound,
            severity: .medium,
            description: "Preservatives that can form nitrosamines (potential carcinogens) and trigger headaches.",
            icon: "drop.triangle.fill",
            color: "orange"
        ),
        "msg": FoodCompound(
            name: "Monosodium Glutamate (MSG)",
            category: .neurologicalTrigger,
            severity: .low,
            description: "Flavor enhancer that can cause headaches and flushing in sensitive individuals.",
            icon: "sparkles",
            color: "yellow"
        ),
        
        // Natural Toxins
        "aflatoxins": FoodCompound(
            name: "Aflatoxins",
            category: .toxicCompound,
            severity: .high,
            description: "Carcinogenic mycotoxins produced by Aspergillus molds. Found in nuts, grains, and dried fruits.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "patulin": FoodCompound(
            name: "Patulin",
            category: .toxicCompound,
            severity: .medium,
            description: "Mycotoxin found in damaged apples and apple products. Can cause digestive and immune issues.",
            icon: "exclamationmark.triangle",
            color: "orange"
        ),
        "cyanogenic_glycosides": FoodCompound(
            name: "Cyanogenic Glycosides",
            category: .toxicCompound,
            severity: .high,
            description: "Compounds that release cyanide when broken down. Found in cassava, lima beans, and stone fruit pits.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        
        // Additional compounds for Apple Pie and baked goods
        "coumarin": FoodCompound(
            name: "Coumarin",
            category: .toxicCompound,
            severity: .medium,
            description: "Aromatic compound in cinnamon that can cause liver damage in high doses and blood thinning effects.",
            icon: "drop.fill",
            color: "orange"
        ),
        "myristicin": FoodCompound(
            name: "Myristicin",
            category: .neurologicalTrigger,
            severity: .low,
            description: "Aromatic compound in nutmeg that can cause nausea and hallucinations in large amounts.",
            icon: "brain.head.profile",
            color: "yellow"
        ),
        "acrylamide": FoodCompound(
            name: "Acrylamide",
            category: .toxicCompound,
            severity: .high,
            description: "Carcinogenic compound formed during high-temperature baking of starchy foods like pie crust.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "advanced_glycation_end_products": FoodCompound(
            name: "Advanced Glycation End Products (AGEs)",
            category: .inflammatoryCompound,
            severity: .medium,
            description: "Inflammatory compounds formed during baking that can contribute to aging and chronic disease.",
            icon: "flame.fill",
            color: "orange"
        ),
        "trans_fats": FoodCompound(
            name: "Trans Fats",
            category: .toxicCompound,
            severity: .high,
            description: "Artificial fats that can form during processing and increase cardiovascular disease risk.",
            icon: "heart.slash.fill",
            color: "red"
        ),
        "saturated_fats": FoodCompound(
            name: "Saturated Fats",
            category: .metabolicDisruptor,
            severity: .low,
            description: "High levels can contribute to inflammation and cardiovascular issues in sensitive individuals.",
            icon: "drop.circle.fill",
            color: "yellow"
        ),
        
        // Additional compounds for comprehensive analysis
        "lactose": FoodCompound(
            name: "Lactose",
            category: .foodIntolerance,
            severity: .medium,
            description: "Milk sugar that can cause digestive issues in lactose-intolerant individuals.",
            icon: "drop.triangle.fill",
            color: "orange"
        ),
        "oligosaccharides": FoodCompound(
            name: "Oligosaccharides",
            category: .foodIntolerance,
            severity: .low,
            description: "Complex sugars that can cause gas and digestive discomfort.",
            icon: "wind",
            color: "yellow"
        ),
        "fructose": FoodCompound(
            name: "Fructose",
            category: .foodIntolerance,
            severity: .low,
            description: "Fruit sugar that can cause digestive issues in people with fructose malabsorption.",
            icon: "drop.triangle.fill",
            color: "yellow"
        ),
        "shellfish_allergens": FoodCompound(
            name: "Shellfish Allergens",
            category: .majorAllergen,
            severity: .high,
            description: "Tropomyosin and other proteins that can cause severe allergic reactions.",
            icon: "allergens",
            color: "red"
        ),
        "ovalbumin": FoodCompound(
            name: "Ovalbumin",
            category: .majorAllergen,
            severity: .high,
            description: "Major egg protein that can cause allergic reactions and digestive issues.",
            icon: "allergens",
            color: "red"
        ),
        "avidin": FoodCompound(
            name: "Avidin",
            category: .metabolicDisruptor,
            severity: .low,
            description: "Protein that can bind biotin and reduce its absorption when eggs are raw.",
            icon: "minus.circle.fill",
            color: "yellow"
        ),
        "sodium": FoodCompound(
            name: "Sodium",
            category: .metabolicDisruptor,
            severity: .medium,
            description: "High sodium levels can contribute to hypertension and cardiovascular issues.",
            icon: "drop.fill",
            color: "orange"
        )
    ]
    
    // MARK: - Ingredient-Based Compound Mappings
    
    private let ingredientMappings: [IngredientMapping] = [
        // Grains & Wheat Products
        IngredientMapping(
            keywords: ["wheat", "flour", "bread", "pasta", "noodles", "crackers", "cereal", "oats", "barley", "rye"],
            compounds: [
                FoodCompound(name: "Gluten", category: .majorAllergen, severity: .high, description: "Storage protein complex that triggers celiac disease and non-celiac gluten sensitivity.", icon: "allergens", color: "red"),
                FoodCompound(name: "Lectins", category: .inflammatoryCompound, severity: .medium, description: "Carbohydrate-binding proteins that can cause digestive issues and inflammatory responses.", icon: "link", color: "orange"),
                FoodCompound(name: "Phytic Acid", category: .metabolicDisruptor, severity: .low, description: "Phosphorus storage compound that can bind minerals and reduce their absorption.", icon: "minus.circle.fill", color: "yellow")
            ],
            ingredientName: "Wheat/Grains"
        ),
        
        // Dairy Products
        IngredientMapping(
            keywords: ["milk", "cheese", "butter", "cream", "yogurt", "ice cream", "whey", "casein", "lactose"],
            compounds: [
                FoodCompound(name: "Casein", category: .foodIntolerance, severity: .medium, description: "Milk protein that can cause digestive issues and inflammatory responses in sensitive individuals.", icon: "drop.fill", color: "orange"),
                FoodCompound(name: "Lactose", category: .foodIntolerance, severity: .medium, description: "Milk sugar that can cause digestive issues in lactose-intolerant individuals.", icon: "drop.triangle.fill", color: "orange")
            ],
            ingredientName: "Dairy"
        ),
        
        // Nuts & Seeds
        IngredientMapping(
            keywords: ["peanut", "almond", "walnut", "cashew", "pecan", "hazelnut", "pistachio", "macadamia", "brazil nut", "pine nut", "sesame", "sunflower seed", "pumpkin seed", "chia", "flax"],
            compounds: [
                FoodCompound(name: "Aflatoxins", category: .toxicCompound, severity: .high, description: "Carcinogenic mycotoxins produced by Aspergillus molds. Found in nuts, grains, and dried fruits.", icon: "exclamationmark.triangle.fill", color: "red"),
                FoodCompound(name: "Oxalates", category: .metabolicDisruptor, severity: .medium, description: "Compounds that can bind minerals and contribute to kidney stone formation in susceptible individuals.", icon: "diamond.fill", color: "orange"),
                FoodCompound(name: "Phytic Acid", category: .metabolicDisruptor, severity: .low, description: "Phosphorus storage compound that can bind minerals and reduce their absorption.", icon: "minus.circle.fill", color: "yellow"),
                FoodCompound(name: "Lectins", category: .inflammatoryCompound, severity: .medium, description: "Carbohydrate-binding proteins that can cause digestive issues and inflammatory responses.", icon: "link", color: "orange")
            ],
            ingredientName: "Nuts/Seeds"
        ),
        
        // Nightshades
        IngredientMapping(
            keywords: ["tomato", "potato", "pepper", "eggplant", "paprika", "chili", "jalapeño", "cayenne", "bell pepper"],
            compounds: [
                FoodCompound(name: "Solanine", category: .toxicCompound, severity: .high, description: "Glycoalkaloid toxin found in nightshades. Can cause digestive issues, neurological symptoms, and cellular damage at high doses.", icon: "exclamationmark.triangle.fill", color: "red"),
                FoodCompound(name: "α-Tomatine", category: .toxicCompound, severity: .medium, description: "Glycoalkaloid found in tomatoes, particularly green tomatoes. Can cause digestive upset in sensitive individuals.", icon: "exclamationmark.triangle", color: "orange"),
                FoodCompound(name: "Capsaicin", category: .inflammatoryCompound, severity: .medium, description: "Vanillamide compound that creates heat sensation. Can irritate digestive tract and mucous membranes.", icon: "flame.fill", color: "red"),
                FoodCompound(name: "Salicylates", category: .inflammatoryCompound, severity: .medium, description: "Natural aspirin-like compounds that can trigger asthma, skin reactions, and digestive issues in sensitive individuals.", icon: "leaf.fill", color: "orange")
            ],
            ingredientName: "Nightshades"
        ),
        
        // Legumes
        IngredientMapping(
            keywords: ["beans", "lentils", "chickpeas", "peas", "soy", "tofu", "tempeh", "edamame", "peanut"],
            compounds: [
                FoodCompound(name: "Lectins", category: .inflammatoryCompound, severity: .medium, description: "Carbohydrate-binding proteins that can cause digestive issues and inflammatory responses.", icon: "link", color: "orange"),
                FoodCompound(name: "Phytic Acid", category: .metabolicDisruptor, severity: .low, description: "Phosphorus storage compound that can bind minerals and reduce their absorption.", icon: "minus.circle.fill", color: "yellow"),
                FoodCompound(name: "Oligosaccharides", category: .foodIntolerance, severity: .low, description: "Complex sugars that can cause gas and digestive discomfort.", icon: "wind", color: "yellow")
            ],
            ingredientName: "Legumes"
        ),
        
        // Fermented Foods
        IngredientMapping(
            keywords: ["vinegar", "wine", "beer", "sauerkraut", "kimchi", "pickled", "fermented", "aged", "cultured", "kefir", "kombucha"],
            compounds: [
                FoodCompound(name: "Histamine", category: .foodIntolerance, severity: .high, description: "Inflammatory compound formed during fermentation. Can trigger allergic-like reactions, headaches, and digestive issues.", icon: "allergens", color: "red"),
                FoodCompound(name: "Tyramine", category: .neurologicalTrigger, severity: .high, description: "Monoamine that can trigger migraines and hypertensive crises, especially with MAOI medications.", icon: "brain.head.profile", color: "red"),
                FoodCompound(name: "Sulfites", category: .foodIntolerance, severity: .high, description: "Preservative compounds that can trigger asthma attacks and allergic reactions in sensitive individuals.", icon: "wind", color: "red")
            ],
            ingredientName: "Fermented Foods"
        ),
        
        // Chocolate & Cocoa
        IngredientMapping(
            keywords: ["chocolate", "cocoa", "cacao", "dark chocolate", "milk chocolate"],
            compounds: [
                FoodCompound(name: "Theobromine", category: .neurologicalTrigger, severity: .low, description: "Methylxanthine found in chocolate. Can cause headaches and digestive issues in sensitive people.", icon: "heart.fill", color: "orange"),
                FoodCompound(name: "Caffeine", category: .neurologicalTrigger, severity: .low, description: "Stimulant alkaloid that can cause jitters, insomnia, and digestive issues in sensitive individuals.", icon: "bolt.fill", color: "orange"),
                FoodCompound(name: "Phenylethylamine", category: .neurologicalTrigger, severity: .medium, description: "Trace amine that can trigger migraines and mood changes in sensitive individuals.", icon: "brain.head.profile", color: "orange"),
                FoodCompound(name: "Oxalates", category: .metabolicDisruptor, severity: .medium, description: "Compounds that can bind minerals and contribute to kidney stone formation in susceptible individuals.", icon: "diamond.fill", color: "orange"),
                FoodCompound(name: "Cadmium", category: .toxicCompound, severity: .high, description: "Toxic heavy metal that can damage kidneys and bones. Found in chocolate, especially dark chocolate.", icon: "exclamationmark.triangle.fill", color: "red")
            ],
            ingredientName: "Chocolate/Cocoa"
        ),
        
        // Fish & Seafood
        IngredientMapping(
            keywords: ["fish", "salmon", "tuna", "cod", "halibut", "shrimp", "crab", "lobster", "shellfish", "sardines", "anchovies"],
            compounds: [
                FoodCompound(name: "Mercury", category: .toxicCompound, severity: .high, description: "Neurotoxic heavy metal that accumulates in large predatory fish. Can cause neurological damage.", icon: "exclamationmark.triangle.fill", color: "red"),
                FoodCompound(name: "Histamine", category: .foodIntolerance, severity: .high, description: "Can form in fish if not properly refrigerated. Causes scombroid poisoning.", icon: "allergens", color: "red"),
                FoodCompound(name: "Shellfish Allergens", category: .majorAllergen, severity: .high, description: "Tropomyosin and other proteins that can cause severe allergic reactions.", icon: "allergens", color: "red")
            ],
            ingredientName: "Fish/Seafood"
        ),
        
        // Eggs
        IngredientMapping(
            keywords: ["egg", "eggs", "yolk", "white", "albumin"],
            compounds: [
                FoodCompound(name: "Ovalbumin", category: .majorAllergen, severity: .high, description: "Major egg protein that can cause allergic reactions and digestive issues.", icon: "allergens", color: "red"),
                FoodCompound(name: "Avidin", category: .metabolicDisruptor, severity: .low, description: "Protein that can bind biotin and reduce its absorption when eggs are raw.", icon: "minus.circle.fill", color: "yellow")
            ],
            ingredientName: "Eggs"
        ),
        
        // Processed Meats
        IngredientMapping(
            keywords: ["bacon", "ham", "sausage", "hot dog", "salami", "pepperoni", "deli meat", "processed meat"],
            compounds: [
                FoodCompound(name: "Nitrates/Nitrites", category: .toxicCompound, severity: .medium, description: "Preservatives that can form nitrosamines (potential carcinogens) and trigger headaches.", icon: "drop.triangle.fill", color: "orange"),
                FoodCompound(name: "Sodium", category: .metabolicDisruptor, severity: .medium, description: "High sodium levels can contribute to hypertension and cardiovascular issues.", icon: "drop.fill", color: "orange"),
                FoodCompound(name: "Tyramine", category: .neurologicalTrigger, severity: .high, description: "Can form in aged/cured meats and trigger migraines.", icon: "brain.head.profile", color: "red")
            ],
            ingredientName: "Processed Meats"
        ),
        
        // Coffee and Caffeine Products
        IngredientMapping(
            keywords: ["coffee", "coffee beans", "espresso", "caffeine"],
            compounds: [
                FoodCompound(name: "Caffeine", category: .neurologicalTrigger, severity: .medium, description: "Stimulant that can cause anxiety, insomnia, and dependency in sensitive individuals.", icon: "brain.head.profile", color: "orange"),
                FoodCompound(name: "Chlorogenic Acids", category: .phenolic, severity: .low, description: "Antioxidant compounds that may cause digestive upset in sensitive individuals.", icon: "leaf.fill", color: "yellow")
            ],
            ingredientName: "Coffee"
        ),
        
        // Sugar and Sweeteners
        IngredientMapping(
            keywords: ["sugar", "cane sugar", "brown sugar", "white sugar", "sucrose", "high fructose corn syrup", "corn syrup"],
            compounds: [
                FoodCompound(name: "Sucrose", category: .metabolicDisruptor, severity: .low, description: "Simple sugar that can cause blood sugar spikes and energy crashes.", icon: "drop.triangle.fill", color: "yellow"),
                FoodCompound(name: "Fructose", category: .foodIntolerance, severity: .low, description: "Fruit sugar that can cause digestive issues in people with fructose malabsorption.", icon: "drop.triangle.fill", color: "yellow")
            ],
            ingredientName: "Sugar/Sweeteners"
        ),
        
        // Spices & Seasonings
        IngredientMapping(
            keywords: ["cinnamon", "nutmeg", "cloves", "allspice", "ginger", "turmeric", "cumin", "coriander"],
            compounds: [
                FoodCompound(name: "Coumarin", category: .toxicCompound, severity: .medium, description: "Aromatic compound in cinnamon that can cause liver damage in high doses and blood thinning effects.", icon: "drop.fill", color: "orange"),
                FoodCompound(name: "Myristicin", category: .neurologicalTrigger, severity: .low, description: "Aromatic compound in nutmeg that can cause nausea and hallucinations in large amounts.", icon: "brain.head.profile", color: "yellow"),
                FoodCompound(name: "Salicylates", category: .inflammatoryCompound, severity: .medium, description: "Natural aspirin-like compounds found in many spices.", icon: "leaf.fill", color: "orange")
            ],
            ingredientName: "Spices"
        ),
        
        // Fruits (High Salicylate)
        IngredientMapping(
            keywords: ["apple", "orange", "strawberry", "grape", "cherry", "peach", "apricot", "plum", "kiwi", "pineapple"],
            compounds: [
                FoodCompound(name: "Salicylates", category: .inflammatoryCompound, severity: .medium, description: "Natural aspirin-like compounds that can trigger asthma, skin reactions, and digestive issues in sensitive individuals.", icon: "leaf.fill", color: "orange"),
                FoodCompound(name: "Fructose", category: .foodIntolerance, severity: .low, description: "Fruit sugar that can cause digestive issues in people with fructose malabsorption.", icon: "drop.triangle.fill", color: "yellow"),
                FoodCompound(name: "Patulin", category: .toxicCompound, severity: .medium, description: "Mycotoxin found in damaged fruits, especially apples. Can cause digestive and immune issues.", icon: "exclamationmark.triangle", color: "orange")
            ],
            ingredientName: "High-Salicylate Fruits"
        ),
        
        // Leafy Greens
        IngredientMapping(
            keywords: ["spinach", "kale", "chard", "lettuce", "arugula", "collard", "mustard greens"],
            compounds: [
                FoodCompound(name: "Oxalates", category: .metabolicDisruptor, severity: .medium, description: "Compounds that can bind minerals and contribute to kidney stone formation in susceptible individuals.", icon: "diamond.fill", color: "orange"),
                FoodCompound(name: "Goitrogens", category: .metabolicDisruptor, severity: .low, description: "Compounds that can interfere with thyroid function and iodine uptake.", icon: "circle.dotted", color: "yellow"),
                FoodCompound(name: "Cadmium", category: .toxicCompound, severity: .medium, description: "Toxic heavy metal that can damage kidneys and bones. Found in leafy greens.", icon: "exclamationmark.triangle.fill", color: "orange")
            ],
            ingredientName: "Leafy Greens"
        )
    ]
    
    // MARK: - Composite Food Definitions
    
    private let compositeFoods: [CompositeFood] = [
        CompositeFood(
            keywords: ["peanut butter sandwich", "pb sandwich", "peanut butter and jelly"],
            likelyIngredients: ["bread", "peanut butter", "jelly", "jam"],
            description: "Sandwich made with bread, peanut butter spread, and optional jelly/jam"
        ),
        CompositeFood(
            keywords: ["pizza", "pepperoni pizza", "cheese pizza"],
            likelyIngredients: ["wheat flour", "tomato sauce", "cheese", "pepperoni", "yeast"],
            description: "Baked flatbread with tomato sauce, cheese, and various toppings"
        ),
        CompositeFood(
            keywords: ["hamburger", "cheeseburger", "burger"],
            likelyIngredients: ["ground beef", "bun", "cheese", "lettuce", "tomato", "onion", "pickle"],
            description: "Ground meat patty served in a bun with various toppings"
        ),
        CompositeFood(
            keywords: ["chicken salad", "caesar salad", "garden salad"],
            likelyIngredients: ["lettuce", "chicken", "dressing", "croutons", "cheese", "vegetables"],
            description: "Mixed greens with protein, vegetables, and dressing"
        ),
        CompositeFood(
            keywords: ["spaghetti", "pasta with sauce", "marinara pasta"],
            likelyIngredients: ["pasta", "tomato sauce", "garlic", "herbs", "olive oil"],
            description: "Wheat pasta served with tomato-based sauce"
        ),
        CompositeFood(
            keywords: ["chocolate chip cookie", "cookies", "baked cookies"],
            likelyIngredients: ["flour", "butter", "sugar", "chocolate chips", "eggs", "vanilla"],
            description: "Baked sweet treat made with flour, sugar, and chocolate"
        ),
        CompositeFood(
            keywords: ["ice cream", "vanilla ice cream", "chocolate ice cream"],
            likelyIngredients: ["milk", "cream", "sugar", "eggs", "flavorings"],
            description: "Frozen dairy dessert with various flavors"
        ),
        CompositeFood(
            keywords: ["french fries", "fries", "potato fries"],
            likelyIngredients: ["potatoes", "oil", "salt"],
            description: "Deep-fried potato strips, often with added salt"
        ),
        CompositeFood(
            keywords: ["apple pie", "fruit pie", "baked pie"],
            likelyIngredients: ["apples", "flour", "butter", "sugar", "cinnamon", "nutmeg"],
            description: "Baked pastry with fruit filling and spiced crust"
        ),
        CompositeFood(
            keywords: ["breakfast cereal", "cereal", "corn flakes"],
            likelyIngredients: ["grains", "sugar", "milk", "vitamins", "preservatives"],
            description: "Processed grain product typically eaten with milk"
        ),
        CompositeFood(
            keywords: ["coffee cream sugar", "coffee with cream", "coffee with milk", "latte", "cappuccino", "flat white", "coffee drink"],
            likelyIngredients: ["coffee", "cream", "milk", "sugar"],
            description: "Coffee beverage with dairy and sweetener"
        ),
        CompositeFood(
            keywords: ["hot dog", "frankfurter", "wiener"],
            likelyIngredients: ["processed meat", "bun", "nitrates", "sodium", "spices"],
            description: "Processed meat sausage served in a bun"
        ),
        CompositeFood(
            keywords: ["taco", "beef taco", "chicken taco"],
            likelyIngredients: ["tortilla", "meat", "cheese", "lettuce", "tomato", "onion", "spices"],
            description: "Folded tortilla filled with meat, vegetables, and seasonings"
        )
    ]
    
    // MARK: - Legacy Food Mappings (for specific items)
    
    private let foodMappings: [FoodCompoundMapping] = [
        // Tomatoes - Complex example
        FoodCompoundMapping(
            foodKeywords: ["tomato", "tomatoes", "cherry tomato", "roma tomato", "heirloom tomato"],
            compounds: [
                FoodCompound(name: "Histamine", category: .foodIntolerance, severity: .high, description: "Inflammatory compound formed during fermentation. Can trigger allergic-like reactions, headaches, and digestive issues.", icon: "allergens", color: "red"),
                FoodCompound(name: "Salicylates", category: .inflammatoryCompound, severity: .medium, description: "Natural aspirin-like compounds that can trigger asthma, skin reactions, and digestive issues in sensitive individuals.", icon: "leaf.fill", color: "orange"),
                FoodCompound(name: "α-Tomatine", category: .toxicCompound, severity: .medium, description: "Glycoalkaloid found in tomatoes, particularly green tomatoes. Can cause digestive upset in sensitive individuals.", icon: "exclamationmark.triangle", color: "orange"),
                FoodCompound(name: "Profilins", category: .majorAllergen, severity: .high, description: "Pan-allergen proteins that cause cross-reactivity between pollens and foods. Can trigger oral allergy syndrome.", icon: "allergens", color: "red"),
                FoodCompound(name: "Lipid Transfer Proteins (LTPs)", category: .majorAllergen, severity: .high, description: "Heat-stable allergen proteins that can cause severe allergic reactions including anaphylaxis.", icon: "allergens", color: "red"),
                FoodCompound(name: "β-Fructofuranosidase (Sola l 2)", category: .majorAllergen, severity: .medium, description: "Tomato-specific allergen enzyme that can trigger allergic reactions and cross-react with birch pollen.", icon: "leaf.fill", color: "orange")
            ]
        ),
        
        // Potatoes
        FoodCompoundMapping(
            foodKeywords: ["potato", "potatoes", "sweet potato", "russet potato", "red potato"],
            compounds: [
                FoodCompound(name: "Solanine", category: .toxicCompound, severity: .high, description: "Glycoalkaloid toxin found in nightshades. Can cause digestive issues, neurological symptoms, and cellular damage at high doses.", icon: "exclamationmark.triangle.fill", color: "red"),
                FoodCompound(name: "α-Chaconine", category: .toxicCompound, severity: .high, description: "Toxic glycoalkaloid that works synergistically with solanine. Found in potatoes and can cause gastrointestinal distress.", icon: "exclamationmark.triangle.fill", color: "red"),
                FoodCompound(name: "Lectins", category: .inflammatoryCompound, severity: .medium, description: "Carbohydrate-binding proteins that can cause digestive issues and inflammatory responses.", icon: "link", color: "orange")
            ]
        ),
        
        // Peppers
        FoodCompoundMapping(
            foodKeywords: ["pepper", "bell pepper", "chili", "jalapeño", "habanero", "cayenne", "paprika"],
            compounds: [
                FoodCompound(name: "Capsaicin", category: .inflammatoryCompound, severity: .medium, description: "Vanillamide compound that creates heat sensation. Can irritate digestive tract and mucous membranes.", icon: "flame.fill", color: "red"),
                FoodCompound(name: "Salicylates", category: .inflammatoryCompound, severity: .medium, description: "Natural aspirin-like compounds that can trigger asthma, skin reactions, and digestive issues in sensitive individuals.", icon: "leaf.fill", color: "orange"),
                FoodCompound(name: "Solanine", category: .toxicCompound, severity: .medium, description: "Glycoalkaloid toxin found in nightshades. Lower levels in peppers than potatoes.", icon: "exclamationmark.triangle", color: "orange")
            ]
        ),
        
        // Chocolate
        FoodCompoundMapping(
            foodKeywords: ["chocolate", "cocoa", "cacao", "dark chocolate", "milk chocolate"],
            compounds: [
                FoodCompound(name: "Theobromine", category: .neurologicalTrigger, severity: .low, description: "Methylxanthine found in chocolate. Can cause headaches and digestive issues in sensitive people.", icon: "heart.fill", color: "orange"),
                FoodCompound(name: "Caffeine", category: .neurologicalTrigger, severity: .low, description: "Stimulant alkaloid that can cause jitters, insomnia, and digestive issues in sensitive individuals.", icon: "bolt.fill", color: "orange"),
                FoodCompound(name: "Phenylethylamine", category: .neurologicalTrigger, severity: .medium, description: "Trace amine that can trigger migraines and mood changes in sensitive individuals.", icon: "brain.head.profile", color: "orange"),
                FoodCompound(name: "Histamine", category: .foodIntolerance, severity: .medium, description: "Can be present in aged or fermented chocolate products.", icon: "allergens", color: "orange"),
                FoodCompound(name: "Oxalates", category: .metabolicDisruptor, severity: .medium, description: "Compounds that can bind minerals and contribute to kidney stone formation in susceptible individuals.", icon: "diamond.fill", color: "orange"),
                FoodCompound(name: "Cadmium", category: .toxicCompound, severity: .high, description: "Toxic heavy metal that can damage kidneys and bones. Found in chocolate, especially dark chocolate.", icon: "exclamationmark.triangle.fill", color: "red")
            ]
        ),
        
        // Aged Cheese
        FoodCompoundMapping(
            foodKeywords: ["aged cheese", "parmesan", "cheddar", "blue cheese", "gouda", "swiss"],
            compounds: [
                FoodCompound(name: "Tyramine", category: .neurologicalTrigger, severity: .high, description: "Monoamine that can trigger migraines and hypertensive crises, especially with MAOI medications.", icon: "brain.head.profile", color: "red"),
                FoodCompound(name: "Histamine", category: .foodIntolerance, severity: .high, description: "Inflammatory compound formed during fermentation. Can trigger allergic-like reactions, headaches, and digestive issues.", icon: "allergens", color: "red"),
                FoodCompound(name: "Putrescine", category: .foodIntolerance, severity: .medium, description: "Polyamine formed during protein breakdown. Can enhance histamine toxicity and cause digestive issues.", icon: "multiply.circle.fill", color: "orange"),
                FoodCompound(name: "Casein", category: .foodIntolerance, severity: .medium, description: "Milk protein that can cause digestive issues and inflammatory responses in sensitive individuals.", icon: "drop.fill", color: "orange")
            ]
        ),
        
        // Tuna
        FoodCompoundMapping(
            foodKeywords: ["tuna", "albacore", "yellowfin", "bluefin"],
            compounds: [
                FoodCompound(name: "Mercury", category: .toxicCompound, severity: .high, description: "Neurotoxic heavy metal that accumulates in large predatory fish. Can cause neurological damage.", icon: "exclamationmark.triangle.fill", color: "red"),
                FoodCompound(name: "Histamine", category: .foodIntolerance, severity: .high, description: "Can form in fish if not properly refrigerated. Causes scombroid poisoning.", icon: "allergens", color: "red")
            ]
        ),
        
        // Rice
        FoodCompoundMapping(
            foodKeywords: ["rice", "brown rice", "white rice", "jasmine rice", "basmati rice"],
            compounds: [
                FoodCompound(name: "Arsenic", category: .toxicCompound, severity: .high, description: "Carcinogenic metalloid commonly found in rice and rice products. Can cause skin lesions and cancer.", icon: "exclamationmark.triangle.fill", color: "red"),
                FoodCompound(name: "Lectins", category: .inflammatoryCompound, severity: .medium, description: "Carbohydrate-binding proteins that can cause digestive issues and inflammatory responses.", icon: "link", color: "orange"),
                FoodCompound(name: "Phytic Acid", category: .metabolicDisruptor, severity: .low, description: "Phosphorus storage compound that can bind minerals and reduce their absorption.", icon: "minus.circle.fill", color: "yellow")
            ]
        ),
        
        // Spinach
        FoodCompoundMapping(
            foodKeywords: ["spinach"],
            compounds: [
                FoodCompound(name: "Oxalates", category: .metabolicDisruptor, severity: .medium, description: "Compounds that can bind minerals and contribute to kidney stone formation in susceptible individuals.", icon: "diamond.fill", color: "orange"),
                FoodCompound(name: "Histamine", category: .foodIntolerance, severity: .medium, description: "Can be present in aged spinach or spinach products.", icon: "allergens", color: "orange"),
                FoodCompound(name: "Goitrogens", category: .metabolicDisruptor, severity: .low, description: "Compounds that can interfere with thyroid function and iodine uptake.", icon: "circle.dotted", color: "yellow"),
                FoodCompound(name: "Cadmium", category: .toxicCompound, severity: .medium, description: "Toxic heavy metal that can damage kidneys and bones. Found in leafy greens.", icon: "exclamationmark.triangle.fill", color: "orange")
            ]
        ),
        
        // Wine
        FoodCompoundMapping(
            foodKeywords: ["wine", "red wine", "white wine", "champagne"],
            compounds: [
                FoodCompound(name: "Histamine", category: .foodIntolerance, severity: .high, description: "Inflammatory compound formed during fermentation. Can trigger allergic-like reactions, headaches, and digestive issues.", icon: "allergens", color: "red"),
                FoodCompound(name: "Tyramine", category: .neurologicalTrigger, severity: .high, description: "Monoamine that can trigger migraines and hypertensive crises, especially with MAOI medications.", icon: "brain.head.profile", color: "red"),
                FoodCompound(name: "Sulfites", category: .foodIntolerance, severity: .high, description: "Preservative compounds that can trigger asthma attacks and allergic reactions in sensitive individuals.", icon: "wind", color: "red"),
                FoodCompound(name: "Salicylates", category: .inflammatoryCompound, severity: .medium, description: "Natural aspirin-like compounds that can trigger asthma, skin reactions, and digestive issues in sensitive individuals.", icon: "leaf.fill", color: "orange"),
                FoodCompound(name: "Tannins", category: .metabolicDisruptor, severity: .low, description: "Polyphenolic compounds that can interfere with iron absorption and cause digestive irritation.", icon: "drop.fill", color: "yellow")
            ]
        ),
        
        // Apple Pie - Complex dessert with multiple compound sources
        FoodCompoundMapping(
            foodKeywords: ["apple pie", "apple tart", "apple crisp", "apple cobbler", "baked apple"],
            compounds: [
                // From Apples
                FoodCompound(name: "Patulin", category: .toxicCompound, severity: .medium, description: "Mycotoxin found in damaged apples and apple products. Can cause digestive and immune issues in sensitive individuals.", icon: "exclamationmark.triangle", color: "orange"),
                FoodCompound(name: "Salicylates", category: .inflammatoryCompound, severity: .medium, description: "Natural aspirin-like compounds found in apples that can trigger asthma, skin reactions, and digestive issues.", icon: "leaf.fill", color: "orange"),
                FoodCompound(name: "Quercetin", category: .inflammatoryCompound, severity: .low, description: "Flavonoid in apple peels that can cause headaches and interact with certain medications in high doses.", icon: "sparkles", color: "yellow"),
                
                // From Wheat Crust
                FoodCompound(name: "Gluten", category: .majorAllergen, severity: .high, description: "Storage protein complex in wheat flour that triggers celiac disease and non-celiac gluten sensitivity.", icon: "allergens", color: "red"),
                FoodCompound(name: "Lectins", category: .inflammatoryCompound, severity: .medium, description: "Carbohydrate-binding proteins in wheat that can cause digestive issues and inflammatory responses.", icon: "link", color: "orange"),
                FoodCompound(name: "Phytic Acid", category: .metabolicDisruptor, severity: .low, description: "Phosphorus storage compound in wheat that can bind minerals and reduce their absorption.", icon: "minus.circle.fill", color: "yellow"),
                
                // From Spices (Cinnamon, Nutmeg)
                FoodCompound(name: "Coumarin", category: .toxicCompound, severity: .medium, description: "Aromatic compound in cinnamon that can cause liver damage in high doses and blood thinning effects.", icon: "drop.fill", color: "orange"),
                FoodCompound(name: "Myristicin", category: .neurologicalTrigger, severity: .low, description: "Aromatic compound in nutmeg that can cause nausea and hallucinations in large amounts.", icon: "brain.head.profile", color: "yellow"),
                
                // Processing & Baking Compounds
                FoodCompound(name: "Acrylamide", category: .toxicCompound, severity: .high, description: "Carcinogenic compound formed during high-temperature baking of starchy foods like pie crust.", icon: "exclamationmark.triangle.fill", color: "red"),
                FoodCompound(name: "Advanced Glycation End Products (AGEs)", category: .inflammatoryCompound, severity: .medium, description: "Inflammatory compounds formed during baking that can contribute to aging and chronic disease.", icon: "flame.fill", color: "orange"),
                
                // From Sugar & Butter
                FoodCompound(name: "Trans Fats", category: .toxicCompound, severity: .high, description: "Artificial fats that can form during processing and increase cardiovascular disease risk.", icon: "heart.slash.fill", color: "red"),
                FoodCompound(name: "Saturated Fats", category: .metabolicDisruptor, severity: .low, description: "High levels can contribute to inflammation and cardiovascular issues in sensitive individuals.", icon: "drop.circle.fill", color: "yellow")
            ]
        )
    ]
    
    // MARK: - Public Methods
    
    /// Main method to analyze any food item and return detected compounds
    func getCompoundsForFood(name: String, ingredients: [String]) -> [FoodCompound] {
        let allIngredients = getIngredientsForFood(name: name, providedIngredients: ingredients)
        return analyzeIngredients(allIngredients)
    }
    
    /// Get likely ingredients for a food item (including breaking down composite foods)
    func getIngredientsForFood(name: String, providedIngredients: [String]) -> [String] {
        var allIngredients = providedIngredients
        let searchText = name.lowercased()
        
        // Check if this is a composite food we know about
        for compositeFood in compositeFoods {
            for keyword in compositeFood.keywords {
                if searchText.contains(keyword.lowercased()) {
                    allIngredients.append(contentsOf: compositeFood.likelyIngredients)
                    break
                }
            }
        }
        
        // If no specific ingredients provided and no composite match, try to infer from name
        if allIngredients.isEmpty {
            allIngredients = inferIngredientsFromName(name)
        }
        
        return Array(Set(allIngredients)) // Remove duplicates
    }
    
    /// Analyze a list of ingredients and return all detected compounds
    func analyzeIngredients(_ ingredients: [String]) -> [FoodCompound] {
        var detectedCompounds: [FoodCompound] = []
        
        for ingredient in ingredients {
            let ingredientLower = ingredient.lowercased()
            
            // Check each ingredient mapping
            for mapping in ingredientMappings {
                for keyword in mapping.keywords {
                    if ingredientLower.contains(keyword.lowercased()) {
                        detectedCompounds.append(contentsOf: mapping.compounds)
                        break // Only add once per mapping
                    }
                }
            }
            
            // Check for processing-related compounds
            if ingredientLower.contains("fried") || ingredientLower.contains("baked") || ingredientLower.contains("grilled") {
                detectedCompounds.append(FoodCompound(
                    name: "Acrylamide",
                    category: .naturalToxin,
                    severity: .high,
                    description: "Carcinogenic compound formed during high-temperature cooking of starchy foods.",
                    icon: "exclamationmark.triangle.fill",
                    color: "red"
                ))
                detectedCompounds.append(FoodCompound(
                    name: "Advanced Glycation End Products (AGEs)",
                    category: .naturalToxin,
                    severity: .medium,
                    description: "Inflammatory compounds formed during high-temperature cooking.",
                    icon: "flame.fill",
                    color: "orange"
                ))
            }
            
            if ingredientLower.contains("oil") || ingredientLower.contains("fat") || ingredientLower.contains("margarine") {
                detectedCompounds.append(FoodCompound(
                    name: "Trans Fats",
                    category: .preservative,
                    severity: .high,
                    description: "Artificial fats that can form during processing and increase cardiovascular disease risk.",
                    icon: "heart.slash.fill",
                    color: "red"
                ))
            }
        }
        
        return removeDuplicatesAndSort(detectedCompounds)
    }
    
    /// Get a description of what ingredients are likely in a food item
    func getFoodDescription(name: String) -> String? {
        let searchText = name.lowercased()
        
        for compositeFood in compositeFoods {
            for keyword in compositeFood.keywords {
                if searchText.contains(keyword.lowercased()) {
                    return compositeFood.description
                }
            }
        }
        return nil
    }
    
    /// Get likely ingredients list for display
    func getIngredientsList(name: String, providedIngredients: [String] = []) -> [String] {
        return getIngredientsForFood(name: name, providedIngredients: providedIngredients)
    }
    
    // MARK: - Private Helper Methods
    
    private func inferIngredientsFromName(_ name: String) -> [String] {
        var inferredIngredients: [String] = []
        let nameLower = name.lowercased()
        
        // Basic ingredient inference from common food names
        let ingredientKeywords = [
            ("bread", ["wheat flour", "yeast"]),
            ("cheese", ["milk", "cheese"]),
            ("chocolate", ["cocoa", "sugar"]),
            ("coffee", ["coffee", "coffee beans"]),
            ("tea", ["tea leaves"]),
            ("wine", ["grapes", "alcohol"]),
            ("beer", ["hops", "barley", "alcohol"]),
            ("pasta", ["wheat flour"]),
            ("rice", ["rice"]),
            ("potato", ["potatoes"]),
            ("tomato", ["tomatoes"]),
            ("apple", ["apples"]),
            ("peanut", ["peanuts"]),
            ("egg", ["eggs"]),
            ("fish", ["fish"]),
            ("chicken", ["chicken"]),
            ("beef", ["beef"]),
            ("pork", ["pork"])
        ]
        
        for (keyword, ingredients) in ingredientKeywords {
            if nameLower.contains(keyword) {
                inferredIngredients.append(contentsOf: ingredients)
            }
        }
        
        return inferredIngredients
    }
    
    private func removeDuplicatesAndSort(_ compounds: [FoodCompound]) -> [FoodCompound] {
        // Remove duplicates based on compound name
        var uniqueCompounds: [FoodCompound] = []
        var seenNames: Set<String> = []
        
        for compound in compounds {
            if !seenNames.contains(compound.name) {
                uniqueCompounds.append(compound)
                seenNames.insert(compound.name)
            }
        }
        
        // Sort by severity (high first) then by name
        return uniqueCompounds.sorted { (first, second) in
            if first.severity != second.severity {
                return first.severity.rawValue > second.severity.rawValue
            }
            return first.name < second.name
        }
    }
    
    // MARK: - Legacy Support Methods
    
    func getCompoundsByCategory(_ category: CompoundCategory) -> [FoodCompound] {
        return compounds.values.filter { $0.category == category }
    }
    
    func getAllCategories() -> [CompoundCategory] {
        return CompoundCategory.allCases
    }
    
    func getAllCompounds() -> [FoodCompound] {
        return Array(compounds.values)
    }
    
    func getCompoundByName(_ name: String) -> FoodCompound? {
        return compounds.values.first { $0.name == name }
    }
}
