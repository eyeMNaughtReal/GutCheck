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
    case alkaloid = "Alkaloids"
    case biogenicAmine = "Biogenic Amines"
    case phenolic = "Phenolic Compounds"
    case protein = "Proteins & Allergens"
    case enzyme = "Enzymes"
    case glycoside = "Glycosides"
    case heavyMetal = "Heavy Metals"
    case pesticide = "Pesticides"
    case antinutrient = "Antinutrients"
    case preservative = "Preservatives"
    case naturalToxin = "Natural Toxins"
    case fermentationProduct = "Fermentation Products"
}

struct FoodCompoundMapping {
    let foodKeywords: [String]
    let compounds: [FoodCompound]
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
            category: .alkaloid,
            severity: .high,
            description: "Glycoalkaloid toxin found in nightshades. Can cause digestive issues, neurological symptoms, and cellular damage at high doses.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "chaconine": FoodCompound(
            name: "α-Chaconine",
            category: .alkaloid,
            severity: .high,
            description: "Toxic glycoalkaloid that works synergistically with solanine. Found in potatoes and can cause gastrointestinal distress.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "tomatine": FoodCompound(
            name: "α-Tomatine",
            category: .alkaloid,
            severity: .medium,
            description: "Glycoalkaloid found in tomatoes, particularly green tomatoes. Can cause digestive upset in sensitive individuals.",
            icon: "exclamationmark.triangle",
            color: "orange"
        ),
        "capsaicin": FoodCompound(
            name: "Capsaicin",
            category: .alkaloid,
            severity: .medium,
            description: "Vanillamide compound that creates heat sensation. Can irritate digestive tract and mucous membranes.",
            icon: "flame.fill",
            color: "red"
        ),
        "caffeine": FoodCompound(
            name: "Caffeine",
            category: .alkaloid,
            severity: .low,
            description: "Stimulant alkaloid that can cause jitters, insomnia, and digestive issues in sensitive individuals.",
            icon: "bolt.fill",
            color: "orange"
        ),
        "theobromine": FoodCompound(
            name: "Theobromine",
            category: .alkaloid,
            severity: .low,
            description: "Methylxanthine found in chocolate. Can cause headaches and digestive issues in sensitive people.",
            icon: "heart.fill",
            color: "orange"
        ),
        
        // Biogenic Amines
        "histamine": FoodCompound(
            name: "Histamine",
            category: .biogenicAmine,
            severity: .high,
            description: "Inflammatory compound formed during fermentation. Can trigger allergic-like reactions, headaches, and digestive issues.",
            icon: "allergens",
            color: "red"
        ),
        "tyramine": FoodCompound(
            name: "Tyramine",
            category: .biogenicAmine,
            severity: .high,
            description: "Monoamine that can trigger migraines and hypertensive crises, especially with MAOI medications.",
            icon: "brain.head.profile",
            color: "red"
        ),
        "phenylethylamine": FoodCompound(
            name: "Phenylethylamine",
            category: .biogenicAmine,
            severity: .medium,
            description: "Trace amine that can trigger migraines and mood changes in sensitive individuals.",
            icon: "brain.head.profile",
            color: "orange"
        ),
        "putrescine": FoodCompound(
            name: "Putrescine",
            category: .biogenicAmine,
            severity: .medium,
            description: "Polyamine formed during protein breakdown. Can enhance histamine toxicity and cause digestive issues.",
            icon: "multiply.circle.fill",
            color: "orange"
        ),
        
        // Phenolic Compounds
        "salicylates": FoodCompound(
            name: "Salicylates",
            category: .phenolic,
            severity: .medium,
            description: "Natural aspirin-like compounds that can trigger asthma, skin reactions, and digestive issues in sensitive individuals.",
            icon: "leaf.fill",
            color: "orange"
        ),
        "tannins": FoodCompound(
            name: "Tannins",
            category: .phenolic,
            severity: .low,
            description: "Polyphenolic compounds that can interfere with iron absorption and cause digestive irritation.",
            icon: "drop.fill",
            color: "yellow"
        ),
        "quercetin": FoodCompound(
            name: "Quercetin",
            category: .phenolic,
            severity: .low,
            description: "Flavonoid that can cause headaches and interact with certain medications in high doses.",
            icon: "sparkles",
            color: "yellow"
        ),
        
        // Proteins & Allergens
        "profilins": FoodCompound(
            name: "Profilins",
            category: .protein,
            severity: .high,
            description: "Pan-allergen proteins that cause cross-reactivity between pollens and foods. Can trigger oral allergy syndrome.",
            icon: "allergens",
            color: "red"
        ),
        "lipidTransferProteins": FoodCompound(
            name: "Lipid Transfer Proteins (LTPs)",
            category: .protein,
            severity: .high,
            description: "Heat-stable allergen proteins that can cause severe allergic reactions including anaphylaxis.",
            icon: "allergens",
            color: "red"
        ),
        "lectins": FoodCompound(
            name: "Lectins",
            category: .protein,
            severity: .medium,
            description: "Carbohydrate-binding proteins that can cause digestive issues and inflammatory responses.",
            icon: "link",
            color: "orange"
        ),
        "gluten": FoodCompound(
            name: "Gluten",
            category: .protein,
            severity: .high,
            description: "Storage protein complex that triggers celiac disease and non-celiac gluten sensitivity.",
            icon: "allergens",
            color: "red"
        ),
        "casein": FoodCompound(
            name: "Casein",
            category: .protein,
            severity: .medium,
            description: "Milk protein that can cause digestive issues and inflammatory responses in sensitive individuals.",
            icon: "drop.fill",
            color: "orange"
        ),
        
        // Enzymes
        "betaFructofuranosidase": FoodCompound(
            name: "β-Fructofuranosidase (Sola l 2)",
            category: .enzyme,
            severity: .medium,
            description: "Tomato-specific allergen enzyme that can trigger allergic reactions and cross-react with birch pollen.",
            icon: "leaf.fill",
            color: "orange"
        ),
        "bromelain": FoodCompound(
            name: "Bromelain",
            category: .enzyme,
            severity: .low,
            description: "Proteolytic enzyme in pineapple that can cause mouth irritation and digestive upset.",
            icon: "scissors",
            color: "yellow"
        ),
        "ficin": FoodCompound(
            name: "Ficin",
            category: .enzyme,
            severity: .low,
            description: "Proteolytic enzyme in figs that can cause skin and mouth irritation.",
            icon: "scissors",
            color: "yellow"
        ),
        
        // Antinutrients
        "oxalates": FoodCompound(
            name: "Oxalates",
            category: .antinutrient,
            severity: .medium,
            description: "Compounds that can bind minerals and contribute to kidney stone formation in susceptible individuals.",
            icon: "diamond.fill",
            color: "orange"
        ),
        "phyticAcid": FoodCompound(
            name: "Phytic Acid",
            category: .antinutrient,
            severity: .low,
            description: "Phosphorus storage compound that can bind minerals and reduce their absorption.",
            icon: "minus.circle.fill",
            color: "yellow"
        ),
        "goitrogens": FoodCompound(
            name: "Goitrogens",
            category: .antinutrient,
            severity: .medium,
            description: "Compounds that can interfere with thyroid function and iodine uptake.",
            icon: "circle.dotted",
            color: "orange"
        ),
        
        // Heavy Metals
        "mercury": FoodCompound(
            name: "Mercury",
            category: .heavyMetal,
            severity: .high,
            description: "Neurotoxic heavy metal that accumulates in large predatory fish. Can cause neurological damage.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "lead": FoodCompound(
            name: "Lead",
            category: .heavyMetal,
            severity: .high,
            description: "Toxic heavy metal found in some foods. Can cause neurological damage, especially in children.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "cadmium": FoodCompound(
            name: "Cadmium",
            category: .heavyMetal,
            severity: .high,
            description: "Toxic heavy metal that can damage kidneys and bones. Found in leafy greens and organ meats.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "arsenic": FoodCompound(
            name: "Arsenic",
            category: .heavyMetal,
            severity: .high,
            description: "Carcinogenic metalloid commonly found in rice and rice products. Can cause skin lesions and cancer.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        
        // Preservatives & Additives
        "sulfites": FoodCompound(
            name: "Sulfites",
            category: .preservative,
            severity: .high,
            description: "Preservative compounds that can trigger asthma attacks and allergic reactions in sensitive individuals.",
            icon: "wind",
            color: "red"
        ),
        "nitrates": FoodCompound(
            name: "Nitrates/Nitrites",
            category: .preservative,
            severity: .medium,
            description: "Preservatives that can form nitrosamines (potential carcinogens) and trigger headaches.",
            icon: "drop.triangle.fill",
            color: "orange"
        ),
        "msg": FoodCompound(
            name: "Monosodium Glutamate (MSG)",
            category: .preservative,
            severity: .low,
            description: "Flavor enhancer that can cause headaches and flushing in sensitive individuals.",
            icon: "sparkles",
            color: "yellow"
        ),
        
        // Natural Toxins
        "aflatoxins": FoodCompound(
            name: "Aflatoxins",
            category: .naturalToxin,
            severity: .high,
            description: "Carcinogenic mycotoxins produced by Aspergillus molds. Found in nuts, grains, and dried fruits.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "patulin": FoodCompound(
            name: "Patulin",
            category: .naturalToxin,
            severity: .medium,
            description: "Mycotoxin found in damaged apples and apple products. Can cause digestive and immune issues.",
            icon: "exclamationmark.triangle",
            color: "orange"
        ),
        "cyanogenic_glycosides": FoodCompound(
            name: "Cyanogenic Glycosides",
            category: .naturalToxin,
            severity: .high,
            description: "Compounds that release cyanide when broken down. Found in cassava, lima beans, and stone fruit pits.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        
        // Additional compounds for Apple Pie and baked goods
        "coumarin": FoodCompound(
            name: "Coumarin",
            category: .phenolic,
            severity: .medium,
            description: "Aromatic compound in cinnamon that can cause liver damage in high doses and blood thinning effects.",
            icon: "drop.fill",
            color: "orange"
        ),
        "myristicin": FoodCompound(
            name: "Myristicin",
            category: .phenolic,
            severity: .low,
            description: "Aromatic compound in nutmeg that can cause nausea and hallucinations in large amounts.",
            icon: "brain.head.profile",
            color: "yellow"
        ),
        "acrylamide": FoodCompound(
            name: "Acrylamide",
            category: .naturalToxin,
            severity: .high,
            description: "Carcinogenic compound formed during high-temperature baking of starchy foods like pie crust.",
            icon: "exclamationmark.triangle.fill",
            color: "red"
        ),
        "advanced_glycation_end_products": FoodCompound(
            name: "Advanced Glycation End Products (AGEs)",
            category: .naturalToxin,
            severity: .medium,
            description: "Inflammatory compounds formed during baking that can contribute to aging and chronic disease.",
            icon: "flame.fill",
            color: "orange"
        ),
        "trans_fats": FoodCompound(
            name: "Trans Fats",
            category: .preservative,
            severity: .high,
            description: "Artificial fats that can form during processing and increase cardiovascular disease risk.",
            icon: "heart.slash.fill",
            color: "red"
        ),
        "saturated_fats": FoodCompound(
            name: "Saturated Fats",
            category: .preservative,
            severity: .low,
            description: "High levels can contribute to inflammation and cardiovascular issues in sensitive individuals.",
            icon: "drop.circle.fill",
            color: "yellow"
        )
    ]
    
    // MARK: - Food-Compound Mappings
    
    private let foodMappings: [FoodCompoundMapping] = [
        // Tomatoes - Complex example
        FoodCompoundMapping(
            foodKeywords: ["tomato", "tomatoes", "cherry tomato", "roma tomato", "heirloom tomato"],
            compounds: [
                FoodCompound(name: "Histamine", category: .biogenicAmine, severity: .high, description: "Inflammatory compound formed during fermentation. Can trigger allergic-like reactions, headaches, and digestive issues.", icon: "allergens", color: "red"),
                FoodCompound(name: "Salicylates", category: .phenolic, severity: .medium, description: "Natural aspirin-like compounds that can trigger asthma, skin reactions, and digestive issues in sensitive individuals.", icon: "leaf.fill", color: "orange"),
                FoodCompound(name: "α-Tomatine", category: .alkaloid, severity: .medium, description: "Glycoalkaloid found in tomatoes, particularly green tomatoes. Can cause digestive upset in sensitive individuals.", icon: "exclamationmark.triangle", color: "orange"),
                FoodCompound(name: "Profilins", category: .protein, severity: .high, description: "Pan-allergen proteins that cause cross-reactivity between pollens and foods. Can trigger oral allergy syndrome.", icon: "allergens", color: "red"),
                FoodCompound(name: "Lipid Transfer Proteins (LTPs)", category: .protein, severity: .high, description: "Heat-stable allergen proteins that can cause severe allergic reactions including anaphylaxis.", icon: "allergens", color: "red"),
                FoodCompound(name: "β-Fructofuranosidase (Sola l 2)", category: .enzyme, severity: .medium, description: "Tomato-specific allergen enzyme that can trigger allergic reactions and cross-react with birch pollen.", icon: "leaf.fill", color: "orange")
            ]
        ),
        
        // Potatoes
        FoodCompoundMapping(
            foodKeywords: ["potato", "potatoes", "sweet potato", "russet potato", "red potato"],
            compounds: [
                FoodCompound(name: "Solanine", category: .alkaloid, severity: .high, description: "Glycoalkaloid toxin found in nightshades. Can cause digestive issues, neurological symptoms, and cellular damage at high doses.", icon: "exclamationmark.triangle.fill", color: "red"),
                FoodCompound(name: "α-Chaconine", category: .alkaloid, severity: .high, description: "Toxic glycoalkaloid that works synergistically with solanine. Found in potatoes and can cause gastrointestinal distress.", icon: "exclamationmark.triangle.fill", color: "red"),
                FoodCompound(name: "Lectins", category: .protein, severity: .medium, description: "Carbohydrate-binding proteins that can cause digestive issues and inflammatory responses.", icon: "link", color: "orange")
            ]
        ),
        
        // Peppers
        FoodCompoundMapping(
            foodKeywords: ["pepper", "bell pepper", "chili", "jalapeño", "habanero", "cayenne", "paprika"],
            compounds: [
                FoodCompound(name: "Capsaicin", category: .alkaloid, severity: .medium, description: "Vanillamide compound that creates heat sensation. Can irritate digestive tract and mucous membranes.", icon: "flame.fill", color: "red"),
                FoodCompound(name: "Salicylates", category: .phenolic, severity: .medium, description: "Natural aspirin-like compounds that can trigger asthma, skin reactions, and digestive issues in sensitive individuals.", icon: "leaf.fill", color: "orange"),
                FoodCompound(name: "Solanine", category: .alkaloid, severity: .medium, description: "Glycoalkaloid toxin found in nightshades. Lower levels in peppers than potatoes.", icon: "exclamationmark.triangle", color: "orange")
            ]
        ),
        
        // Chocolate
        FoodCompoundMapping(
            foodKeywords: ["chocolate", "cocoa", "cacao", "dark chocolate", "milk chocolate"],
            compounds: [
                FoodCompound(name: "Theobromine", category: .alkaloid, severity: .low, description: "Methylxanthine found in chocolate. Can cause headaches and digestive issues in sensitive people.", icon: "heart.fill", color: "orange"),
                FoodCompound(name: "Caffeine", category: .alkaloid, severity: .low, description: "Stimulant alkaloid that can cause jitters, insomnia, and digestive issues in sensitive individuals.", icon: "bolt.fill", color: "orange"),
                FoodCompound(name: "Phenylethylamine", category: .biogenicAmine, severity: .medium, description: "Trace amine that can trigger migraines and mood changes in sensitive individuals.", icon: "brain.head.profile", color: "orange"),
                FoodCompound(name: "Histamine", category: .biogenicAmine, severity: .medium, description: "Can be present in aged or fermented chocolate products.", icon: "allergens", color: "orange"),
                FoodCompound(name: "Oxalates", category: .antinutrient, severity: .medium, description: "Compounds that can bind minerals and contribute to kidney stone formation in susceptible individuals.", icon: "diamond.fill", color: "orange"),
                FoodCompound(name: "Cadmium", category: .heavyMetal, severity: .high, description: "Toxic heavy metal that can damage kidneys and bones. Found in chocolate, especially dark chocolate.", icon: "exclamationmark.triangle.fill", color: "red")
            ]
        ),
        
        // Aged Cheese
        FoodCompoundMapping(
            foodKeywords: ["aged cheese", "parmesan", "cheddar", "blue cheese", "gouda", "swiss"],
            compounds: [
                FoodCompound(name: "Tyramine", category: .biogenicAmine, severity: .high, description: "Monoamine that can trigger migraines and hypertensive crises, especially with MAOI medications.", icon: "brain.head.profile", color: "red"),
                FoodCompound(name: "Histamine", category: .biogenicAmine, severity: .high, description: "Inflammatory compound formed during fermentation. Can trigger allergic-like reactions, headaches, and digestive issues.", icon: "allergens", color: "red"),
                FoodCompound(name: "Putrescine", category: .biogenicAmine, severity: .medium, description: "Polyamine formed during protein breakdown. Can enhance histamine toxicity and cause digestive issues.", icon: "multiply.circle.fill", color: "orange"),
                FoodCompound(name: "Casein", category: .protein, severity: .medium, description: "Milk protein that can cause digestive issues and inflammatory responses in sensitive individuals.", icon: "drop.fill", color: "orange")
            ]
        ),
        
        // Tuna
        FoodCompoundMapping(
            foodKeywords: ["tuna", "albacore", "yellowfin", "bluefin"],
            compounds: [
                FoodCompound(name: "Mercury", category: .heavyMetal, severity: .high, description: "Neurotoxic heavy metal that accumulates in large predatory fish. Can cause neurological damage.", icon: "exclamationmark.triangle.fill", color: "red"),
                FoodCompound(name: "Histamine", category: .biogenicAmine, severity: .high, description: "Can form in fish if not properly refrigerated. Causes scombroid poisoning.", icon: "allergens", color: "red")
            ]
        ),
        
        // Rice
        FoodCompoundMapping(
            foodKeywords: ["rice", "brown rice", "white rice", "jasmine rice", "basmati rice"],
            compounds: [
                FoodCompound(name: "Arsenic", category: .heavyMetal, severity: .high, description: "Carcinogenic metalloid commonly found in rice and rice products. Can cause skin lesions and cancer.", icon: "exclamationmark.triangle.fill", color: "red"),
                FoodCompound(name: "Lectins", category: .protein, severity: .medium, description: "Carbohydrate-binding proteins that can cause digestive issues and inflammatory responses.", icon: "link", color: "orange"),
                FoodCompound(name: "Phytic Acid", category: .antinutrient, severity: .low, description: "Phosphorus storage compound that can bind minerals and reduce their absorption.", icon: "minus.circle.fill", color: "yellow")
            ]
        ),
        
        // Spinach
        FoodCompoundMapping(
            foodKeywords: ["spinach"],
            compounds: [
                FoodCompound(name: "Oxalates", category: .antinutrient, severity: .medium, description: "Compounds that can bind minerals and contribute to kidney stone formation in susceptible individuals.", icon: "diamond.fill", color: "orange"),
                FoodCompound(name: "Histamine", category: .biogenicAmine, severity: .medium, description: "Can be present in aged spinach or spinach products.", icon: "allergens", color: "orange"),
                FoodCompound(name: "Goitrogens", category: .antinutrient, severity: .low, description: "Compounds that can interfere with thyroid function and iodine uptake.", icon: "circle.dotted", color: "yellow"),
                FoodCompound(name: "Cadmium", category: .heavyMetal, severity: .medium, description: "Toxic heavy metal that can damage kidneys and bones. Found in leafy greens.", icon: "exclamationmark.triangle.fill", color: "orange")
            ]
        ),
        
        // Wine
        FoodCompoundMapping(
            foodKeywords: ["wine", "red wine", "white wine", "champagne"],
            compounds: [
                FoodCompound(name: "Histamine", category: .biogenicAmine, severity: .high, description: "Inflammatory compound formed during fermentation. Can trigger allergic-like reactions, headaches, and digestive issues.", icon: "allergens", color: "red"),
                FoodCompound(name: "Tyramine", category: .biogenicAmine, severity: .high, description: "Monoamine that can trigger migraines and hypertensive crises, especially with MAOI medications.", icon: "brain.head.profile", color: "red"),
                FoodCompound(name: "Sulfites", category: .preservative, severity: .high, description: "Preservative compounds that can trigger asthma attacks and allergic reactions in sensitive individuals.", icon: "wind", color: "red"),
                FoodCompound(name: "Salicylates", category: .phenolic, severity: .medium, description: "Natural aspirin-like compounds that can trigger asthma, skin reactions, and digestive issues in sensitive individuals.", icon: "leaf.fill", color: "orange"),
                FoodCompound(name: "Tannins", category: .phenolic, severity: .low, description: "Polyphenolic compounds that can interfere with iron absorption and cause digestive irritation.", icon: "drop.fill", color: "yellow")
            ]
        ),
        
        // Apple Pie - Complex dessert with multiple compound sources
        FoodCompoundMapping(
            foodKeywords: ["apple pie", "apple tart", "apple crisp", "apple cobbler", "baked apple"],
            compounds: [
                // From Apples
                FoodCompound(name: "Patulin", category: .naturalToxin, severity: .medium, description: "Mycotoxin found in damaged apples and apple products. Can cause digestive and immune issues in sensitive individuals.", icon: "exclamationmark.triangle", color: "orange"),
                FoodCompound(name: "Salicylates", category: .phenolic, severity: .medium, description: "Natural aspirin-like compounds found in apples that can trigger asthma, skin reactions, and digestive issues.", icon: "leaf.fill", color: "orange"),
                FoodCompound(name: "Quercetin", category: .phenolic, severity: .low, description: "Flavonoid in apple peels that can cause headaches and interact with certain medications in high doses.", icon: "sparkles", color: "yellow"),
                
                // From Wheat Crust
                FoodCompound(name: "Gluten", category: .protein, severity: .high, description: "Storage protein complex in wheat flour that triggers celiac disease and non-celiac gluten sensitivity.", icon: "allergens", color: "red"),
                FoodCompound(name: "Lectins", category: .protein, severity: .medium, description: "Carbohydrate-binding proteins in wheat that can cause digestive issues and inflammatory responses.", icon: "link", color: "orange"),
                FoodCompound(name: "Phytic Acid", category: .antinutrient, severity: .low, description: "Phosphorus storage compound in wheat that can bind minerals and reduce their absorption.", icon: "minus.circle.fill", color: "yellow"),
                
                // From Spices (Cinnamon, Nutmeg)
                FoodCompound(name: "Coumarin", category: .phenolic, severity: .medium, description: "Aromatic compound in cinnamon that can cause liver damage in high doses and blood thinning effects.", icon: "drop.fill", color: "orange"),
                FoodCompound(name: "Myristicin", category: .phenolic, severity: .low, description: "Aromatic compound in nutmeg that can cause nausea and hallucinations in large amounts.", icon: "brain.head.profile", color: "yellow"),
                
                // Processing & Baking Compounds
                FoodCompound(name: "Acrylamide", category: .naturalToxin, severity: .high, description: "Carcinogenic compound formed during high-temperature baking of starchy foods like pie crust.", icon: "exclamationmark.triangle.fill", color: "red"),
                FoodCompound(name: "Advanced Glycation End Products (AGEs)", category: .naturalToxin, severity: .medium, description: "Inflammatory compounds formed during baking that can contribute to aging and chronic disease.", icon: "flame.fill", color: "orange"),
                
                // From Sugar & Butter
                FoodCompound(name: "Trans Fats", category: .preservative, severity: .high, description: "Artificial fats that can form during processing and increase cardiovascular disease risk.", icon: "heart.slash.fill", color: "red"),
                FoodCompound(name: "Saturated Fats", category: .preservative, severity: .low, description: "High levels can contribute to inflammation and cardiovascular issues in sensitive individuals.", icon: "drop.circle.fill", color: "yellow")
            ]
        )
    ]
    
    // MARK: - Public Methods
    
    func getCompoundsForFood(name: String, ingredients: [String]) -> [FoodCompound] {
        var detectedCompounds: [FoodCompound] = []
        let searchText = ([name] + ingredients).joined(separator: " ").lowercased()
        
        for mapping in foodMappings {
            for keyword in mapping.foodKeywords {
                if searchText.contains(keyword.lowercased()) {
                    detectedCompounds.append(contentsOf: mapping.compounds)
                    break // Only add once per mapping
                }
            }
        }
        
        // Remove duplicates based on compound name
        var uniqueCompounds: [FoodCompound] = []
        var seenNames: Set<String> = []
        
        for compound in detectedCompounds {
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
    
    func getCompoundsByCategory(_ category: CompoundCategory) -> [FoodCompound] {
        return compounds.values.filter { $0.category == category }
    }
    
    func getAllCategories() -> [CompoundCategory] {
        return CompoundCategory.allCases
    }
}
