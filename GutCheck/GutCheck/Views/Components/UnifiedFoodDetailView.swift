//
//  UnifiedFoodDetailView.swift
//  GutCheck
//
//  Unified food detail view supporting all presentation modes

import SwiftUI
import Foundation

enum ServingUnit: String, CaseIterable, Identifiable {
    case serving = "serving"
    case grams = "g"
    case ounces = "oz"
    case cups = "cup"
    case tablespoons = "tbsp"
    case teaspoons = "tsp"
    case pounds = "lb"
    case milliliters = "ml"
    case liters = "L"
    case pieces = "piece"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .serving: return "Serving"
        case .grams: return "Grams"
        case .ounces: return "Ounces"
        case .cups: return "Cups"
        case .tablespoons: return "Tablespoons"
        case .teaspoons: return "Teaspoons"
        case .pounds: return "Pounds"
        case .milliliters: return "Milliliters"
        case .liters: return "Liters"
        case .pieces: return "Pieces"
        }
    }
}

struct UnifiedFoodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var foodItem: FoodItem
    @State private var servingMultiplier: Double = 1.0
    @State private var customQuantity: String = ""
    @State private var quantityText: String = "1.0"
    @State private var selectedUnit: ServingUnit = .serving
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
        
        // Parse initial quantity and unit from foodItem.quantity
        var initialQuantity = "1.0"
        var initialUnit = ServingUnit.serving
        
        // Try to detect if this is already an adjusted serving size
        // Look for the "× " pattern in the quantity string
        if foodItem.quantity.contains("×") {
            let components = foodItem.quantity.components(separatedBy: "×")
            if let multiplierString = components.first?.trimmingCharacters(in: CharacterSet.whitespaces),
               let detectedMultiplier = Double(multiplierString) {
                self._servingMultiplier = State(initialValue: detectedMultiplier)
                initialQuantity = String(format: "%.1f", detectedMultiplier)
            }
        } else {
            // Parse quantity like "1 cup", "2.5 servings", etc.
            let parts = foodItem.quantity.components(separatedBy: " ")
            if let firstPart = parts.first, let quantity = Double(firstPart) {
                initialQuantity = String(format: "%.1f", quantity)
                if parts.count > 1 {
                    let unitString = parts.dropFirst().joined(separator: " ").lowercased()
                    // Try to match with our enum cases
                    if let matchedUnit = ServingUnit.allCases.first(where: { unit in
                        unitString.contains(unit.rawValue) || unitString.contains(unit.displayName.lowercased())
                    }) {
                        initialUnit = matchedUnit
                    }
                }
            }
        }
        
        self._quantityText = State(initialValue: initialQuantity)
        self._selectedUnit = State(initialValue: initialUnit)
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
                if config.showCancelButton {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $detailService.showingNutritionDetails) {
                NutritionDetailsView(foodItem: foodItem)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $detailService.showingAllergens) {
                CombinedAllergensHealthView(foodItem: foodItem)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $detailService.showingIngredients) {
                IngredientsView(ingredients: foodItem.ingredients)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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
            
            VStack(spacing: 16) {
                // Quantity input row
                HStack {
                    Text("Amount:")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Spacer()
                    
                    TextField("1.0", text: $quantityText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .onChange(of: quantityText) { _, newValue in
                            updateServingFromInput()
                        }
                }
                
                // Unit selection row
                HStack {
                    Text("Unit:")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Spacer()
                    
                    Picker("Unit", selection: $selectedUnit) {
                        ForEach(ServingUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedUnit) { _, _ in
                        updateServingFromInput()
                    }
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
            
            // Basic nutrition facts - only show kcal, Protein, Carbs, Fat
            VStack(spacing: 16) {
                // Calories prominent display
                if let calories = foodItem.nutrition.calories {
                    HStack {
                        Text("Calories")
                            .font(.title3)
                            .foregroundColor(ColorTheme.primaryText)
                        Spacer()
                        Text("\(calories)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("kcal")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(12)
                }
                
                // Basic macros in a row
                HStack(spacing: 16) {
                    if let protein = foodItem.nutrition.protein {
                        BasicNutrientColumn(name: "Protein", value: protein, unit: "g", color: .blue)
                    }
                    
                    if let carbs = foodItem.nutrition.carbs {
                        BasicNutrientColumn(name: "Carbs", value: carbs, unit: "g", color: .green)
                    }
                    
                    if let fat = foodItem.nutrition.fat {
                        BasicNutrientColumn(name: "Fat", value: fat, unit: "g", color: .red)
                    }
                }
                .padding()
                .background(ColorTheme.surface)
                .cornerRadius(12)
            }
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
    
    // MARK: - Helper Functions
    
    private func getAllergensAndIndicatorsSubtitle() -> String {
        let allergenCount = foodItem.allergens.count
        let healthIndicators = getHealthIndicators()
        let indicatorCount = healthIndicators.count
        
        var parts: [String] = []
        
        if allergenCount > 0 {
            parts.append("\(allergenCount) allergen\(allergenCount == 1 ? "" : "s")")
        }
        
        if indicatorCount > 0 {
            parts.append("\(indicatorCount) health indicator\(indicatorCount == 1 ? "" : "s")")
        }
        
        if parts.isEmpty {
            return "No concerns detected"
        }
        
        return parts.joined(separator: ", ")
    }
    
    private func getIngredientsSubtitle() -> String {
        let ingredientCount = foodItem.ingredients.count
        
        if ingredientCount == 0 {
            return "No ingredients listed"
        } else if ingredientCount == 1 {
            return "1 ingredient"
        } else {
            return "\(ingredientCount) ingredients"
        }
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
            
            // Combined Allergens & Health Indicators
            Button(action: {
                detailService.showingAllergens = true
            }) {
                DetailSectionRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Allergens & Health Indicators",
                    subtitle: getAllergensAndIndicatorsSubtitle(),
                    iconColor: ColorTheme.error
                )
            }
            
            // Ingredients
            Button(action: {
                detailService.showingIngredients = true
            }) {
                DetailSectionRow(
                    icon: "list.bullet",
                    title: "Ingredients",
                    subtitle: getIngredientsSubtitle()
                )
            }
        }
    }
    
    private var addToMealButton: some View {
        Button(action: {
            if let onUpdate = onUpdate {
                // Editing mode: update existing item
                onUpdate(foodItem)
                if config.showCancelButton {
                    dismiss()  // Only dismiss if we're in a modal context
                }
            } else {
                // Adding mode: add new item to meal
                MealBuilderService.shared.addFoodItem(foodItem)
                if config.showCancelButton {
                    dismiss()  // Only dismiss if we're in a modal context
                }
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
    
    private func updateServingFromInput() {
        guard let quantity = Double(quantityText), quantity > 0 else {
            return
        }
        
        // Update serving multiplier based on text input
        servingMultiplier = quantity
        updateNutritionForServing(multiplier: quantity)
        
        // Update the custom quantity string with unit
        if quantity == 1.0 {
            customQuantity = "1 \(selectedUnit.rawValue)"
        } else {
            customQuantity = "\(String(format: "%.1f", quantity)) \(selectedUnit.rawValue)"
        }
        foodItem.quantity = customQuantity
    }
    
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
        
        // Use comprehensive compound database
        let detectedCompounds = FoodCompoundDatabase.shared.getCompoundsForFood(name: name, ingredients: ingredients)
        
        // Group compounds by category for better organization
        let groupedCompounds = Dictionary(grouping: detectedCompounds) { $0.category }
        
        for (category, compounds) in groupedCompounds {
            let compoundNames = compounds.map { $0.name }
            let highestSeverity = compounds.max(by: { $0.severity.rawValue < $1.severity.rawValue })?.severity ?? .low
            let categoryColor: Color = {
                switch highestSeverity {
                case .high: return .red
                case .medium: return .orange
                case .low: return .yellow
                }
            }()
            
            indicators.append(HealthIndicator(
                text: category.rawValue,
                icon: getIconForCategory(category),
                color: categoryColor,
                severity: highestSeverity,
                description: "\(category.rawValue): \(compoundNames.joined(separator: ", "))"
            ))
        }
        
        // Legacy nutritional indicators (keep these for now)
        
        // High sodium
        if let sodium = foodItem.nutrition.sodium, sodium > 600 {
            indicators.append(HealthIndicator(
                text: "High Sodium",
                icon: "🧂",
                color: .red,
                severity: .high,
                description: "High in sodium (\(sodium)mg)"
            ))
        }
        
        // High sugar
        if let sugar = foodItem.nutrition.sugar, sugar > 15 {
            indicators.append(HealthIndicator(
                text: "High Sugar",
                icon: "🍯",
                color: .orange,
                severity: .medium,
                description: "High in sugar (\(sugar)g)"
            ))
        }
        
        // High fiber (positive indicator)
        if let fiber = foodItem.nutrition.fiber, fiber >= 5 {
            indicators.append(HealthIndicator(
                text: "High Fiber",
                icon: "🥬",
                color: .green,
                severity: .low,
                description: "Good source of fiber (\(fiber)g)"
            ))
        }
        
        return indicators
    }
    
    private func getIconForCategory(_ category: CompoundCategory) -> String {
        switch category {
        case .majorAllergen:
            return "exclamationmark.shield.fill"
        case .foodIntolerance:
            return "person.crop.circle.badge.exclamationmark"
        case .toxicCompound:
            return "exclamationmark.triangle.fill"
        case .inflammatoryCompound:
            return "flame.fill"
        case .metabolicDisruptor:
            return "minus.circle.fill"
        case .neurologicalTrigger:
            return "brain.head.profile"
        case .alkaloid:
            return "pills.fill"
        case .biogenicAmine:
            return "atom"
        case .phenolic:
            return "leaf.fill"
        case .heavyMetal:
            return "testtube.2"
        case .preservative:
            return "timer"
        case .naturalToxin:
            return "exclamationmark.triangle.fill"
        }
    }
    
    // MARK: - Legacy Helper Functions (kept for specific processing needs)
    
    private func isProcessedFood(name: String, ingredients: [String]) -> Bool {
        let processedTerms = ["frozen", "canned", "instant", "powder", "mix", "artificial", "preservative", "packaged"]
        return processedTerms.contains { name.contains($0) } || 
               ingredients.count > 10 ||
               ingredients.contains { ingredient in
                   processedTerms.contains { ingredient.contains($0) }
               }
    }
    
    private func isFriedFood(name: String, ingredients: [String]) -> Bool {
        let friedTerms = ["fried", "deep-fried", "battered", "breaded", "crispy", "chips", "fries"]
        return friedTerms.contains { name.contains($0) } ||
               ingredients.contains { ingredient in
                   friedTerms.contains { ingredient.contains($0) }
               }
    }
    
    private func containsHFCS(ingredients: [String]) -> Bool {
        return ingredients.contains { ingredient in
            ingredient.contains("high fructose corn syrup") || 
            ingredient.contains("corn syrup") ||
            ingredient.contains("hfcs")
        }
    }
    
    private func isFODMAP(name: String, ingredients: [String]) -> Bool {
        let fodmapFoods = ["apple", "pear", "watermelon", "mango", "onion", "garlic", "wheat", "rye", "barley", 
                          "milk", "yogurt", "ice cream", "beans", "lentils", "chickpeas", "cashews", "pistachios"]
        return fodmapFoods.contains { name.contains($0) } ||
               ingredients.contains { ingredient in
                   fodmapFoods.contains { ingredient.contains($0) }
               }
    }
    
    private func containsArtificialAdditives(ingredients: [String]) -> Bool {
        let additives = ["artificial", "preservative", "color", "flavor", "msg", "aspartame", "sucralose"]
        return ingredients.contains { ingredient in
            additives.contains { ingredient.contains($0) }
        }
    }
    
    private func isSpicyFood(name: String, ingredients: [String]) -> Bool {
        let spicyTerms = ["spicy", "hot", "pepper", "chili", "jalapeño", "habanero", "cayenne", "sriracha", "tabasco"]
        return spicyTerms.contains { name.contains($0) } ||
               ingredients.contains { ingredient in
                   spicyTerms.contains { ingredient.contains($0) }
               }
    }
    
    private func containsCaffeine(name: String, ingredients: [String]) -> Bool {
        let caffeineTerms = ["coffee", "tea", "chocolate", "cola", "caffeine", "guarana", "yerba mate"]
        return caffeineTerms.contains { name.contains($0) } ||
               ingredients.contains { ingredient in
                   caffeineTerms.contains { ingredient.contains($0) }
               }
    }
}

// MARK: - Supporting Views

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

// MARK: - Health Indicator Models

struct HealthIndicator {
    let text: String
    let icon: String
    let color: Color
    let severity: HealthSeverity
    let description: String
}

struct DetailedHealthIndicator {
    let id: String
    let foodItem: String      // e.g., "Tomato"
    let category: String      // e.g., "Inflammatory Compounds"
    let compound: String      // e.g., "Salicylates"
    let severity: HealthSeverity
    let color: Color
    let icon: String
}

struct HealthIndicatorRow: View {
    let indicator: DetailedHealthIndicator
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Severity indicator
            Circle()
                .fill(indicator.color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                // Food item name (bold)
                Text(indicator.foodItem)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                // Category and compound
                HStack {
                    Text(indicator.category)
                        .font(.subheadline)
                        .foregroundColor(indicator.color)
                    
                    Text("-")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Text(indicator.compound)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                }
            }
            
            Spacer()
            
            // Icon
            Image(systemName: indicator.icon)
                .font(.title3)
                .foregroundColor(indicator.color)
        }
        .padding()
        .background(indicator.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(indicator.color.opacity(0.3), lineWidth: 1)
        )
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

struct CombinedAllergensHealthView: View {
    @Environment(\.dismiss) private var dismiss
    let foodItem: FoodItem
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Allergens Section
                    allergensSection
                    
                    // Health Indicators Section
                    healthIndicatorsSection
                }
                .padding()
            }
            .navigationTitle("Allergens & Health")
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
    
    private var allergensSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Allergens")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.primaryText)
            
            if foodItem.allergens.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    
                    Text("No Known Allergens")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("No common allergens detected in this food item.")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(foodItem.allergens, id: \.self) { allergen in
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
                    }
                }
            }
        }
    }
    
    private var healthIndicatorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Indicators")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.primaryText)
            
            let detailedIndicators = getDetailedHealthIndicators()
            
            if detailedIndicators.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    
                    Text("No Health Concerns")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("No health concerns detected for this food item.")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    // Group indicators by category
                    let groupedByCategory = Dictionary(grouping: detailedIndicators) { $0.category }
                    let sortedCategories = groupedByCategory.keys.sorted { categoryA, categoryB in
                        let maxSeverityA = groupedByCategory[categoryA]?.map(\.severity.rawValue).max() ?? 0
                        let maxSeverityB = groupedByCategory[categoryB]?.map(\.severity.rawValue).max() ?? 0
                        return maxSeverityA > maxSeverityB
                    }
                    
                    ForEach(sortedCategories, id: \.self) { category in
                        let categoryIndicators = groupedByCategory[category] ?? []
                        let maxSeverity = categoryIndicators.map(\.severity.rawValue).max() ?? 0
                        let categoryColor: Color = {
                            switch maxSeverity {
                            case 3: return .red
                            case 2: return .orange
                            case 1: return .yellow
                            default: return .gray
                            }
                        }()
                        
                        GroupedCategoryView(
                            category: category,
                            indicators: categoryIndicators,
                            categoryColor: categoryColor
                        )
                    }
                }
            }
        }
    }
    
    private func getDetailedHealthIndicators() -> [DetailedHealthIndicator] {
        var detailedIndicators: [DetailedHealthIndicator] = []
        
        let name = foodItem.name.lowercased()
        let providedIngredients = foodItem.ingredients.map { $0.lowercased() }
        
        // Get all possible ingredients (including inferred ones from composite foods)
        let database = FoodCompoundDatabase.shared
        let allIngredients = database.getIngredientsForFood(name: name, providedIngredients: providedIngredients)
        
        // Analyze each ingredient individually to properly attribute compounds
        for ingredient in allIngredients {
            let ingredientCompounds = database.analyzeIngredients([ingredient])
            
            for compound in ingredientCompounds {
                let severity = compound.severity
                let severityColor: Color = {
                    switch severity {
                    case .high: return .red
                    case .medium: return .orange
                    case .low: return .yellow
                    }
                }()
                
                detailedIndicators.append(DetailedHealthIndicator(
                    id: UUID().uuidString,
                    foodItem: ingredient.capitalized,
                    category: compound.category.rawValue,
                    compound: compound.name,
                    severity: severity,
                    color: severityColor,
                    icon: getIconForCategory(compound.category)
                ))
            }
        }
        
        // Check for additives from barcode scanning
        if let additives = foodItem.nutritionDetails["additives"] {
            let additivesList = additives.components(separatedBy: ", ")
            for additive in additivesList {
                let trimmedAdditive = additive.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if !trimmedAdditive.isEmpty {
                    detailedIndicators.append(DetailedHealthIndicator(
                        id: UUID().uuidString,
                        foodItem: foodItem.name,
                        category: "Preservatives & Additives",
                        compound: trimmedAdditive,
                        severity: .medium,
                        color: .orange,
                        icon: "timer"
                    ))
                }
            }
        }
        
        // Legacy nutritional indicators
        if let sodium = foodItem.nutrition.sodium, sodium > 600 {
            detailedIndicators.append(DetailedHealthIndicator(
                id: UUID().uuidString,
                foodItem: foodItem.name,
                category: "High Sodium",
                compound: "\(sodium)mg sodium",
                severity: .high,
                color: .red,
                icon: "drop.fill"
            ))
        }
        
        if let sugar = foodItem.nutrition.sugar, sugar > 15 {
            detailedIndicators.append(DetailedHealthIndicator(
                id: UUID().uuidString,
                foodItem: foodItem.name,
                category: "High Sugar",
                compound: "\(sugar)g sugar",
                severity: .medium,
                color: .orange,
                icon: "cube.fill"
            ))
        }
        
        if let fiber = foodItem.nutrition.fiber, fiber >= 5 {
            detailedIndicators.append(DetailedHealthIndicator(
                id: UUID().uuidString,
                foodItem: foodItem.name,
                category: "High Fiber",
                compound: "\(fiber)g fiber (beneficial)",
                severity: .low,
                color: .green,
                icon: "leaf.fill"
            ))
        }
        
        return detailedIndicators
    }
    
    
    private func getHealthIndicators() -> [HealthIndicator] {
        // Keep this for backward compatibility with the subtitle function
        let detailedIndicators = getDetailedHealthIndicators()
        return detailedIndicators.map { detailed in
            HealthIndicator(
                text: detailed.category,
                icon: detailed.icon,
                color: detailed.color,
                severity: detailed.severity,
                description: "\(detailed.foodItem): \(detailed.category) - \(detailed.compound)"
            )
        }
    }
    
    private func getIconForCategory(_ category: CompoundCategory) -> String {
        switch category {
        case .majorAllergen:
            return "exclamationmark.shield.fill"
        case .foodIntolerance:
            return "person.crop.circle.badge.exclamationmark"
        case .toxicCompound:
            return "exclamationmark.triangle.fill"
        case .inflammatoryCompound:
            return "flame.fill"
        case .metabolicDisruptor:
            return "minus.circle.fill"
        case .neurologicalTrigger:
            return "brain.head.profile"
        case .alkaloid:
            return "pills.fill"
        case .biogenicAmine:
            return "atom"
        case .phenolic:
            return "leaf.fill"
        case .heavyMetal:
            return "testtube.2"
        case .preservative:
            return "timer"
        case .naturalToxin:
            return "exclamationmark.triangle.fill"
        }
    }
}

