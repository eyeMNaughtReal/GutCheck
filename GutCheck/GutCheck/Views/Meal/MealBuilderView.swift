//
//  MealBuilderView.swift
//  GutCheck
//
//  Created on 7/14/25.
//

import SwiftUI

struct MealBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mealService = MealBuilderService.shared
    @State private var showingDatePicker = false
    @State private var showingConfirmation = false
    @State private var showingDiscard = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Meal details section
            VStack(spacing: 16) {
                // Meal name field
                TextField("Meal name", text: $mealService.mealName)
                    .font(.headline)
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorTheme.border, lineWidth: 1)
                    )
                
                HStack(spacing: 12) {
                    // Meal type picker
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(ColorTheme.primary)
                        
                        Picker("Type", selection: $mealService.mealType) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorTheme.border, lineWidth: 1)
                    )
                    
                    // Date/time button
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(ColorTheme.primary)
                            Text(mealService.formattedDateTime)
                                .foregroundColor(ColorTheme.primaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ColorTheme.border, lineWidth: 1)
                        )
                    }
                }
            }
            .padding()
            .background(ColorTheme.background)
            
            // Divider
            Rectangle()
                .fill(ColorTheme.border)
                .frame(height: 1)
            
            // Food items list
            ScrollView {
                VStack(spacing: 16) {
                    // Nutrition summary
                    NutritionSummaryCard(nutrition: mealService.totalNutrition)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Food items
                    if mealService.currentMeal.isEmpty {
                        emptyStateView
                            .padding()
                    } else {
                        ForEach(mealService.currentMeal) { item in
                            FoodItemRow(
                                foodItem: item,
                                onEdit: {
                                    // TODO: Implement food item editing
                                },
                                onDelete: {
                                    mealService.removeFoodItem(item)
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                    
                    // Notes field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)
                        
                        TextEditor(text: $mealService.notes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(ColorTheme.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ColorTheme.border, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Bottom padding
                    Spacer().frame(height: 100)
                }
            }
            
            // Bottom buttons bar
            VStack(spacing: 12) {
                // Add food button
                Button(action: {
                    // TODO: Show food search/scanner modal
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Food Item")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                HStack(spacing: 12) {
                    // Cancel button
                    Button(action: {
                        if !mealService.currentMeal.isEmpty {
                            showingDiscard = true
                        } else {
                            dismiss()
                        }
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.surface)
                            .foregroundColor(ColorTheme.primaryText)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ColorTheme.border, lineWidth: 1)
                            )
                    }
                    
                    // Save button
                    Button(action: {
                        Task {
                            do {
                                _ = try await mealService.saveMeal()
                                showingConfirmation = true
                            } catch {
                                // TODO: Show error alert
                                Swift.print("❌ Failed to save meal: \(error)")
                            }
                        }
                    }) {
                        Text("Save Meal")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.accent)
                            .foregroundColor(ColorTheme.text)
                            .cornerRadius(12)
                    }
                    .disabled(mealService.currentMeal.isEmpty)
                    .opacity(mealService.currentMeal.isEmpty ? 0.6 : 1)
                }
            }
            .padding()
            .background(
                Rectangle()
                    .fill(ColorTheme.cardBackground)
                    .shadow(color: ColorTheme.shadowColor, radius: 8, x: 0, y: -4)
            )
        }
        .navigationTitle("Build Your Meal")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDatePicker) {
            DateTimePickerView(date: $mealService.mealDate)
        }
        .alert("Discard Meal?", isPresented: $showingDiscard) {
            Button("Cancel", role: .cancel) { }
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Are you sure you want to discard this meal? All food items will be lost.")
        }
        .alert("Meal Saved", isPresented: $showingConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your meal has been successfully saved.")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundColor(ColorTheme.secondaryText.opacity(0.5))
            
            Text("No food items yet")
                .font(.headline)
                .foregroundColor(ColorTheme.secondaryText)
            
            Text("Tap \"Add Food Item\" to start building your meal")
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
}

struct NutritionSummaryCard: View {
    let nutrition: NutritionInfo
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Nutrition Summary")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                Text("\(nutrition.calories ?? 0) kcal")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primary)
            }
            
            Divider()
            
            // Macros
            HStack(spacing: 16) {
                NutrientLabel(name: "Protein", value: nutrition.protein, unit: "g", color: .blue)
                NutrientLabel(name: "Carbs", value: nutrition.carbs, unit: "g", color: .green)
                NutrientLabel(name: "Fat", value: nutrition.fat, unit: "g", color: .red)
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
}

struct NutrientLabel: View {
    let name: String
    let value: Double?
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
            
            Text("\(value?.formatted() ?? "0") \(unit)")
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FoodItemRow: View {
    let foodItem: FoodItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name and actions
            HStack {
                Text(foodItem.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
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
            
            // Quantity
            Text("\(foodItem.quantity)")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
            
            // Nutrition preview
            HStack(spacing: 12) {
                if let calories = foodItem.nutrition.calories {
                    Text("\(calories) kcal")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ColorTheme.accent.opacity(0.2))
                        .foregroundColor(ColorTheme.text)
                        .cornerRadius(8)
                }
                
                if let protein = foodItem.nutrition.protein {
                    Text("P: \(protein)g")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(ColorTheme.text)
                        .cornerRadius(8)
                }
                
                if let carbs = foodItem.nutrition.carbs {
                    Text("C: \(carbs)g")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(ColorTheme.text)
                        .cornerRadius(8)
                }
                
                if let fat = foodItem.nutrition.fat {
                    Text("F: \(fat)g")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(ColorTheme.text)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
}

struct DateTimePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select date and time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .padding()
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Select Date & Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
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
        MealBuilderView()
    }
}
