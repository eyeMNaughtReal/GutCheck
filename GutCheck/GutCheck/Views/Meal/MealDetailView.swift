 //
//  MealDetailView.swift
//  GutCheck
//
//  Created by Mark Conley on 7/14/25.
//

import SwiftUI
import FirebaseFirestore

struct MealDetailView: View {
    @StateObject private var viewModel: MealDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    init(meal: Meal) {
        self._viewModel = StateObject(wrappedValue: MealDetailViewModel(meal: meal))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(viewModel.isEditing ? "Edit Meal" : "Meal Details")
                        .font(.title2.bold())
                        .foregroundColor(ColorTheme.primaryText)
                    
                    if viewModel.isEditing {
                        TextField("Meal name", text: $viewModel.meal.name)
                            .font(.headline)
                            .padding()
                            .background(ColorTheme.surface)
                            .cornerRadius(12)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(viewModel.meal.name)
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                    }
                    
                    HStack {
                        mealBadge(type: viewModel.meal.type)
                        
                        Text(viewModel.formattedDateTime)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                }
                .padding(.horizontal)
                
                // Nutrition summary
                NutritionSummaryCard(nutrition: viewModel.totalNutrition)
                    .padding(.horizontal)
                
                // Food items list
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Food Items")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Spacer()
                        
                        if viewModel.isEditing {
                            Button(action: {
                                viewModel.addNewFoodItem()
                            }) {
                                Label("Add", systemImage: "plus")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.primary)
                            }
                        }
                    }
                    
                    if viewModel.meal.foodItems.isEmpty {
                        emptyFoodItemsView
                    } else {
                        ForEach(viewModel.meal.foodItems) { item in
                            if viewModel.isEditing {
                                UnifiedFoodDetailView(foodItem: item, style: .compact)
                                // TODO: Add edit/delete functionality to compact view
                            } else {
                                Button(action: {
                                    navigationCoordinator.navigateTo(.foodDetail(item))
                                }) {
                                    UnifiedFoodDetailView(foodItem: item, style: .compact)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    if viewModel.isEditing {
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(ColorTheme.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ColorTheme.border, lineWidth: 1)
                            )
                    } else if let notes = viewModel.meal.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(ColorTheme.primaryText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ColorTheme.surface)
                            .cornerRadius(12)
                    } else {
                        Text("No notes added")
                            .font(.body)
                            .foregroundColor(ColorTheme.secondaryText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ColorTheme.surface)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Source information
                HStack {
                    Text("Source:")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Text(viewModel.sourceDescription)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Spacer()
                    
                    Text("Created: \(viewModel.formattedDate)")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                .padding(.horizontal)
                
                // Tags
                if !viewModel.meal.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.meal.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(ColorTheme.accent.opacity(0.2))
                                        .foregroundColor(ColorTheme.text)
                                        .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Action buttons - only show when editing (Save/Cancel)
                if viewModel.isEditing {
                    HStack(spacing: 16) {
                        // Cancel button
                        Button(action: {
                            viewModel.cancelEditing()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(ColorTheme.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(ColorTheme.surface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorTheme.border, lineWidth: 1)
                                )
                        }
                        
                        // Save button
                        Button(action: {
                            viewModel.saveMeal()
                        }) {
                            HStack(spacing: 8) {
                                if viewModel.isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(viewModel.isSaving ? "Saving..." : "Save")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.accent)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isSaving)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .padding(.top, 16)
        }
        .navigationTitle(viewModel.isEditing ? "Edit Meal" : "Meal Details")
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(.keyboard, edges: .bottom) // Allow content to scroll under keyboard
        .toolbar {
            if !viewModel.isEditing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.startEditing()
                        }) {
                            Label("Edit Meal", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            viewModel.shareAsPDF()
                        }) {
                            Label("Share PDF", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            viewModel.confirmDelete()
                        }) {
                            Label("Delete Meal", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            } else {
                // When editing, add Cancel button to toolbar
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.cancelEditing()
                    }
                }
            }
        }
        .alert("Delete Meal?", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteMeal() }
            }
        } message: {
            Text("Are you sure you want to delete this meal? This action cannot be undone.")
        }
        .alert("Error", isPresented: $viewModel.showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(item: $viewModel.editingFoodItem) { foodItem in
            EditFoodItemView(foodItem: foodItem) { updatedItem in
                viewModel.updateFoodItem(updatedItem)
            }
        }
    }
    
    private var emptyFoodItemsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 36))
                .foregroundColor(ColorTheme.secondaryText.opacity(0.5))
            
            Text("No food items")
                .font(.headline)
                .foregroundColor(ColorTheme.secondaryText)
            
            if viewModel.isEditing {
                Text("Tap \"Add\" to add food items to this meal")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
    
    private func mealBadge(type: MealType) -> some View {
        Text(type.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(mealTypeColor(type).opacity(0.2))
            .foregroundColor(mealTypeColor(type))
            .cornerRadius(8)
    }
    
    private func mealTypeColor(_ type: MealType) -> Color {
        switch type {
        case .breakfast:
            return .orange
        case .lunch:
            return .green
        case .dinner:
            return .blue
        case .snack:
            return .purple
        case .drink:
            return .cyan
        }
    }
}

// Using shared FoodItemDetailRow component from Components/

struct EditFoodItemView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var foodItem: FoodItem
    let onSave: (FoodItem) -> Void
    
    init(foodItem: FoodItem, onSave: @escaping (FoodItem) -> Void) {
        self._foodItem = State(initialValue: foodItem)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Food name
                    TextField("Food name", text: $foodItem.name)
                        .font(.title2)
                        .padding()
                        .background(ColorTheme.surface)
                        .cornerRadius(12)
                    
                    // Serving size
                    HStack {
                        Text("Serving Size:")
                            .font(.headline)
                        
                        TextField("e.g. 1 cup, 100g", text: $foodItem.quantity)
                            .padding()
                            .background(ColorTheme.surface)
                            .cornerRadius(12)
                    }
                    
                    // Weight in grams
                    HStack {
                        Text("Weight (g):")
                            .font(.headline)
                        
                        Spacer()
                        
                        TextField("0", value: $foodItem.estimatedWeightInGrams, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .padding()
                            .frame(width: 120)
                            .background(ColorTheme.surface)
                            .cornerRadius(12)
                    }
                    
                    // Nutrition information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition Information")
                            .font(.headline)
                        
                        // Calories
                        HStack {
                            Text("Calories:")
                            Spacer()
                            TextField("0", value: $foodItem.nutrition.calories, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                            Text("kcal")
                        }
                        .padding()
                        .background(ColorTheme.surface)
                        .cornerRadius(12)
                        
                        // Protein
                        HStack {
                            Text("Protein:")
                            Spacer()
                            TextField("0", value: $foodItem.nutrition.protein, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("g")
                        }
                        .padding()
                        .background(ColorTheme.surface)
                        .cornerRadius(12)
                        
                        // Carbs
                        HStack {
                            Text("Carbs:")
                            Spacer()
                            TextField("0", value: $foodItem.nutrition.carbs, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("g")
                        }
                        .padding()
                        .background(ColorTheme.surface)
                        .cornerRadius(12)
                        
                        // Fat
                        HStack {
                            Text("Fat:")
                            Spacer()
                            TextField("0", value: $foodItem.nutrition.fat, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("g")
                        }
                        .padding()
                        .background(ColorTheme.surface)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Food Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(foodItem)
                        dismiss()
                    }
                }
            }
        }
    }
}

// Preview
#Preview {
    NavigationStack {
        MealDetailView(meal: Meal(
            name: "Breakfast",
            date: Date(),
            type: .breakfast,
            source: .manual,
            foodItems: [
                {
                    var oatmealNutrition = NutritionInfo()
                    oatmealNutrition.calories = 158
                    oatmealNutrition.protein = 6.0
                    oatmealNutrition.carbs = 27.0
                    oatmealNutrition.fat = 3.0
                    return FoodItem(
                        name: "Oatmeal",
                        quantity: "1 cup",
                        estimatedWeightInGrams: 240,
                        nutrition: oatmealNutrition
                    )
                }(),
                {
                    var bananaNutrition = NutritionInfo()
                    bananaNutrition.calories = 105
                    bananaNutrition.protein = 1.0
                    bananaNutrition.carbs = 27.0
                    bananaNutrition.fat = 0.0
                    return FoodItem(
                        name: "Banana",
                        quantity: "1 medium",
                        estimatedWeightInGrams: 118,
                        nutrition: bananaNutrition
                    )
                }()
            ],
            notes: "Quick breakfast before work",
            tags: ["morning", "healthy"],
            createdBy: "testUser"
        ))
    }
}