struct BasicNutrientColumn: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
            
            Text(String(format: "%.1f", value))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Grouped Category View

struct GroupedCategoryView: View {
    let category: String
    let indicators: [DetailedHealthIndicator]
    let categoryColor: Color
    @State private var isExpanded = true
    
    private var categoryIcon: String {
        switch category {
        case "Major Allergens": return "allergens"
        case "Food Intolerances": return "exclamationmark.triangle"
        case "Toxic Compounds": return "exclamationmark.triangle.fill"
        case "Inflammatory Compounds": return "flame.fill"
        case "Metabolic Disruptors": return "drop.fill"
        case "Neurological Triggers": return "brain.head.profile"
        case "Preservatives & Additives": return "timer"
        case "High Sodium": return "drop.fill"
        case "High Sugar": return "cube.fill"
        case "High Fiber": return "leaf.fill"
        default: return "questionmark.circle"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: categoryIcon)
                        .foregroundColor(categoryColor)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(indicators.count) compound\(indicators.count == 1 ? "" : "s") detected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(categoryColor.opacity(0.1))
            .cornerRadius(8)
            
            // Compounds List
            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(indicators.sorted { $0.severity.rawValue > $1.severity.rawValue }, id: \.id) { indicator in
                        SimplifiedHealthIndicatorRow(indicator: indicator)
                    }
                }
                .padding(.leading, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(categoryColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 4)
    }
}

