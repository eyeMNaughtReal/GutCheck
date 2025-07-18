//
//  FoodItemDetailComponents.swift
//  GutCheck
//
//  Shared components for food item detail views

import SwiftUI

struct EnhancedFoodItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var foodItem: FoodItem
    @State private var servingMultiplier: Double = 1.0
    @State private var customQuantity: String = ""
    @State private var showingNutritionDetails = false
    @State private var showingIngredients = false
    @State private var showingAllergens = false
    
    let onAdd: (FoodItem) -> Void
    
    // Store original nutrition values for calculations
    private let baseNutrition: NutritionInfo
    private let baseQuantity: String
    
    init(foodItem: FoodItem, onAdd: @escaping (FoodItem) -> Void) {
        self._foodItem = State(initialValue: foodItem)
        self.onAdd = onAdd
        self.baseNutrition = foodItem.nutrition
        self.baseQuantity = foodItem.quantity
        self._customQuantity = State(initialValue: foodItem.quantity)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    foodHeaderSection
                    servingSizeSection
                    nutritionSummarySection
                    detailSectionsLinks
                    addToMealButton
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
            .sheet(isPresented: $showingNutritionDetails) {
                FoodNutritionDetailsView(foodItem: foodItem)
            }
            .sheet(isPresented: $showingIngredients) {
                IngredientsView(ingredients: foodItem.ingredients)
            }
            .sheet(isPresented: $showingAllergens) {
                AllergensView(allergens: foodItem.allergens)
            }
            .onChange(of: servingMultiplier) { _, newValue in
                updateNutritionForServing(multiplier: newValue)
            }
        }
    }
    
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
            
            TextField("Food name", text: $foodItem.name)
                .font(.title2)
                .fontWeight(.bold)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let brand = foodItem.nutritionDetails["brand"] {
                Text(brand)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.accent)
            }
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
    
    private var nutritionSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Facts")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(spacing: 8) {
                if let calories = foodItem.nutrition.calories {
                    MacroRow(label: "Calories", value: "\(calories)", unit: "kcal", color: .orange)
                }
                
                if let protein = foodItem.nutrition.protein {
                    MacroRow(label: "Protein", value: String(format: "%.1f", protein), unit: "g", color: .blue)
                }
                
                if let carbs = foodItem.nutrition.carbs {
                    MacroRow(label: "Carbohydrates", value: String(format: "%.1f", carbs), unit: "g", color: .green)
                }
                
                if let fat = foodItem.nutrition.fat {
                    MacroRow(label: "Fat", value: String(format: "%.1f", fat), unit: "g", color: .red)
                }
                
                if let fiber = foodItem.nutrition.fiber {
                    MacroRow(label: "Fiber", value: String(format: "%.1f", fiber), unit: "g", color: .brown)
                }
                
                if let sodium = foodItem.nutrition.sodium {
                    MacroRow(label: "Sodium", value: String(format: "%.0f", sodium), unit: "mg", color: .purple)
                }
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(12)
            .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
        }
    }
    
    private var detailSectionsLinks: some View {
        VStack(spacing: 12) {
            // Full nutrition details
            Button(action: {
                showingNutritionDetails = true
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
                    showingIngredients = true
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
                    showingAllergens = true
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
            onAdd(foodItem)
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

struct MacroRow: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(ColorTheme.primaryText)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
        }
    }
}

struct DetailSectionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var iconColor: Color = ColorTheme.accent
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(subtitle)
                    .font(.caption)
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
                                
                                Text(allergen.capitalized)
                                    .font(.body)
                                    .foregroundColor(ColorTheme.primaryText)
                                
                                Spacer()
                            }
                            .padding()
                            .background(ColorTheme.error.opacity(0.1))
                            .cornerRadius(8)
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

struct NutritionBadge: View {
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            Text(unit)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(4)
    }
}

struct EnhancedFoodItemResultRow: View {
    let item: FoodItem
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Food image placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(ColorTheme.accent.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(ColorTheme.accent)
                    )
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    if let brand = item.nutritionDetails["brand"] {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.accent)
                    }
                    
                    Text(item.quantity)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    // Nutrition preview
                    HStack(spacing: 8) {
                        if let calories = item.nutrition.calories {
                            NutritionBadge(value: "\(calories)", unit: "kcal", color: .orange)
                        }
                        
                        if let protein = item.nutrition.protein {
                            NutritionBadge(value: String(format: "%.1f", protein), unit: "P", color: .blue)
                        }
                        
                        if let carbs = item.nutrition.carbs {
                            NutritionBadge(value: String(format: "%.1f", carbs), unit: "C", color: .green)
                        }
                        
                        if let fat = item.nutrition.fat {
                            NutritionBadge(value: String(format: "%.1f", fat), unit: "F", color: .red)
                        }
                    }
                    
                    // Allergens preview
                    if !item.allergens.isEmpty {
                        HStack {
                            ForEach(item.allergens.prefix(3), id: \.self) { allergen in
                                Text(allergen)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ColorTheme.error.opacity(0.2))
                                    .foregroundColor(ColorTheme.error)
                                    .cornerRadius(4)
                            }
                            if item.allergens.count > 3 {
                                Text("+\(item.allergens.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(ColorTheme.secondaryText)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Add button
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(ColorTheme.primary)
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(12)
            .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}
