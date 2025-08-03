//
//  UnifiedFoodDetailView.swift
//  GutCheck
//
//  Unified food detail view supporting all presentation modes

import SwiftUI

struct UnifiedFoodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var foodItem: FoodItem
    @State private var servingMultiplier: Double = 1.0
    @State private var customQuantity: String = ""
    @StateObject private var detailService = FoodDetailService.shared
    
    private let config: FoodDetailConfig
    private let baseNutrition: NutritionInfo
    private let baseQuantity: String
    private let onUpdate: ((FoodItem) -> Void)?
    
    init(foodItem: FoodItem, style: FoodDetailStyle = .standard, onUpdate: ((FoodItem) -> Void)? = nil) {
        self._foodItem = State(initialValue: foodItem)
        self.config = FoodDetailConfig.config(for: style)
        self.baseNutrition = foodItem.nutrition
        self.baseQuantity = foodItem.quantity
        self._customQuantity = State(initialValue: foodItem.quantity)
        self.onUpdate = onUpdate
        
        // Try to detect if this is already an adjusted serving size
        // Look for the "× " pattern in the quantity string
        if foodItem.quantity.contains("×") {
            let components = foodItem.quantity.components(separatedBy: "×")
            if let multiplierString = components.first?.trimmingCharacters(in: .whitespaces),
               let detectedMultiplier = Double(multiplierString) {
                self._servingMultiplier = State(initialValue: detectedMultiplier)
            }
        }
    }
    
    var body: some View {
        switch config.style {
        case .compact:
            compactView
        case .standard, .full, .nutrition:
            fullDetailView
        }
    }
    
    // MARK: - Compact View (for lists)
    
    private var compactView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(foodItem.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                if config.allowEditing {
                    // Edit/Delete buttons would go here
                }
            }
            
            Text(foodItem.quantity)
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
            
            // Unified nutrition display
            unifiedNutritionCompact
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Full Detail View
    
    private var fullDetailView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    foodHeaderSection
                    
                    if config.showServingControls {
                        servingSizeSection
                    }
                    
                    nutritionSection
                    
                    // Health indicators section
                    if config.showDetailedSections {
                        healthIndicatorsSection
                    }
                    
                    if config.showDetailedSections {
                        detailSectionsLinks
                    }
                    
                    if config.showAddToMeal {
                        addToMealButton
                    }
                }
                .padding()
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $detailService.showingNutritionDetails) {
                NutritionDetailsView(foodItem: foodItem)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $detailService.showingIngredients) {
                IngredientsView(ingredients: foodItem.ingredients)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $detailService.showingAllergens) {
                AllergensView(allergens: foodItem.allergens)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: servingMultiplier) { _, newValue in
                updateNutritionForServing(multiplier: newValue)
            }
        }
    }
    
    // MARK: - Unified Components
    
    private var foodHeaderSection: some View {
        VStack(spacing: 12) {
            // Food image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(ColorTheme.accent.opacity(0.2))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 48))
                            .foregroundColor(ColorTheme.accent)
                        Text("Food Image")
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                )
            
            VStack(spacing: 8) {
                Text(foodItem.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                    .multilineTextAlignment(.center)
                
                if let brand = foodItem.nutritionDetails["brand"] {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.accent)
                }
                
                sourceIndicator
            }
        }
    }
    
    private var sourceIndicator: some View {
        HStack {
            Text("Source:")
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
            
            Text(sourceDescription)
                .font(.caption)
                .foregroundColor(ColorTheme.primary)
        }
    }
    
    private var sourceDescription: String {
        switch foodItem.source {
        case .manual: return "Manual entry"
        case .barcode: return "Barcode scan"
        case .lidar: return "LiDAR estimation"
        case .ai: return "AI recognition"
        }
    }
    
    private var servingSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Serving Size")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            HStack {
                Text("Amount:")
                    .font(.subheadline)
                
                Stepper(value: $servingMultiplier, in: 0.1...10.0, step: 0.1) {
                    Text(String(format: "%.1f", servingMultiplier))
                        .font(.headline)
                        .foregroundColor(ColorTheme.primary)
                }
            }
            .padding()
            .background(ColorTheme.surface)
            .cornerRadius(12)
            
            Text("Per \(customQuantity)")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
        }
    }
    
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Facts")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            // Use the unified nutrition summary component
            foodItem.nutrition.summaryCard(style: config.style == .nutrition ? .detailed : .standard)
        }
    }
    
    private var unifiedNutritionCompact: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Calories
            if let calories = foodItem.nutrition.calories {
                Text("\(calories) kcal")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primaryText)
            }
            
            // Macros in a compact row
            foodItem.nutrition.compactPreview()
        }
    }
    
    // MARK: - Health Indicators Section
    
    private var healthIndicatorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Indicators")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            let indicators = healthIndicators
            
            if indicators.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No health concerns detected")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(indicators, id: \.text) { indicator in
                        HealthIndicatorBadge(indicator: indicator)
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
    }
    
    private var healthIndicators: [HealthIndicator] {
        return getHealthIndicators()
    }
    
    private var detailSectionsLinks: some View {
        VStack(spacing: 12) {
            // Full nutrition details
            Button(action: {
                detailService.showingNutritionDetails = true
            }) {
                DetailSectionRow(
                    icon: "chart.bar.fill",
                    title: "Full Nutrition Details",
                    subtitle: "View all vitamins, minerals & nutrients"
                )
            }
            
            // Ingredients
            if !foodItem.ingredients.isEmpty {
                Button(action: {
                    detailService.showingIngredients = true
                }) {
                    DetailSectionRow(
                        icon: "list.bullet",
                        title: "Ingredients",
                        subtitle: "\(foodItem.ingredients.count) ingredients"
                    )
                }
            }
            
            // Allergens
            if !foodItem.allergens.isEmpty {
                Button(action: {
                    detailService.showingAllergens = true
                }) {
                    DetailSectionRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Allergens & Warnings",
                        subtitle: "\(foodItem.allergens.count) allergens detected",
                        iconColor: ColorTheme.error
                    )
                }
            }
        }
    }
    
    private var addToMealButton: some View {
        Button(action: {
            if let onUpdate = onUpdate {
                // Editing mode: update existing item
                onUpdate(foodItem)
                dismiss()
            } else {
                // Adding mode: add new item to meal
                MealBuilderService.shared.addFoodItem(foodItem)
                dismiss()
            }
        }) {
            Text(onUpdate != nil ? "Update Item" : "Add to Meal")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.accent)
                .cornerRadius(12)
        }
        .padding(.top)
    }
    
    // MARK: - Helper Methods
    
    private func updateNutritionForServing(multiplier: Double) {
        // Update all nutrition values based on serving multiplier
        foodItem.nutrition.calories = baseNutrition.calories.map { Int(Double($0) * multiplier) }
        foodItem.nutrition.protein = baseNutrition.protein.map { $0 * multiplier }
        foodItem.nutrition.carbs = baseNutrition.carbs.map { $0 * multiplier }
        foodItem.nutrition.fat = baseNutrition.fat.map { $0 * multiplier }
        foodItem.nutrition.fiber = baseNutrition.fiber.map { $0 * multiplier }
        foodItem.nutrition.sugar = baseNutrition.sugar.map { $0 * multiplier }
        foodItem.nutrition.sodium = baseNutrition.sodium.map { $0 * multiplier }
        
        // Update quantity description
        if multiplier == 1.0 {
            customQuantity = baseQuantity
        } else {
            customQuantity = "\(String(format: "%.1f", multiplier)) × \(baseQuantity)"
        }
        foodItem.quantity = customQuantity
    }
    
    // MARK: - Health Analysis Functions
    
    private func getHealthIndicators() -> [HealthIndicator] {
        var indicators: [HealthIndicator] = []
        
        let name = foodItem.name.lowercased()
        let ingredients = foodItem.ingredients.map { $0.lowercased() }
        
        // Mammalian products
        if let mammalianSources = getMammalianSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Mammalian",
                icon: "🐄",
                color: .orange,
                severity: .medium,
                description: "Contains mammalian products: \(mammalianSources.joined(separator: ", "))"
            ))
        }
        
        // Processed food
        if isProcessedFood(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Processed",
                icon: "🏭",
                color: .yellow,
                severity: .low,
                description: "Highly processed food"
            ))
        }
        
        // Fried food
        if isFriedFood(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Fried",
                icon: "🍟",
                color: .red,
                severity: .high,
                description: "Contains fried ingredients"
            ))
        }
        
        // High fructose corn syrup
        if containsHFCS(ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "HFCS",
                icon: "🌽",
                color: .red,
                severity: .high,
                description: "Contains high fructose corn syrup"
            ))
        }
        
        // FODMAP foods
        if isFODMAP(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "FODMAP",
                icon: "⚠️",
                color: .orange,
                severity: .medium,
                description: "May contain FODMAPs"
            ))
        }
        
        // High sodium
        if let sodium = foodItem.nutrition.sodium, sodium > 600 {
            indicators.append(HealthIndicator(
                text: "High Sodium",
                icon: "🧂",
                color: .red,
                severity: .high,
                description: "High in sodium"
            ))
        }
        
        // High sugar
        if let sugar = foodItem.nutrition.sugar, sugar > 15 {
            indicators.append(HealthIndicator(
                text: "High Sugar",
                icon: "🍯",
                color: .orange,
                severity: .medium,
                description: "High in sugar"
            ))
        }
        
        // Artificial additives
        if containsArtificialAdditives(ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Additives",
                icon: "🧪",
                color: .yellow,
                severity: .low,
                description: "Contains artificial additives"
            ))
        }
        
        // High fiber (positive indicator)
        if let fiber = foodItem.nutrition.fiber, fiber >= 5 {
            indicators.append(HealthIndicator(
                text: "High Fiber",
                icon: "🥬",
                color: .green,
                severity: .low,
                description: "Good source of fiber (≥5g)"
            ))
        }
        
        // Spicy food
        if isSpicyFood(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Spicy",
                icon: "🌶️",
                color: .orange,
                severity: .medium,
                description: "May cause digestive irritation"
            ))
        }
        
        // Caffeine
        if containsCaffeine(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Caffeine",
                icon: "☕",
                color: .orange,
                severity: .medium,
                description: "Contains caffeine"
            ))
        }
        
        // Nightshade family
        if let nightshadeSources = getNightshadeSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Nightshade",
                icon: "🍅",
                color: .orange,
                severity: .medium,
                description: "Nightshade family: \(nightshadeSources.joined(separator: ", "))"
            ))
        }
        
        // High histamine
        if let histamineSources = getHistamineSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "High Histamine",
                icon: "🔺",
                color: .red,
                severity: .high,
                description: "High histamine sources: \(histamineSources.joined(separator: ", "))"
            ))
        }
        
        // Heavy meals/toxins
        if let heavyMetalSources = getHeavyMetalSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Heavy Metals",
                icon: "⚠️",
                color: .red,
                severity: .high,
                description: "Potential heavy metal sources: \(heavyMetalSources.joined(separator: ", "))"
            ))
        }
        
        // Oxalates
        if let oxalateSources = getOxalateSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "High Oxalates",
                icon: "💎",
                color: .orange,
                severity: .medium,
                description: "High oxalate sources: \(oxalateSources.joined(separator: ", "))"
            ))
        }
        
        // Lectins
        if let lectinSources = getLectinSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Lectins",
                icon: "🫘",
                color: .orange,
                severity: .medium,
                description: "Lectin sources: \(lectinSources.joined(separator: ", "))"
            ))
        }
        
        // Phytic acid
        if let phyticAcidSources = getPhyticAcidSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Phytic Acid",
                icon: "🌾",
                color: .yellow,
                severity: .low,
                description: "Phytic acid sources: \(phyticAcidSources.joined(separator: ", "))"
            ))
        }
        
        // Goitrogens
        if let goitrogenSources = getGoitrogenSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Goitrogens",
                icon: "🦴",
                color: .orange,
                severity: .medium,
                description: "Goitrogenic compounds in: \(goitrogenSources.joined(separator: ", "))"
            ))
        }
        
        // Pesticide residues (high-risk foods)
        if let pesticideSources = getPesticideSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Pesticide Risk",
                icon: "🚫",
                color: .red,
                severity: .high,
                description: "High pesticide residue risk: \(pesticideSources.joined(separator: ", "))"
            ))
        }
        
        // Inflammatory oils
        if let inflammatoryOilSources = getInflammatoryOilSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Inflammatory Oils",
                icon: "🛢️",
                color: .red,
                severity: .high,
                description: "Inflammatory oils: \(inflammatoryOilSources.joined(separator: ", "))"
            ))
        }
        
        // Salicylates
        if let salicylateSources = getSalicylateSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Salicylates",
                icon: "🌿",
                color: .orange,
                severity: .medium,
                description: "Salicylate sources: \(salicylateSources.joined(separator: ", "))"
            ))
        }
        
        // Tyramine
        if let tyramineSources = getTyramineSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Tyramine",
                icon: "🧀",
                color: .orange,
                severity: .medium,
                description: "Tyramine sources: \(tyramineSources.joined(separator: ", "))"
            ))
        }
        
        // Sulfites
        if let sulfiteSources = getSulfiteSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "Sulfites",
                icon: "🍷",
                color: .red,
                severity: .high,
                description: "Sulfite sources: \(sulfiteSources.joined(separator: ", "))"
            ))
        }
        
        // Purines (gout risk)
        if let purineSources = getPurineSources(name: name, ingredients: ingredients) {
            indicators.append(HealthIndicator(
                text: "High Purines",
                icon: "🦐",
                color: .orange,
                severity: .medium,
                description: "High purine sources: \(purineSources.joined(separator: ", "))"
            ))
        }
        
        return indicators
    }
    
    // Helper functions for food analysis
    private func containsMammalianProducts(name: String, ingredients: [String]) -> Bool {
        let mammalianKeywords = [
            "milk", "dairy", "cheese", "butter", "cream", "yogurt", "whey", "casein",
            "beef", "pork", "lamb", "bacon", "ham", "sausage", "ground beef", "steak",
            "lactose", "milk powder", "milk solids", "condensed milk", "evaporated milk"
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ")
        return mammalianKeywords.contains { allText.contains($0) }
    }
    
    private func getMammalianSources(name: String, ingredients: [String]) -> [String]? {
        let mammalianKeywords = [
            "milk", "dairy", "cheese", "butter", "cream", "yogurt", "whey", "casein",
            "beef", "pork", "lamb", "bacon", "ham", "sausage", "ground beef", "steak",
            "lactose", "milk powder", "milk solids", "condensed milk", "evaporated milk"
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        let foundSources = mammalianKeywords.filter { allText.contains($0) }
        
        return foundSources.isEmpty ? nil : foundSources
    }
    
    private func isProcessedFood(name: String, ingredients: [String]) -> Bool {
        let processedKeywords = [
            "modified", "extract", "concentrate", "isolate", "hydrolyzed",
            "artificial", "preserved", "enriched", "fortified", "reconstituted"
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ")
        return processedKeywords.contains { allText.contains($0) } || ingredients.count > 10
    }
    
    private func isFriedFood(name: String, ingredients: [String]) -> Bool {
        let friedKeywords = [
            "fried", "deep fried", "tempura", "battered", "breaded",
            "crispy", "crunchy", "oil", "palm oil", "vegetable oil"
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ")
        return friedKeywords.contains { allText.contains($0) }
    }
    
    private func containsHFCS(ingredients: [String]) -> Bool {
        let hfcsKeywords = [
            "high fructose corn syrup", "hfcs", "corn syrup", "fructose syrup"
        ]
        
        let allText = ingredients.joined(separator: " ")
        return hfcsKeywords.contains { allText.contains($0) }
    }
    
    private func isFODMAP(name: String, ingredients: [String]) -> Bool {
        let fodmapKeywords = [
            "onion", "garlic", "wheat", "rye", "barley", "beans", "lentils",
            "apple", "pear", "mango", "watermelon", "lactose", "fructose",
            "honey", "agave", "inulin", "chicory", "artichoke"
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ")
        return fodmapKeywords.contains { allText.contains($0) }
    }
    
    private func containsArtificialAdditives(ingredients: [String]) -> Bool {
        let additiveKeywords = [
            "artificial", "flavor", "color", "preservative", "additive",
            "bht", "bha", "msg", "sodium benzoate", "potassium sorbate",
            "red dye", "yellow dye", "blue dye", "fd&c"
        ]
        
        let allText = ingredients.joined(separator: " ")
        return additiveKeywords.contains { allText.contains($0) }
    }
    
    private func isSpicyFood(name: String, ingredients: [String]) -> Bool {
        let spicyKeywords = [
            "spicy", "hot", "chili", "pepper", "jalapeno", "habanero", "serrano",
            "cayenne", "paprika", "chipotle", "poblano", "ghost pepper", "scotch bonnet",
            "curry", "wasabi", "horseradish", "ginger", "sriracha", "tabasco",
            "hot sauce", "red pepper flakes", "black pepper", "white pepper",
            "szechuan", "thai chili", "bird's eye", "carolina reaper"
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ")
        return spicyKeywords.contains { allText.contains($0) }
    }
    
    private func containsCaffeine(name: String, ingredients: [String]) -> Bool {
        let caffeineKeywords = [
            "coffee", "espresso", "cappuccino", "latte", "mocha", "caffeine",
            "tea", "green tea", "black tea", "white tea", "oolong", "matcha",
            "chocolate", "cocoa", "cacao", "dark chocolate", "milk chocolate",
            "energy drink", "red bull", "monster", "rockstar", "bang",
            "cola", "coke", "pepsi", "dr pepper", "mountain dew",
            "guarana", "yerba mate", "kola nut", "theophylline", "theobromine"
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ")
        return caffeineKeywords.contains { allText.contains($0) }
    }

    
    private func isHighHistamine(name: String, ingredients: [String]) -> Bool {
        let highHistamineKeywords = [
            // Fermented foods
            "cheese", "aged cheese", "blue cheese", "parmesan", "cheddar",
            "fermented", "sauerkraut", "kimchi", "miso", "tempeh", "natto",
            "yogurt", "kefir", "kombucha", "wine", "beer", "champagne",
            "vinegar", "pickled", "olives", "salami", "pepperoni", "sausage",
            
            // Fish and seafood
            "tuna", "mackerel", "sardines", "anchovies", "salmon", "herring",
            "shellfish", "shrimp", "crab", "lobster", "mussels", "clams",
            
            // Vegetables and fruits
            "tomato", "spinach", "eggplant", "avocado", "citrus", "strawberry",
            "banana", "pineapple", "papaya", "kiwi", "plum", "cherry",
            
            // Nuts and chocolate
            "chocolate", "cocoa", "nuts", "walnuts", "cashews", "peanuts",
            
            // Other
            "mushroom", "yeast", "sourdough", "aged", "cured", "smoked"
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        return highHistamineKeywords.contains { allText.contains($0) }
    }
    
    // MARK: - Enhanced Detection Functions (with source identification)
    
    private func getNightshadeSources(name: String, ingredients: [String]) -> [String]? {
        let nightshadeItems = [
            ("tomato", "tomatoes"),
            ("potato", "potatoes"),
            ("bell pepper", "bell peppers"),
            ("sweet pepper", "sweet peppers"),
            ("hot pepper", "hot peppers"),
            ("chili", "chili peppers"),
            ("jalapeno", "jalapeños"),
            ("serrano", "serrano peppers"),
            ("habanero", "habanero peppers"),
            ("cayenne", "cayenne pepper"),
            ("paprika", "paprika"),
            ("eggplant", "eggplant"),
            ("aubergine", "aubergine"),
            ("tobacco", "tobacco"),
            ("goji berry", "goji berries"),
            ("wolfberry", "wolfberries"),
            ("tomatillo", "tomatillos"),
            ("ground cherry", "ground cherries"),
            ("cape gooseberry", "cape gooseberries"),
            ("ashwagandha", "ashwagandha"),
            ("belladonna", "belladonna"),
            ("petunia", "petunia"),
            ("huckleberry", "huckleberries"),
            ("wonderberry", "wonderberries")
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        let foundSources = nightshadeItems.compactMap { keyword, displayName in
            allText.contains(keyword) ? displayName : nil
        }
        
        return foundSources.isEmpty ? nil : Array(Set(foundSources))
    }
    
    private func getHistamineSources(name: String, ingredients: [String]) -> [String]? {
        let histamineItems = [
            // Fermented foods
            ("cheese", "cheese"),
            ("aged cheese", "aged cheese"),
            ("blue cheese", "blue cheese"),
            ("parmesan", "parmesan"),
            ("cheddar", "cheddar"),
            ("fermented", "fermented foods"),
            ("sauerkraut", "sauerkraut"),
            ("kimchi", "kimchi"),
            ("miso", "miso"),
            ("tempeh", "tempeh"),
            ("natto", "natto"),
            ("yogurt", "yogurt"),
            ("kefir", "kefir"),
            ("kombucha", "kombucha"),
            ("wine", "wine"),
            ("beer", "beer"),
            ("champagne", "champagne"),
            ("vinegar", "vinegar"),
            ("pickled", "pickled foods"),
            ("olives", "olives"),
            ("salami", "salami"),
            ("pepperoni", "pepperoni"),
            ("sausage", "sausage"),
            
            // Fish and seafood
            ("tuna", "tuna"),
            ("mackerel", "mackerel"),
            ("sardines", "sardines"),
            ("anchovies", "anchovies"),
            ("salmon", "salmon"),
            ("herring", "herring"),
            ("shellfish", "shellfish"),
            ("shrimp", "shrimp"),
            ("crab", "crab"),
            ("lobster", "lobster"),
            ("mussels", "mussels"),
            ("clams", "clams"),
            
            // Vegetables and fruits
            ("tomato", "tomatoes"),
            ("spinach", "spinach"),
            ("eggplant", "eggplant"),
            ("avocado", "avocado"),
            ("citrus", "citrus fruits"),
            ("strawberry", "strawberries"),
            ("banana", "bananas"),
            ("pineapple", "pineapple"),
            ("papaya", "papaya"),
            ("kiwi", "kiwi"),
            ("plum", "plums"),
            ("cherry", "cherries"),
            
            // Nuts and chocolate
            ("chocolate", "chocolate"),
            ("cocoa", "cocoa"),
            ("nuts", "nuts"),
            ("walnuts", "walnuts"),
            ("cashews", "cashews"),
            ("peanuts", "peanuts"),
            
            // Other
            ("mushroom", "mushrooms"),
            ("yeast", "yeast"),
            ("sourdough", "sourdough"),
            ("aged", "aged foods"),
            ("cured", "cured foods"),
            ("smoked", "smoked foods")
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        let foundSources = histamineItems.compactMap { keyword, displayName in
            allText.contains(keyword) ? displayName : nil
        }
        
        return foundSources.isEmpty ? nil : Array(Set(foundSources))
    }
    
    private func getHeavyMetalSources(name: String, ingredients: [String]) -> [String]? {
        let heavyMetalRisks = [
            ("tuna", "tuna (mercury)"),
            ("swordfish", "swordfish (mercury)"),
            ("shark", "shark (mercury)"),
            ("king mackerel", "king mackerel (mercury)"),
            ("tilefish", "tilefish (mercury)"),
            ("marlin", "marlin (mercury)"),
            ("orange roughy", "orange roughy (mercury)"),
            ("big eye tuna", "big eye tuna (mercury)"),
            ("rice", "rice (arsenic)"),
            ("brown rice", "brown rice (arsenic)"),
            ("rice flour", "rice flour (arsenic)"),
            ("rice syrup", "rice syrup (arsenic)"),
            ("rice crackers", "rice crackers (arsenic)"),
            ("kelp", "kelp (arsenic/iodine)"),
            ("seaweed", "seaweed (arsenic/iodine)"),
            ("hijiki", "hijiki seaweed (arsenic)"),
            ("leafy greens", "leafy greens (cadmium)"),
            ("spinach", "spinach (cadmium)"),
            ("lettuce", "lettuce (cadmium)"),
            ("chocolate", "chocolate (cadmium/lead)"),
            ("cocoa", "cocoa (cadmium)"),
            ("sunflower seeds", "sunflower seeds (cadmium)"),
            ("organ meat", "organ meat (various)"),
            ("liver", "liver (various)"),
            ("kidney", "kidney (various)")
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        let foundSources = heavyMetalRisks.compactMap { keyword, displayName in
            allText.contains(keyword) ? displayName : nil
        }
        
        return foundSources.isEmpty ? nil : Array(Set(foundSources))
    }
    
    private func getOxalateSources(name: String, ingredients: [String]) -> [String]? {
        let oxalateItems = [
            ("spinach", "spinach"),
            ("rhubarb", "rhubarb"),
            ("beets", "beets"),
            ("swiss chard", "swiss chard"),
            ("nuts", "nuts"),
            ("almonds", "almonds"),
            ("cashews", "cashews"),
            ("peanuts", "peanuts"),
            ("chocolate", "chocolate"),
            ("cocoa", "cocoa"),
            ("tea", "tea"),
            ("black tea", "black tea"),
            ("green tea", "green tea"),
            ("sweet potato", "sweet potatoes"),
            ("potato", "potatoes"),
            ("okra", "okra"),
            ("collard greens", "collard greens"),
            ("kale", "kale"),
            ("turnip greens", "turnip greens"),
            ("mustard greens", "mustard greens"),
            ("beans", "beans"),
            ("soy", "soy products"),
            ("tofu", "tofu"),
            ("tempeh", "tempeh"),
            ("raspberries", "raspberries"),
            ("figs", "figs"),
            ("kiwi", "kiwi"),
            ("plums", "plums")
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        let foundSources = oxalateItems.compactMap { keyword, displayName in
            allText.contains(keyword) ? displayName : nil
        }
        
        return foundSources.isEmpty ? nil : Array(Set(foundSources))
    }
    
    private func getLectinSources(name: String, ingredients: [String]) -> [String]? {
        let lectinItems = [
            ("beans", "beans"),
            ("lentils", "lentils"),
            ("chickpeas", "chickpeas"),
            ("kidney beans", "kidney beans"),
            ("black beans", "black beans"),
            ("pinto beans", "pinto beans"),
            ("navy beans", "navy beans"),
            ("lima beans", "lima beans"),
            ("soy", "soy products"),
            ("tofu", "tofu"),
            ("tempeh", "tempeh"),
            ("peanuts", "peanuts"),
            ("cashews", "cashews"),
            ("tomato", "tomatoes"),
            ("potato", "potatoes"),
            ("eggplant", "eggplant"),
            ("bell pepper", "bell peppers"),
            ("wheat", "wheat"),
            ("barley", "barley"),
            ("rye", "rye"),
            ("oats", "oats"),
            ("quinoa", "quinoa"),
            ("brown rice", "brown rice"),
            ("corn", "corn"),
            ("chia seeds", "chia seeds"),
            ("pumpkin seeds", "pumpkin seeds"),
            ("sunflower seeds", "sunflower seeds")
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        let foundSources = lectinItems.compactMap { keyword, displayName in
            allText.contains(keyword) ? displayName : nil
        }
        
        return foundSources.isEmpty ? nil : Array(Set(foundSources))
    }
    
    private func getPhyticAcidSources(name: String, ingredients: [String]) -> [String]? {
        let phyticAcidItems = [
            ("grains", "grains"),
            ("wheat", "wheat"),
            ("rice", "rice"),
            ("oats", "oats"),
            ("barley", "barley"),
            ("rye", "rye"),
            ("quinoa", "quinoa"),
            ("beans", "beans"),
            ("lentils", "lentils"),
            ("chickpeas", "chickpeas"),
            ("nuts", "nuts"),
            ("almonds", "almonds"),
            ("walnuts", "walnuts"),
            ("pecans", "pecans"),
            ("brazil nuts", "brazil nuts"),
            ("seeds", "seeds"),
            ("sunflower seeds", "sunflower seeds"),
            ("pumpkin seeds", "pumpkin seeds"),
            ("sesame seeds", "sesame seeds"),
            ("flax seeds", "flax seeds"),
            ("chia seeds", "chia seeds"),
            ("soy", "soy products"),
            ("tofu", "tofu"),
            ("tempeh", "tempeh")
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        let foundSources = phyticAcidItems.compactMap { keyword, displayName in
            allText.contains(keyword) ? displayName : nil
        }
        
        return foundSources.isEmpty ? nil : Array(Set(foundSources))
    }
    
    private func getGoitrogenSources(name: String, ingredients: [String]) -> [String]? {
        let goitrogenItems = [
            ("broccoli", "broccoli"),
            ("cauliflower", "cauliflower"),
            ("cabbage", "cabbage"),
            ("brussels sprouts", "brussels sprouts"),
            ("kale", "kale"),
            ("collard greens", "collard greens"),
            ("turnips", "turnips"),
            ("rutabaga", "rutabaga"),
            ("radishes", "radishes"),
            ("horseradish", "horseradish"),
            ("mustard greens", "mustard greens"),
            ("watercress", "watercress"),
            ("bok choy", "bok choy"),
            ("arugula", "arugula"),
            ("soy", "soy products"),
            ("tofu", "tofu"),
            ("tempeh", "tempeh"),
            ("millet", "millet"),
            ("cassava", "cassava"),
            ("sweet potato", "sweet potatoes"),
            ("corn", "corn"),
            ("lima beans", "lima beans"),
            ("flax seeds", "flax seeds"),
            ("peanuts", "peanuts"),
            ("pine nuts", "pine nuts"),
            ("strawberries", "strawberries"),
            ("peaches", "peaches"),
            ("spinach", "spinach")
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        let foundSources = goitrogenItems.compactMap { keyword, displayName in
            allText.contains(keyword) ? displayName : nil
        }
        
        return foundSources.isEmpty ? nil : Array(Set(foundSources))
    }
    
    private func getPesticideSources(name: String, ingredients: [String]) -> [String]? {
        // Based on EWG's Dirty Dozen and other high-pesticide foods
        let pesticideRisks = [
            ("strawberries", "strawberries"),
            ("spinach", "spinach"),
            ("kale", "kale"),
            ("peaches", "peaches"),
            ("pears", "pears"),
            ("nectarines", "nectarines"),
            ("apples", "apples"),
            ("grapes", "grapes"),
            ("bell peppers", "bell peppers"),
            ("cherry tomatoes", "cherry tomatoes"),
            ("tomatoes", "tomatoes"),
            ("celery", "celery"),
            ("potatoes", "potatoes"),
            ("hot peppers", "hot peppers"),
            ("cucumber", "cucumbers"),
            ("lettuce", "lettuce"),
            ("snap peas", "snap peas"),
            ("blueberries", "blueberries"),
            ("green beans", "green beans"),
            ("plums", "plums"),
            ("cherries", "cherries"),
            ("tangerines", "tangerines"),
            ("raspberries", "raspberries"),
            ("carrots", "carrots"),
            ("winter squash", "winter squash"),
            ("summer squash", "summer squash"),
            ("broccoli", "broccoli"),
            ("snap peas", "snap peas"),
            ("sweet corn", "sweet corn (unless organic)")
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        let foundSources = pesticideRisks.compactMap { keyword, displayName in
            allText.contains(keyword) && !allText.contains("organic") ? displayName : nil
        }
        
        return foundSources.isEmpty ? nil : Array(Set(foundSources))
    }
    
    private func getInflammatoryOilSources(name: String, ingredients: [String]) -> [String]? {
        let inflammatoryOils = [
            ("vegetable oil", "vegetable oil"),
            ("soybean oil", "soybean oil"),
            ("corn oil", "corn oil"),
            ("canola oil", "canola oil"),
            ("rapeseed oil", "rapeseed oil"),
            ("sunflower oil", "sunflower oil"),
            ("safflower oil", "safflower oil"),
            ("cottonseed oil", "cottonseed oil"),
            ("peanut oil", "peanut oil"),
            ("sesame oil", "sesame oil"),
            ("palm oil", "palm oil"),
            ("margarine", "margarine"),
            ("shortening", "shortening"),
            ("hydrogenated", "hydrogenated oils"),
            ("partially hydrogenated", "partially hydrogenated oils"),
            ("trans fat", "trans fats"),
            ("interesterified", "interesterified oils")
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        let foundSources = inflammatoryOils.compactMap { keyword, displayName in
            allText.contains(keyword) ? displayName : nil
        }
        
        return foundSources.isEmpty ? nil : Array(Set(foundSources))
    }
    
    private func getSalicylateSources(name: String, ingredients: [String]) -> [String]? {
        let salicylateItems = [
            ("berries", "berries"),
            ("strawberries", "strawberries"),
            ("blueberries", "blueberries"),
            ("raspberries", "raspberries"),
            ("blackberries", "blackberries"),
            ("cherries", "cherries"),
            ("grapes", "grapes"),
            ("raisins", "raisins"),
            ("dates", "dates"),
            ("prunes", "prunes"),
            ("oranges", "oranges"),
            ("tangerines", "tangerines"),
            ("apricots", "apricots"),
            ("tomatoes", "tomatoes"),
            ("cucumber", "cucumbers"),
            ("radishes", "radishes"),
            ("peppers", "peppers"),
            ("herbs", "herbs"),
            ("mint", "mint"),
            ("oregano", "oregano"),
            ("thyme", "thyme"),
            ("rosemary", "rosemary"),
            ("sage", "sage"),
            ("dill", "dill"),
            ("tarragon", "tarragon"),
            ("bay leaves", "bay leaves"),
            ("curry", "curry"),
            ("paprika", "paprika"),
            ("turmeric", "turmeric"),
            ("cinnamon", "cinnamon"),
            ("cloves", "cloves"),
            ("ginger", "ginger"),
            ("nutmeg", "nutmeg"),
            ("almonds", "almonds"),
            ("peanuts", "peanuts"),
            ("honey", "honey"),
            ("licorice", "licorice"),
            ("peppermint", "peppermint"),
            ("wintergreen", "wintergreen"),
            ("tea", "tea"),
            ("coffee", "coffee"),
            ("wine", "wine"),
            ("beer", "beer")
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        let foundSources = salicylateItems.compactMap { keyword, displayName in
            allText.contains(keyword) ? displayName : nil
        }
        
        return foundSources.isEmpty ? nil : Array(Set(foundSources))
    }
    
    private func getTyramineSources(name: String, ingredients: [String]) -> [String]? {
        let tyramineItems = [
            ("aged cheese", "aged cheese"),
            ("blue cheese", "blue cheese"),
            ("cheddar", "aged cheddar"),
            ("gouda", "aged gouda"),
            ("parmesan", "parmesan"),
            ("swiss", "aged swiss"),
            ("camembert", "camembert"),
            ("brie", "brie"),
            ("processed cheese", "processed cheese"),
            ("cured meat", "cured meats"),
            ("salami", "salami"),
            ("pepperoni", "pepperoni"),
            ("bologna", "bologna"),
            ("hot dogs", "hot dogs"),
            ("bacon", "bacon"),
            ("ham", "ham"),
            ("sausage", "sausage"),
            ("liver", "liver"),
            ("smoked fish", "smoked fish"),
            ("pickled herring", "pickled herring"),
            ("anchovies", "anchovies"),
            ("caviar", "caviar"),
            ("sauerkraut", "sauerkraut"),
            ("kimchi", "kimchi"),
            ("pickled vegetables", "pickled vegetables"),
            ("soy sauce", "soy sauce"),
            ("miso", "miso"),
            ("teriyaki", "teriyaki sauce"),
            ("fish sauce", "fish sauce"),
            ("worcestershire", "worcestershire sauce"),
            ("yeast extract", "yeast extract"),
            ("nutritional yeast", "nutritional yeast"),
            ("beer", "beer"),
            ("wine", "wine"),
            ("champagne", "champagne"),
            ("vermouth", "vermouth"),
            ("sherry", "sherry"),
            ("chianti", "chianti"),
            ("banana", "overripe bananas"),
            ("avocado", "overripe avocado"),
            ("figs", "figs"),
            ("raisins", "raisins"),
            ("chocolate", "chocolate"),
            ("vanilla", "vanilla extract")
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        let foundSources = tyramineItems.compactMap { keyword, displayName in
            allText.contains(keyword) ? displayName : nil
        }
        
        return foundSources.isEmpty ? nil : Array(Set(foundSources))
    }
    
    private func getSulfiteSources(name: String, ingredients: [String]) -> [String]? {
        let sulfiteItems = [
            ("wine", "wine"),
            ("beer", "beer"),
            ("dried fruit", "dried fruit"),
            ("raisins", "raisins"),
            ("apricots", "dried apricots"),
            ("dates", "dates"),
            ("figs", "dried figs"),
            ("coconut", "dried coconut"),
            ("potato products", "potato products"),
            ("french fries", "french fries"),
            ("hash browns", "hash browns"),
            ("dehydrated potatoes", "dehydrated potatoes"),
            ("lemon juice", "bottled lemon juice"),
            ("lime juice", "bottled lime juice"),
            ("grape juice", "grape juice"),
            ("wine vinegar", "wine vinegar"),
            ("balsamic vinegar", "balsamic vinegar"),
            ("pickled foods", "pickled foods"),
            ("olives", "olives"),
            ("pickles", "pickles"),
            ("sauerkraut", "sauerkraut"),
            ("maraschino cherries", "maraschino cherries"),
            ("molasses", "molasses"),
            ("corn syrup", "corn syrup"),
            ("maple syrup", "maple syrup"),
            ("jam", "jam"),
            ("jelly", "jelly"),
            ("preserves", "preserves"),
            ("fruit leather", "fruit leather"),
            ("trail mix", "trail mix"),
            ("granola", "granola"),
            ("muesli", "muesli"),
            ("soup mix", "soup mix"),
            ("salad dressing", "salad dressing"),
            ("condiments", "condiments"),
            ("horseradish", "horseradish"),
            ("relish", "relish"),
            ("guacamole", "guacamole"),
            ("avocado dip", "avocado dip"),
            ("shrimp", "shrimp"),
            ("lobster", "lobster"),
            ("crab", "crab"),
            ("scallops", "scallops"),
            ("clams", "clams"),
            ("mussels", "mussels")
        ]
        
        // Also check for sulfite preservatives in ingredients
        let sulfitePreservatives = [
            "sulfur dioxide", "sodium sulfite", "sodium bisulfite", "sodium metabisulfite",
            "potassium sulfite", "potassium bisulfite", "potassium metabisulfite",
            "calcium sulfite", "calcium bisulfite", "e220", "e221", "e222", "e223",
            "e224", "e225", "e226", "e227", "e228"
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        
        var foundSources = sulfiteItems.compactMap { keyword, displayName in
            allText.contains(keyword) ? displayName : nil
        }
        
        let foundPreservatives = sulfitePreservatives.compactMap { preservative in
            allText.contains(preservative) ? "sulfite preservatives" : nil
        }
        
        foundSources.append(contentsOf: foundPreservatives)
        
        return foundSources.isEmpty ? nil : Array(Set(foundSources))
    }
    
    private func getPurineSources(name: String, ingredients: [String]) -> [String]? {
        let purineItems = [
            ("organ meat", "organ meats"),
            ("liver", "liver"),
            ("kidney", "kidneys"),
            ("heart", "heart"),
            ("brain", "brain"),
            ("sweetbreads", "sweetbreads"),
            ("anchovies", "anchovies"),
            ("sardines", "sardines"),
            ("mackerel", "mackerel"),
            ("herring", "herring"),
            ("mussels", "mussels"),
            ("scallops", "scallops"),
            ("tuna", "tuna"),
            ("salmon", "salmon"),
            ("trout", "trout"),
            ("cod", "cod"),
            ("haddock", "haddock"),
            ("pike", "pike"),
            ("perch", "perch"),
            ("game meat", "game meats"),
            ("venison", "venison"),
            ("rabbit", "rabbit"),
            ("duck", "duck"),
            ("goose", "goose"),
            ("turkey", "turkey"),
            ("beef", "beef"),
            ("pork", "pork"),
            ("lamb", "lamb"),
            ("bacon", "bacon"),
            ("ham", "ham"),
            ("sausage", "sausage"),
            ("beer", "beer"),
            ("wine", "wine"),
            ("spirits", "alcoholic beverages"),
            ("yeast", "yeast"),
            ("nutritional yeast", "nutritional yeast"),
            ("baker's yeast", "baker's yeast"),
            ("brewer's yeast", "brewer's yeast"),
            ("spinach", "spinach"),
            ("asparagus", "asparagus"),
            ("cauliflower", "cauliflower"),
            ("mushrooms", "mushrooms"),
            ("peas", "peas"),
            ("lentils", "lentils"),
            ("beans", "beans"),
            ("oatmeal", "oatmeal"),
            ("wheat germ", "wheat germ"),
            ("bran", "bran")
        ]
        
        let allText = ([name] + ingredients).joined(separator: " ").lowercased()
        let foundSources = purineItems.compactMap { keyword, displayName in
            allText.contains(keyword) ? displayName : nil
        }
        
        return foundSources.isEmpty ? nil : Array(Set(foundSources))
    }
}

// MARK: - Supporting Views (reused from existing components)

struct DetailSectionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var iconColor: Color = ColorTheme.primary
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
    }
}

struct NutritionDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let foodItem: FoodItem
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Comprehensive nutrition display
                    foodItem.nutrition.summaryCard(style: .detailed)
                    
                    // Comprehensive nutrition grid (like barcode scanner)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Micronutrients & Additional Details")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            // Additional nutrition from nutritionDetails dictionary (micronutrients only)
                            if let saturatedFat = foodItem.nutritionDetails["saturated_fat"],
                               let saturatedFatValue = Double(saturatedFat), saturatedFatValue > 0 {
                                nutritionGridItem("Sat Fat", value: saturatedFatValue, unit: "g")
                            }
                            if let cholesterol = foodItem.nutritionDetails["cholesterol"],
                               let cholesterolValue = Double(cholesterol), cholesterolValue > 0 {
                                nutritionGridItem("Cholesterol", value: cholesterolValue, unit: "mg")
                            }
                            if let potassium = foodItem.nutritionDetails["potassium"],
                               let potassiumValue = Double(potassium), potassiumValue > 0 {
                                nutritionGridItem("Potassium", value: potassiumValue, unit: "mg")
                            }
                            if let calcium = foodItem.nutritionDetails["calcium"],
                               let calciumValue = Double(calcium), calciumValue > 0 {
                                nutritionGridItem("Calcium", value: calciumValue, unit: "mg")
                            }
                            if let iron = foodItem.nutritionDetails["iron"],
                               let ironValue = Double(iron), ironValue > 0 {
                                nutritionGridItem("Iron", value: ironValue, unit: "mg")
                            }
                            if let vitaminA = foodItem.nutritionDetails["vitamin_a"],
                               let vitaminAValue = Double(vitaminA), vitaminAValue > 0 {
                                nutritionGridItem("Vitamin A", value: vitaminAValue, unit: "mcg")
                            }
                            if let vitaminC = foodItem.nutritionDetails["vitamin_c"],
                               let vitaminCValue = Double(vitaminC), vitaminCValue > 0 {
                                nutritionGridItem("Vitamin C", value: vitaminCValue, unit: "mg")
                            }
                        }
                    }
                    .padding()
                    .background(ColorTheme.cardBackground)
                    .cornerRadius(12)
                    
                    // Additional nutrition details (remaining items)
                    if !remainingNutritionDetails.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Additional Nutrition Information")
                                .font(.headline)
                                .foregroundColor(ColorTheme.primaryText)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(remainingNutritionDetails, id: \.0) { key, value in
                                    NutritionDetailItem(label: key, value: value)
                                }
                            }
                        }
                        .padding()
                        .background(ColorTheme.cardBackground)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Nutrition Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var remainingNutritionDetails: [(String, String)] {
        // Keys that are already displayed in the main sections or are not nutrients
        let usedKeys = [
            "protein", "carbs", "fat", "calories", "brand", "source", "barcode",
            "saturated_fat", "cholesterol", "potassium", "calcium", "iron", "vitamin_a", "vitamin_c"
        ]
        
        // Keys that should be excluded (non-nutritional data)
        let excludedKeys = [
            "brand", "source", "barcode", "upc", "ndb_no", "item_id", "item_name",
            "food_group", "measure", "common_name", "scientific_name", "commercial_name",
            "alternate_names", "nutrients_per", "refuse_pct", "n_factor", "pro_factor",
            "fat_factor", "cho_factor"
        ]
        
        // Show most nutrition information, but avoid duplicates from main sections
        return foodItem.nutritionDetails
            .filter { key, value in
                let lowerKey = key.lowercased()
                
                // Exclude already used keys and non-nutritional metadata
                guard !usedKeys.contains(lowerKey) && !excludedKeys.contains(lowerKey) else { return false }
                
                // Exclude empty or zero values
                guard value != "N/A" && value != "0" && value != "0.0" && !value.isEmpty else { return false }
                
                // Exclude percentage daily values (we'll show raw values)
                guard !lowerKey.hasSuffix("_dv") && !lowerKey.hasSuffix("_pct") else { return false }
                
                return true
            }
            .sorted { first, second in
                let firstKey = first.0.lowercased()
                let secondKey = second.0.lowercased()
                
                // Define categories for better organization
                let firstIsVitamin = firstKey.contains("vitamin") || firstKey.contains("thiamin") || 
                                   firstKey.contains("riboflavin") || firstKey.contains("niacin") ||
                                   firstKey.contains("folate") || firstKey.contains("biotin") ||
                                   firstKey.contains("pantothenic")
                let secondIsVitamin = secondKey.contains("vitamin") || secondKey.contains("thiamin") || 
                                     secondKey.contains("riboflavin") || secondKey.contains("niacin") ||
                                     secondKey.contains("folate") || secondKey.contains("biotin") ||
                                     secondKey.contains("pantothenic")
                
                let firstIsMineral = ["calcium", "iron", "magnesium", "phosphorus", "potassium", "sodium", 
                                     "zinc", "copper", "manganese", "selenium"].contains { firstKey.contains($0) }
                let secondIsMineral = ["calcium", "iron", "magnesium", "phosphorus", "potassium", "sodium", 
                                      "zinc", "copper", "manganese", "selenium"].contains { secondKey.contains($0) }
                
                let firstIsAminoAcid = ["histidine", "isoleucine", "leucine", "lysine", "methionine", 
                                       "phenylalanine", "threonine", "tryptophan", "valine", "alanine",
                                       "arginine", "aspartic", "cysteine", "glutamic", "glycine", 
                                       "proline", "serine", "tyrosine"].contains { firstKey.contains($0) }
                let secondIsAminoAcid = ["histidine", "isoleucine", "leucine", "lysine", "methionine", 
                                        "phenylalanine", "threonine", "tryptophan", "valine", "alanine",
                                        "arginine", "aspartic", "cysteine", "glutamic", "glycine", 
                                        "proline", "serine", "tyrosine"].contains { secondKey.contains($0) }
                
                let firstIsFat = firstKey.contains("fat") || firstKey.contains("fatty")
                let secondIsFat = secondKey.contains("fat") || secondKey.contains("fatty")
                
                // Sort order: Vitamins -> Minerals -> Fats -> Amino Acids -> Others
                if firstIsVitamin && !secondIsVitamin {
                    return true
                } else if !firstIsVitamin && secondIsVitamin {
                    return false
                } else if firstIsMineral && !secondIsMineral && !secondIsVitamin {
                    return true
                } else if !firstIsMineral && secondIsMineral && !firstIsVitamin {
                    return false
                } else if firstIsFat && !secondIsFat && !secondIsVitamin && !secondIsMineral {
                    return true
                } else if !firstIsFat && secondIsFat && !firstIsVitamin && !firstIsMineral {
                    return false
                } else if firstIsAminoAcid && !secondIsAminoAcid && !secondIsVitamin && !secondIsMineral && !secondIsFat {
                    return true
                } else if !firstIsAminoAcid && secondIsAminoAcid && !firstIsVitamin && !firstIsMineral && !firstIsFat {
                    return false
                } else {
                    return first.0 < second.0
                }
            }
    }
    
    private func nutritionGridItem(_ label: String, value: Double, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            Text(String(format: "%.1f", value))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(ColorTheme.surface)
        .cornerRadius(8)
    }
}

struct NutritionDetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(formattedLabel)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            Text(formattedValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)
            
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(ColorTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(ColorTheme.surface)
        .cornerRadius(8)
    }
    
    private var formattedLabel: String {
        label.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    private var formattedValue: String {
        if let doubleValue = Double(value) {
            return String(format: "%.1f", doubleValue)
        }
        return value
    }
    
    private var unit: String {
        let lowerLabel = label.lowercased()
        
        // Vitamins (most in micrograms except C, niacin, etc.)
        if lowerLabel.contains("vitamin_a") || lowerLabel.contains("folate") || lowerLabel.contains("folic") ||
           lowerLabel.contains("b12") || lowerLabel.contains("biotin") || lowerLabel.contains("cobalamin") ||
           lowerLabel.contains("vitamin_k") || lowerLabel.contains("selenium") || lowerLabel.contains("iodine") ||
           lowerLabel.contains("chromium") || lowerLabel.contains("molybdenum") {
            return "mcg"
        } else if lowerLabel.contains("vitamin_c") || lowerLabel.contains("ascorbic") ||
                  lowerLabel.contains("niacin") || lowerLabel.contains("vitamin_b6") || 
                  lowerLabel.contains("thiamin") || lowerLabel.contains("riboflavin") || 
                  lowerLabel.contains("pantothenic") || lowerLabel.contains("vitamin_e") ||
                  lowerLabel.contains("tocopherol") {
            return "mg"
        } else if lowerLabel.contains("vitamin_d") {
            return "IU"
        }
        
        // Minerals (most in milligrams)
        else if lowerLabel.contains("calcium") || lowerLabel.contains("iron") || 
                lowerLabel.contains("magnesium") || lowerLabel.contains("phosphorus") ||
                lowerLabel.contains("potassium") || lowerLabel.contains("sodium") ||
                lowerLabel.contains("zinc") || lowerLabel.contains("copper") ||
                lowerLabel.contains("manganese") {
            return "mg"
        }
        
        // Dietary components
        else if lowerLabel.contains("cholesterol") || lowerLabel.contains("caffeine") ||
                lowerLabel.contains("theobromine") {
            return "mg"
        }
        
        // Amino acids (all in grams or milligrams depending on amount)
        else if lowerLabel.contains("histidine") || lowerLabel.contains("isoleucine") ||
                lowerLabel.contains("leucine") || lowerLabel.contains("lysine") ||
                lowerLabel.contains("methionine") || lowerLabel.contains("phenylalanine") ||
                lowerLabel.contains("threonine") || lowerLabel.contains("tryptophan") ||
                lowerLabel.contains("valine") || lowerLabel.contains("alanine") ||
                lowerLabel.contains("arginine") || lowerLabel.contains("aspartic") ||
                lowerLabel.contains("cysteine") || lowerLabel.contains("glutamic") ||
                lowerLabel.contains("glycine") || lowerLabel.contains("proline") ||
                lowerLabel.contains("serine") || lowerLabel.contains("tyrosine") {
            // Check value to determine appropriate unit
            if let doubleValue = Double(value), doubleValue < 1.0 {
                return "mg"
            } else {
                return "g"
            }
        }
        
        // Fats (grams)
        else if lowerLabel.contains("fat") || lowerLabel.contains("fatty") ||
                lowerLabel.contains("saturated") || lowerLabel.contains("trans") ||
                lowerLabel.contains("polyunsaturated") || lowerLabel.contains("monounsaturated") {
            return "g"
        }
        
        // Carbohydrates and related (grams)
        else if lowerLabel.contains("fiber") || lowerLabel.contains("sugar") || 
                lowerLabel.contains("carb") || lowerLabel.contains("starch") ||
                lowerLabel.contains("protein") {
            return "g"
        }
        
        // Energy
        else if lowerLabel.contains("energy") || lowerLabel.contains("calorie") {
            return "kcal"
        }
        
        // Water and ash
        else if lowerLabel.contains("water") || lowerLabel.contains("moisture") ||
                lowerLabel.contains("ash") {
            return "g"
        }
        
        return "" // No unit for percentages, ratios, or unknown items
    }
}

struct IngredientsView: View {
    @Environment(\.dismiss) private var dismiss
    let ingredients: [String]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if ingredients.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 48))
                                .foregroundColor(ColorTheme.secondaryText.opacity(0.5))
                            
                            Text("No Ingredients Listed")
                                .font(.headline)
                                .foregroundColor(ColorTheme.primaryText)
                            
                            Text("Ingredient information is not available for this food item.")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding()
                    } else {
                        Text("Ingredients are listed in order of predominance by weight.")
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                            .padding(.horizontal)
                        
                        ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                            HStack {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.secondaryText)
                                    .frame(width: 24, alignment: .leading)
                                
                                Text(ingredient.capitalized)
                                    .font(.body)
                                    .foregroundColor(ColorTheme.primaryText)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AllergensView: View {
    @Environment(\.dismiss) private var dismiss
    let allergens: [String]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if allergens.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 48))
                                .foregroundColor(ColorTheme.success)
                            
                            Text("No Known Allergens")
                                .font(.headline)
                                .foregroundColor(ColorTheme.primaryText)
                            
                            Text("No common allergens were detected in this food item. However, always check the original packaging for complete allergen information.")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding()
                    } else {
                        Text("This food contains or may contain the following allergens:")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)
                            .padding(.horizontal)
                        
                        ForEach(allergens, id: \.self) { allergen in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(ColorTheme.error)
                                
                                Text(allergen)
                                    .font(.body)
                                    .foregroundColor(ColorTheme.primaryText)
                                
                                Spacer()
                            }
                            .padding()
                            .background(ColorTheme.error.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Allergens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Health Indicator Models

struct HealthIndicator {
    let text: String
    let icon: String
    let color: Color
    let severity: HealthSeverity
    let description: String
}

enum HealthSeverity {
    case low, medium, high
    
    var borderColor: Color {
        switch self {
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct HealthIndicatorBadge: View {
    let indicator: HealthIndicator
    @State private var showingDetail = false
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(indicator.icon)
                    .font(.caption)
                Text(indicator.text)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(indicator.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(indicator.color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(indicator.severity.borderColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
        .onTapGesture {
            showingDetail = true
        }
        .alert(indicator.text, isPresented: $showingDetail) {
            Button("Got it") { }
        } message: {
            Text(indicator.description)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UnifiedFoodDetailView(
            foodItem: FoodItem(
                name: "Tomato Basil Pasta with Parmesan",
                quantity: "1 cup",
                estimatedWeightInGrams: 245,
                ingredients: [
                    "pasta", "tomatoes", "basil", "parmesan cheese", "olive oil", 
                    "garlic", "spinach", "vegetable oil", "soybean oil", "wine"
                ],
                allergens: ["Dairy", "Gluten"],
                nutrition: NutritionInfo(
                    calories: 350,
                    protein: 12.0,
                    carbs: 45.0,
                    fat: 14.0,
                    fiber: 3.0,
                    sugar: 8.0,
                    sodium: 580.0
                ),
                source: .barcode,
                nutritionDetails: [
                    "brand": "Organic Valley",
                    "calcium_dv": "25",
                    "vitamin_b12_mcg": "1.4",
                    "saturated_fat": "6.5"
                ]
            ),
            style: .full
        )
    }
}
