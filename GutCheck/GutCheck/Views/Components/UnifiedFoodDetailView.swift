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
    
    init(foodItem: FoodItem, style: FoodDetailStyle = .standard) {
        self._foodItem = State(initialValue: foodItem)
        self.config = FoodDetailConfig.config(for: style)
        self.baseNutrition = foodItem.nutrition
        self.baseQuantity = foodItem.quantity
        self._customQuantity = State(initialValue: foodItem.quantity)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $detailService.showingNutritionDetails) {
                NutritionDetailsView(foodItem: foodItem)
            }
            .sheet(isPresented: $detailService.showingIngredients) {
                IngredientsView(ingredients: foodItem.ingredients)
            }
            .sheet(isPresented: $detailService.showingAllergens) {
                AllergensView(allergens: foodItem.allergens)
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
            // Use unified meal builder service
            MealBuilderService.shared.addFoodItem(foodItem)
            dismiss()
        }) {
            Text("Add to Meal")
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
                        Text("Detailed Nutrition Information")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            // Primary macronutrients from nutrition
                            if let protein = foodItem.nutrition.protein {
                                nutritionGridItem("Protein", value: protein, unit: "g")
                            }
                            if let carbs = foodItem.nutrition.carbs {
                                nutritionGridItem("Carbs", value: carbs, unit: "g")
                            }
                            if let fat = foodItem.nutrition.fat {
                                nutritionGridItem("Fat", value: fat, unit: "g")
                            }
                            if let fiber = foodItem.nutrition.fiber {
                                nutritionGridItem("Fiber", value: fiber, unit: "g")
                            }
                            if let sugar = foodItem.nutrition.sugar {
                                nutritionGridItem("Sugar", value: sugar, unit: "g")
                            }
                            if let sodium = foodItem.nutrition.sodium {
                                nutritionGridItem("Sodium", value: sodium, unit: "mg")
                            }
                            
                            // Additional nutrition from nutritionDetails dictionary
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
        let usedKeys = ["protein", "carbs", "fat", "calories", "brand", "source", "barcode", 
                       "saturated_fat", "cholesterol", "potassium", "calcium", "iron", "vitamin_a", "vitamin_c"]
        
        return foodItem.nutritionDetails
            .filter { key, value in
                !usedKeys.contains(key) &&
                value != "N/A" && value != "0" && value != "0.0" && !value.isEmpty
            }
            .sorted { $0.key < $1.key }
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
        VStack(alignment: .leading, spacing: 4) {
            Text(label.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primaryText)
        }
        .padding(8)
        .background(ColorTheme.surface)
        .cornerRadius(8)
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

// MARK: - Preview

#Preview {
    NavigationStack {
        UnifiedFoodDetailView(
            foodItem: FoodItem(
                name: "Organic Greek Yogurt",
                quantity: "1 cup",
                estimatedWeightInGrams: 245,
                ingredients: ["cultured pasteurized nonfat milk", "live active cultures"],
                allergens: ["Dairy"],
                nutrition: NutritionInfo(
                    calories: 150,
                    protein: 20.0,
                    carbs: 9.0,
                    fat: 4.0,
                    fiber: 0.0,
                    sugar: 9.0,
                    sodium: 65.0
                ),
                source: .barcode,
                nutritionDetails: [
                    "brand": "Organic Valley",
                    "calcium_dv": "25",
                    "vitamin_b12_mcg": "1.4",
                    "saturated_fat": "2.5"
                ]
            ),
            style: .full
        )
    }
}
