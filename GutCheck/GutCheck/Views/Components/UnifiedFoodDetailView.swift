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
    @State private var detailService = FoodDetailService.shared
    
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
                    .typography(Typography.headline)
                    .foregroundStyle(ColorTheme.primaryText)
                
                Spacer()
                
                if config.allowEditing {
                    // Edit/Delete buttons would go here
                }
            }
            
            Text(foodItem.quantity)
                .typography(Typography.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
            
            // Unified nutrition display
            unifiedNutritionCompact
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Full Detail View
    
    private var fullDetailView: some View {
        ScrollView {
            VStack(spacing: 24) {
                foodHeaderSection
                
                if config.showServingControls {
                    servingSizeSection
                }
                
                nutritionSection
                
                // Health indicators are now integrated into Allergens & Warnings
                
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
            ToolbarItem(placement: .topBarLeading) {
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
            AllergensView(allergens: foodItem.allergens, healthIndicators: healthIndicators)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: servingMultiplier) { _, newValue in
            updateNutritionForServing(multiplier: newValue)
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
                            .foregroundStyle(ColorTheme.accent)
                        Text("Food Image")
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                )
            
            VStack(spacing: 8) {
                Text(foodItem.name)
                    .typography(Typography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(ColorTheme.primaryText)
                    .multilineTextAlignment(.center)
                
                if let brand = foodItem.nutritionDetails["brand"] {
                    Text(brand)
                        .typography(Typography.subheadline)
                        .foregroundStyle(ColorTheme.accent)
                }
                
                sourceIndicator
            }
        }
    }
    
    private var sourceIndicator: some View {
        HStack {
            Text("Source:")
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
            
            Text(sourceDescription)
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.primary)
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
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)
            
            HStack {
                Text("Amount:")
                    .typography(Typography.subheadline)
                
                Stepper(value: $servingMultiplier, in: 0.1...10.0, step: 0.1) {
                    Text(servingMultiplier.formatted(.number.precision(.fractionLength(1))))
                        .typography(Typography.headline)
                        .foregroundStyle(ColorTheme.primary)
                }
            }
            .padding()
            .background(ColorTheme.surface)
            .clipShape(.rect(cornerRadius: 12))
            
            Text("Per \(customQuantity)")
                .typography(Typography.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
        }
    }
    
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Facts")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            VStack(spacing: 0) {
                // Macronutrients
                nutritionGroupLabel("Macronutrients")
                NutritionDetailRow(label: "Calories",      value: foodItem.nutrition.calories.map { Double($0) }, unit: "kcal", color: .orange)
                NutritionDetailRow(label: "Protein",       value: foodItem.nutrition.protein,   unit: "g",    color: .blue)
                NutritionDetailRow(label: "Carbohydrates", value: foodItem.nutrition.carbs,     unit: "g",    color: .green)
                NutritionDetailRow(label: "Total Fat",     value: foodItem.nutrition.fat,       unit: "g",    color: .red)
                NutritionDetailRow(label: "Fiber",         value: foodItem.nutrition.fiber,     unit: "g",    color: .orange)
                NutritionDetailRow(label: "Sugar",         value: foodItem.nutrition.sugar,     unit: "g",    color: .pink)
                NutritionDetailRow(label: "Sodium",        value: foodItem.nutrition.sodium,    unit: "mg",   color: .yellow)

                if !parsedFats.isEmpty {
                    Divider().padding(.vertical, 8)
                    nutritionGroupLabel("Fats")
                    ForEach(parsedFats, id: \.0) { key, value in
                        NutritionDetailRow(label: key, value: value,
                                           unit: key == "Cholesterol" ? "mg" : "g", color: .red)
                    }
                }

                if !parsedMinerals.isEmpty {
                    Divider().padding(.vertical, 8)
                    nutritionGroupLabel("Minerals")
                    ForEach(parsedMinerals, id: \.0) { key, value in
                        NutritionDetailRow(label: key, value: value,
                                           unit: unitForMicronutrient(key), color: .teal)
                    }
                }

                if !parsedVitamins.isEmpty {
                    Divider().padding(.vertical, 8)
                    nutritionGroupLabel("Vitamins")
                    ForEach(parsedVitamins, id: \.0) { key, value in
                        NutritionDetailRow(label: key, value: value,
                                           unit: unitForMicronutrient(key), color: .purple)
                    }
                }
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
        }
    }

    @ViewBuilder
    private func nutritionGroupLabel(_ title: String) -> some View {
        Text(title)
            .typography(Typography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
    }

    /// Parses a `nutritionDetails` string value (e.g. "15.0g", "100mg") into a Double.
    /// See `NutrientValueParser` for how the comma conventions are handled.
    private func parsedDetails(keys: [String]) -> [(String, Double)] {
        keys.compactMap { key in
            guard let str = foodItem.nutritionDetails[key],
                  let val = NutrientValueParser.number(from: str),
                  val >= 0
            else { return nil }
            return (key, val)
        }
    }

    /// Display unit for a parsed micronutrient. Vitamins A, D and K are stored
    /// in micrograms; the rest of what reaches these sections is milligrams.
    private func unitForMicronutrient(_ key: String) -> String {
        switch key {
        case "Vitamin A", "Vitamin D", "Vitamin K", "Folate", "Vitamin B12", "Biotin", "Selenium":
            return "mcg"
        case "Vitamin E", "Thiamin", "Riboflavin", "Niacin", "Vitamin B6", "Pantothenic Acid",
             "Calcium", "Iron", "Magnesium", "Phosphorus", "Potassium", "Sodium", "Zinc",
             "Copper", "Manganese":
            return "mg"
        default:
            return "mg"
        }
    }

    private var parsedFats: [(String, Double)] {
        parsedDetails(keys: ["Saturated Fat", "Trans Fat", "Polyunsaturated Fat",
                              "Monounsaturated Fat", "Cholesterol"])
    }

    private var parsedMinerals: [(String, Double)] {
        parsedDetails(keys: ["Potassium", "Calcium", "Iron", "Magnesium", "Phosphorus",
                              "Zinc", "Copper", "Manganese", "Selenium"])
    }

    private var parsedVitamins: [(String, Double)] {
        parsedDetails(keys: ["Vitamin A", "Vitamin C", "Vitamin D", "Vitamin E", "Vitamin K",
                              "Thiamin", "Riboflavin", "Niacin", "Vitamin B6", "Folate",
                              "Vitamin B12", "Biotin", "Pantothenic Acid"])
    }
    
    private var unifiedNutritionCompact: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Calories
            if let calories = foodItem.nutrition.calories {
                Text("\(calories) calories")
                    .typography(Typography.subheadline)
                    .foregroundStyle(ColorTheme.primaryText)
            }
            
            // Macros in a compact row
            HStack(spacing: 12) {
                if let protein = foodItem.nutrition.protein {
                    Text("P: \(protein.formatted(.number.precision(.fractionLength(1))))g")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }
                if let carbs = foodItem.nutrition.carbs {
                    Text("C: \(carbs.formatted(.number.precision(.fractionLength(1))))g")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }
                if let fat = foodItem.nutrition.fat {
                    Text("F: \(fat.formatted(.number.precision(.fractionLength(1))))g")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }
            }
        }
    }
    
    // MARK: - Health Indicators Section
    
    private var healthIndicatorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Indicators")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)
            
            let indicators = healthIndicators
            
            if indicators.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("No health concerns detected")
                        .typography(Typography.subheadline)
                        .foregroundStyle(ColorTheme.secondaryText)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .clipShape(.rect(cornerRadius: 12))
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
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
    }
    
    private var healthIndicators: [HealthIndicator] {
        return getHealthIndicators()
    }
    
    private func getAllergensAndHealthSummary() -> String {
        let allergenCount = foodItem.allergens.count
        let healthCount = healthIndicators.count
        
        if allergenCount > 0 && healthCount > 0 {
            return "\(allergenCount) allergens, \(healthCount) health indicators"
        } else if allergenCount > 0 {
            return "\(allergenCount) allergens detected"
        } else if healthCount > 0 {
            return "\(healthCount) health indicators"
        } else {
            return "No warnings detected"
        }
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
            
            // Allergens & Health Indicators
            let totalWarnings = foodItem.allergens.count + healthIndicators.count
            if totalWarnings > 0 {
                Button(action: {
                    detailService.showingAllergens = true
                }) {
                    DetailSectionRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Allergens & Warnings", 
                        subtitle: getAllergensAndHealthSummary(),
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
                .typography(Typography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.accent)
                .clipShape(.rect(cornerRadius: 12))
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
            customQuantity = "\(multiplier.formatted(.number.precision(.fractionLength(1)))) × \(baseQuantity)"
        }
        foodItem.quantity = customQuantity
    }
    
    // MARK: - Health Analysis Functions
    
    private func getHealthIndicators() -> [HealthIndicator] {
        var indicators: [HealthIndicator] = []
        
        let name = foodItem.name.lowercased()
        let ingredients = foodItem.ingredients.map { $0.lowercased() }
        
        // Get all ingredients for this food item
        let allIngredients = FoodCompoundDatabase.shared.getIngredientsForFood(name: name, providedIngredients: ingredients)
        
        // Analyze each ingredient separately to maintain ingredient-compound mapping
        var compoundToIngredientMap: [String: [String]] = [:]
        
        for ingredient in allIngredients {
            let compoundsForIngredient = FoodCompoundDatabase.shared.analyzeIngredients([ingredient])
            
            for compound in compoundsForIngredient {
                if compoundToIngredientMap[compound.name] == nil {
                    compoundToIngredientMap[compound.name] = []
                }
                compoundToIngredientMap[compound.name]?.append(ingredient.capitalized)
            }
        }
        
        // Use comprehensive compound database to get all compounds
        let detectedCompounds = FoodCompoundDatabase.shared.getCompoundsForFood(name: name, ingredients: ingredients)
        
        // Group compounds by category for better organization
        let groupedCompounds = Dictionary(grouping: detectedCompounds) { $0.category }
        
        for (category, compounds) in groupedCompounds {
            let highestSeverity = compounds.max(by: { $0.severity.rawValue < $1.severity.rawValue })?.severity ?? .low
            let categoryColor: Color = {
                switch highestSeverity {
                case .high: return .red
                case .medium: return .orange
                case .low: return .yellow
                }
            }()
            
            // Create compound descriptions with ingredient sources
            let compoundDescriptions = compounds.compactMap { compound -> String? in
                if let ingredientSources = compoundToIngredientMap[compound.name], !ingredientSources.isEmpty {
                    let uniqueSources = Array(Set(ingredientSources)).sorted()
                    return "\(compound.name) - \(uniqueSources.joined(separator: ", "))"
                } else {
                    return compound.name
                }
            }
            
            indicators.append(HealthIndicator(
                text: category.rawValue,
                icon: getIconForCategory(category),
                color: categoryColor,
                severity: highestSeverity,
                description: "\(category.rawValue): \(compoundDescriptions.joined(separator: "; "))"
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
        case .alkaloid:
            return "exclamationmark.triangle.fill"
        case .biogenicAmine:
            return "allergens"
        case .phenolic:
            return "leaf.fill"
        case .heavyMetal:
            return "exclamationmark.triangle.fill"
        case .preservative:
            return "wind"
        case .naturalToxin:
            return "exclamationmark.triangle.fill"
        case .majorAllergen:
            return "exclamationmark.triangle.fill"
        case .foodIntolerance:
            return "allergens"
        case .toxicCompound:
            return "exclamationmark.triangle.fill"
        case .inflammatoryCompound:
            return "flame.fill"
        case .metabolicDisruptor:
            return "minus.circle.fill"
        case .neurologicalTrigger:
            return "brain.head.profile"
        }
    }
}

// MARK: - Supporting Views

struct HealthIndicatorBadge: View {
    let indicator: HealthIndicator
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(indicator.icon)
                        .typography(Typography.caption)
                    Text(indicator.text)
                        .typography(Typography.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(indicator.color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(indicator.color.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(indicator.severity.borderColor.opacity(0.3), lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
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

// MARK: - Supporting Views (reused from existing components)

struct DetailSectionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var iconColor: Color = ColorTheme.primary
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .typography(Typography.title2)
                .foregroundStyle(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .typography(Typography.headline)
                    .foregroundStyle(ColorTheme.primaryText)
                
                Text(subtitle)
                    .typography(Typography.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
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
                    nutritionFactsPanel
                    micronutrientPanel
                }
                .padding()
            }
            .navigationTitle("Nutrition Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var nutritionFactsPanel: some View {
        nutritionPanel(
            title: "Nutrition Facts",
            rows: nutritionFactsRows,
            emptyMessage: nil
        )
    }

    private var micronutrientPanel: some View {
        nutritionPanel(
            title: "Vitamins & Minerals",
            rows: micronutrientRows,
            emptyMessage: "No vitamin or mineral data available"
        )
    }

    private func nutritionPanel(
        title: String,
        rows: [NutritionFactRow],
        emptyMessage: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            if let emptyMessage, rows.allSatisfy({ $0.value == nil }) {
                EmptyStateView(message: emptyMessage, imageName: "leaf")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(ColorTheme.cardBackground)
                    .clipShape(.rect(cornerRadius: 12))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        NutritionFactRowView(row: row)

                        if index < rows.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(ColorTheme.cardBackground)
                .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    private var nutritionFactsRows: [NutritionFactRow] {
        [
            .init(label: "Calories", value: foodItem.nutrition.calories.map(Double.init), unit: "kcal", fractionDigits: 0, dailyValueReference: nil),
            .init(label: "Total Fat", value: foodItem.nutrition.fat ?? detailValue("Total Fat"), unit: "g", fractionDigits: 1, dailyValueReference: 78),
            .init(label: "Saturated Fat", value: detailValue("Saturated Fat"), unit: "g", fractionDigits: 1, dailyValueReference: 20),
            .init(label: "Trans Fat", value: detailValue("Trans Fat"), unit: "g", fractionDigits: 1, dailyValueReference: nil),
            .init(label: "Cholesterol", value: detailValue("Cholesterol"), unit: "mg", fractionDigits: 1, dailyValueReference: 300),
            .init(label: "Sodium", value: foodItem.nutrition.sodium ?? detailValue("Sodium"), unit: "mg", fractionDigits: 0, dailyValueReference: 2300),
            .init(label: "Total Carbohydrate", value: foodItem.nutrition.carbs ?? detailValue("Total Carbohydrate"), unit: "g", fractionDigits: 1, dailyValueReference: 275),
            .init(label: "Dietary Fiber", value: foodItem.nutrition.fiber ?? detailValue("Dietary Fiber"), unit: "g", fractionDigits: 1, dailyValueReference: 28),
            .init(label: "Total Sugars", value: foodItem.nutrition.sugar ?? detailValue("Total Sugars"), unit: "g", fractionDigits: 1, dailyValueReference: nil),
            .init(label: "Added Sugars", value: detailValue("Added Sugars"), unit: "g", fractionDigits: 1, dailyValueReference: 50),
            .init(label: "Protein", value: foodItem.nutrition.protein ?? detailValue("Protein"), unit: "g", fractionDigits: 1, dailyValueReference: nil)
        ]
    }

    private var micronutrientRows: [NutritionFactRow] {
        [
            .init(label: "Vitamin D", value: detailValue("Vitamin D"), unit: "mcg", fractionDigits: 2, dailyValueReference: 20),
            .init(label: "Calcium", value: detailValue("Calcium"), unit: "mg", fractionDigits: 2, dailyValueReference: 1300),
            .init(label: "Iron", value: detailValue("Iron"), unit: "mg", fractionDigits: 2, dailyValueReference: 18),
            .init(label: "Potassium", value: detailValue("Potassium"), unit: "mg", fractionDigits: 2, dailyValueReference: 4700),
            .init(label: "Vitamin A", value: detailValue("Vitamin A"), unit: "mcg", fractionDigits: 2, dailyValueReference: 900),
            .init(label: "Vitamin C", value: detailValue("Vitamin C"), unit: "mg", fractionDigits: 2, dailyValueReference: 90),
            .init(label: "Vitamin E", value: detailValue("Vitamin E"), unit: "mg", fractionDigits: 2, dailyValueReference: 15),
            .init(label: "Vitamin K", value: detailValue("Vitamin K"), unit: "mcg", fractionDigits: 2, dailyValueReference: 120),
            .init(label: "Thiamin", value: detailValue("Thiamin"), unit: "mg", fractionDigits: 2, dailyValueReference: 1.2),
            .init(label: "Riboflavin", value: detailValue("Riboflavin"), unit: "mg", fractionDigits: 2, dailyValueReference: 1.3),
            .init(label: "Niacin", value: detailValue("Niacin"), unit: "mg", fractionDigits: 2, dailyValueReference: 16),
            .init(label: "Vitamin B6", value: detailValue("Vitamin B6"), unit: "mg", fractionDigits: 2, dailyValueReference: 1.7),
            .init(label: "Folate", value: detailValue("Folate"), unit: "mcg", fractionDigits: 2, dailyValueReference: 400),
            .init(label: "Vitamin B12", value: detailValue("Vitamin B12"), unit: "mcg", fractionDigits: 2, dailyValueReference: 2.4),
            .init(label: "Biotin", value: detailValue("Biotin"), unit: "mcg", fractionDigits: 2, dailyValueReference: 30),
            .init(label: "Pantothenic Acid", value: detailValue("Pantothenic Acid"), unit: "mg", fractionDigits: 2, dailyValueReference: 5),
            .init(label: "Magnesium", value: detailValue("Magnesium"), unit: "mg", fractionDigits: 2, dailyValueReference: 420),
            .init(label: "Phosphorus", value: detailValue("Phosphorus"), unit: "mg", fractionDigits: 2, dailyValueReference: 1250),
            .init(label: "Zinc", value: detailValue("Zinc"), unit: "mg", fractionDigits: 2, dailyValueReference: 11),
            .init(label: "Copper", value: detailValue("Copper"), unit: "mg", fractionDigits: 2, dailyValueReference: 0.9),
            .init(label: "Manganese", value: detailValue("Manganese"), unit: "mg", fractionDigits: 2, dailyValueReference: 2.3),
            .init(label: "Selenium", value: detailValue("Selenium"), unit: "mcg", fractionDigits: 2, dailyValueReference: 55)
        ]
    }

    private func detailValue(_ label: String) -> Double? {
        nutritionDetailsValue(for: label)
    }

    private func nutritionDetailsValue(for label: String) -> Double? {
        let lookupKeys = [
            label,
            label.replacingOccurrences(of: " ", with: "_").lowercased(),
            label.lowercased()
        ]

        for key in lookupKeys {
            if let value = foodItem.nutritionDetails[key] {
                return NutrientValueParser.number(from: value)
            }
        }

        if let fallback = foodItem.nutritionDetails.first(where: {
            $0.key.lowercased() == label.lowercased() ||
            $0.key.lowercased() == label.replacingOccurrences(of: " ", with: "_").lowercased()
        })?.value {
            return NutrientValueParser.number(from: fallback)
        }

        return nil
    }

    private struct NutritionFactRow: Identifiable {
        let label: String
        let value: Double?
        let unit: String
        let fractionDigits: Int
        let dailyValueReference: Double?

        var id: String { label }

        var dailyValuePercent: Double? {
            guard let value, let dailyValueReference, dailyValueReference > 0 else { return nil }
            return value / dailyValueReference * 100
        }
    }

    private struct NutritionFactRowView: View {
        let row: NutritionFactRow

        var body: some View {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.label)
                        .typography(Typography.subheadline)
                        .foregroundStyle(ColorTheme.primaryText)

                    if let dailyValuePercent = row.dailyValuePercent {
                        Text("\(dailyValuePercent.formatted(.number.precision(.fractionLength(0))))% DV")
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                }

                Spacer()

                if let value = row.value {
                    HStack(spacing: 4) {
                        Text(value.formatted(.number.precision(.fractionLength(row.fractionDigits...row.fractionDigits))))
                            .typography(Typography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorTheme.primaryText)

                        Text(row.unit)
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                } else {
                    Text("Not available")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct NutritionDetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(formattedLabel)
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            Text(formattedValue)
                .typography(Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(ColorTheme.primaryText)
            
            if !unit.isEmpty {
                Text(unit)
                    .typography(Typography.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 8))
    }
    
    private var formattedLabel: String {
        label.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    private var formattedValue: String {
        if let doubleValue = Double(value) {
            return doubleValue.formatted(.number.precision(.fractionLength(1)))
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
            return "calories"
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
                                .foregroundStyle(ColorTheme.secondaryText.opacity(0.5))
                            
                            Text("No Ingredients Listed")
                                .typography(Typography.headline)
                                .foregroundStyle(ColorTheme.primaryText)
                            
                            Text("Ingredient information is not available for this food item.")
                                .typography(Typography.subheadline)
                                .foregroundStyle(ColorTheme.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding()
                    } else {
                        Text("Ingredients are listed in order of predominance by weight.")
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.secondaryText)
                            .padding(.horizontal)
                        
                        ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                            HStack {
                                Text("\(index + 1).")
                                    .typography(Typography.caption)
                                    .foregroundStyle(ColorTheme.secondaryText)
                                    .frame(width: 24, alignment: .leading)
                                
                                Text(ingredient.capitalized)
                                    .typography(Typography.body)
                                    .foregroundStyle(ColorTheme.primaryText)
                                
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
                ToolbarItem(placement: .topBarTrailing) {
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
    let healthIndicators: [HealthIndicator]
    
    init(allergens: [String], healthIndicators: [HealthIndicator] = []) {
        self.allergens = allergens
        self.healthIndicators = healthIndicators
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if allergens.isEmpty && healthIndicators.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(ColorTheme.success)
                            
                            Text("No Known Allergens or Warnings")
                                .typography(Typography.headline)
                                .foregroundStyle(ColorTheme.primaryText)
                            
                            Text("No common allergens or health indicators were detected in this food item. However, always check the original packaging for complete allergen information.")
                                .typography(Typography.subheadline)
                                .foregroundStyle(ColorTheme.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding()
                    } else {
                        // Allergens section
                        if !allergens.isEmpty {
                            Text("Allergens:")
                                .typography(Typography.headline)
                                .foregroundStyle(ColorTheme.primaryText)
                                .padding(.horizontal)
                            
                            Text("This food contains or may contain the following allergens:")
                                .typography(Typography.subheadline)
                                .foregroundStyle(ColorTheme.secondaryText)
                                .padding(.horizontal)
                            
                            ForEach(allergens, id: \.self) { allergen in
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(ColorTheme.error)
                                    
                                    Text(allergen)
                                        .typography(Typography.body)
                                        .foregroundStyle(ColorTheme.primaryText)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(ColorTheme.error.opacity(0.1))
                                .clipShape(.rect(cornerRadius: 12))
                                .padding(.horizontal)
                            }
                        }
                        
                        // Health Indicators section
                        if !healthIndicators.isEmpty {
                            if !allergens.isEmpty {
                                Divider()
                                    .padding(.horizontal)
                            }
                            
                            Text("Health Indicators:")
                                .typography(Typography.headline)
                                .foregroundStyle(ColorTheme.primaryText)
                                .padding(.horizontal)
                            
                            Text("Compounds that may affect your health:")
                                .typography(Typography.subheadline)
                                .foregroundStyle(ColorTheme.secondaryText)
                                .padding(.horizontal)
                            
                            ForEach(healthIndicators, id: \.text) { indicator in
                                VStack(alignment: .leading, spacing: 8) {
                                    // Category header
                                    HStack {
                                        Image(systemName: indicator.icon)
                                            .foregroundStyle(indicator.color)
                                        
                                        Text(indicator.text)
                                            .typography(Typography.headline)
                                            .foregroundStyle(ColorTheme.primaryText)
                                        
                                        Spacer()
                                    }
                                    
                                    // Description of what this category does
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Description:")
                                            .typography(Typography.subheadline)
                                            .foregroundStyle(ColorTheme.secondaryText)
                                            .padding(.leading, 24) // Indent to align with icon
                                        
                                        Text(getCategoryDescription(indicator.text))
                                            .typography(Typography.caption)
                                            .foregroundStyle(ColorTheme.secondaryText)
                                            .padding(.leading, 24) // Indent to align with icon
                                    }
                                    
                                    // Individual compounds - smaller and grey
                                    VStack(alignment: .leading, spacing: 2) {
                                        ForEach(getCompoundsFromDescription(indicator.description), id: \.self) { compound in
                                            Text(compound)
                                                .typography(Typography.caption)
                                                .foregroundStyle(ColorTheme.secondaryText)
                                                .padding(.leading, 24) // Indent to align with icon
                                        }
                                    }
                                }
                                .padding()
                                .background(indicator.color.opacity(0.1))
                                .clipShape(.rect(cornerRadius: 12))
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Allergens & Warnings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Helper function to parse compound descriptions
    private func getCompoundsFromDescription(_ description: String) -> [String] {
        // Remove the category prefix (e.g., "Food Intolerances: ")
        let withoutPrefix = description.components(separatedBy: ": ").dropFirst().joined(separator: ": ")
        
        // Split by semicolon to get individual compounds (don't split on comma within ingredient lists)
        return withoutPrefix.components(separatedBy: "; ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    // Helper function to get category descriptions
    private func getCategoryDescription(_ categoryName: String) -> String {
        switch categoryName {
        case "Food Intolerances":
            return "Compounds that can cause digestive issues, gas, bloating, or discomfort in sensitive individuals."
        case "Phenolic Compounds":
            return "Natural plant compounds that act as antioxidants but may cause sensitivity reactions in some people."
        case "Neurological Triggers":
            return "Substances that can affect the nervous system, potentially causing headaches, anxiety, or sleep issues."
        case "Metabolic Disruptors":
            return "Compounds that may interfere with normal metabolism, blood sugar regulation, or nutrient absorption."
        case "Inflammatory Compounds":
            return "Substances that may trigger inflammatory responses in the body, potentially causing joint pain or digestive issues."
        case "Major Allergens":
            return "Common allergens that can cause severe allergic reactions including anaphylaxis in sensitive individuals."
        case "Toxic Compounds":
            return "Naturally occurring or synthetic compounds that may be harmful in larger quantities or to sensitive individuals."
        case "Alkaloids":
            return "Natural plant compounds that can have psychoactive or physiological effects on the body."
        case "Biogenic Amines":
            return "Compounds formed during fermentation or aging that can trigger headaches or blood pressure changes."
        case "Heavy Metals":
            return "Metallic elements that can accumulate in the body and potentially cause health issues over time."
        case "Preservatives & Additives":
            return "Chemical compounds added to food for preservation that may cause sensitivity reactions in some people."
        case "Natural Toxins":
            return "Naturally occurring compounds in foods that can be harmful in certain quantities or preparation methods."
        default:
            return "Compounds that may affect your health in various ways."
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