//
//  MealDetailView.swift
//  GutCheck
//
//  Created by Mark Conley on 7/14/25.
//


//
//  MealDetailView.swift
//  GutCheck
//
//  Created on 7/14/25.
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
                                FoodItemDetailRow(
                                    foodItem: item,
                                    isEditing: true,
                                    onEdit: {
                                        viewModel.editFoodItem(item)
                                    },
                                    onDelete: {
                                        viewModel.removeFoodItem(item)
                                    }
                                )
                            } else {
                                Button(action: {
                                    navigationCoordinator.navigateTo(.foodDetail(item))
                                }) {
                                    FoodItemDetailRow(
                                        foodItem: item,
                                        isEditing: false,
                                        onEdit: {},
                                        onDelete: {}
                                    )
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
                
                // Action buttons
                HStack(spacing: 16) {
                    if viewModel.isEditing {
                        // Save and Cancel buttons when editing
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
                        
                        Button(action: {
                            viewModel.saveMeal()
                        }) {
                            Text("Save")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(ColorTheme.accent)
                                .cornerRadius(12)
                        }
                        .disabled(viewModel.isSaving)
                        
                    } else {
                        // Edit and Delete buttons when viewing
                        Button(action: {
                            viewModel.startEditing()
                        }) {
                            Text("Edit")
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
                        
                        Button(action: {
                            viewModel.confirmDelete()
                        }) {
                            Text("Delete")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(ColorTheme.error)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top, 16)
        }
        .navigationTitle(viewModel.isEditing ? "Edit Meal" : "Meal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.isEditing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.startEditing()
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            viewModel.confirmDelete()
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button(action: {
                            viewModel.shareAsPDF()
                        }) {
                            Label("Share PDF", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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

struct FoodItemDetailRow: View {
    let foodItem: FoodItem
    let isEditing: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(foodItem.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                if isEditing {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(ColorTheme.primary)
                    }
                    .padding(.horizontal, 4)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(ColorTheme.error)
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Quantity
            Text("\(foodItem.quantity)")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
            
            // Nutrition details
            if let calories = foodItem.nutrition.calories {
                Text("\(calories) kcal")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primaryText)
            }
            
            HStack(spacing: 12) {
                if let protein = foodItem.nutrition.protein {
                    UnifiedNutritionBadge(protein: protein)
                }
                if let carbs = foodItem.nutrition.carbs {
                    UnifiedNutritionBadge(carbs: carbs)
                }
                if let fat = foodItem.nutrition.fat {
                    UnifiedNutritionBadge(fat: fat)
                }
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
    
    private func nutrientBadge(label: String, value: Double, unit: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
            
            Text(String(format: "%.1f", value) + unit)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

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
                FoodItem(
                    name: "Oatmeal",
                    quantity: "1 cup",
                    estimatedWeightInGrams: 240,
                    nutrition: NutritionInfo(calories: 158, protein: 6, carbs: 27, fat: 3)
                ),
                FoodItem(
                    name: "Banana",
                    quantity: "1 medium",
                    estimatedWeightInGrams: 118,
                    nutrition: NutritionInfo(calories: 105, protein: 1, carbs: 27, fat: 0)
                )
            ],
            notes: "Quick breakfast before work",
            tags: ["morning", "healthy"],
            createdBy: "testUser"
        ))
    }
}