struct SimplifiedHealthIndicatorRow: View {
    let indicator: DetailedHealthIndicator
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail.toggle()
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Severity indicator
                Circle()
                    .fill(indicator.color)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(indicator.compound)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if indicator.foodItem != indicator.compound {
                            Text("from \(indicator.foodItem)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    if showingDetail {
                        Text(getSimplifiedDescription(indicator.compound))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                Image(systemName: showingDetail ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(indicator.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func getSimplifiedDescription(_ compoundName: String) -> String {
        // Simplified descriptions for common compounds
        switch compoundName.lowercased() {
        case let name where name.contains("sodium"):
            return "High sodium intake can contribute to hypertension and cardiovascular issues."
        case let name where name.contains("sugar"):
            return "High sugar content can lead to blood sugar spikes and energy crashes."
        case let name where name.contains("fiber"):
            return "High fiber content is beneficial for digestive health and blood sugar regulation."
        case let name where name.contains("tartrazine"):
            return "Yellow food dye that may cause hyperactivity and allergic reactions in sensitive individuals."
        case let name where name.contains("sodium benzoate"):
            return "Preservative that may form benzene when combined with vitamin C."
        case let name where name.contains("citric acid"):
            return "Generally safe preservative that can enhance absorption of minerals."
        case let name where name.contains("ascorbic acid"):
            return "Vitamin C used as preservative and antioxidant, generally beneficial."
        case let name where name.contains("gluten"):
            return "Protein complex that can trigger celiac disease and gluten sensitivity."
        case let name where name.contains("lactose"):
            return "Milk sugar that can cause digestive issues in lactose-intolerant individuals."
        case let name where name.contains("histamine"):
            return "Compound that can trigger allergic-like reactions and headaches."
        case let name where name.contains("msg"):
            return "Flavor enhancer that can cause headaches and flushing in sensitive individuals."
        default:
            return "This compound may affect health in sensitive individuals. Consult healthcare provider if concerns."
        }
    }
}
