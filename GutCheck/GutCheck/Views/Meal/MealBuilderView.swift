//
//  MealBuilderView.swift
//  GutCheck
//
//  Created on 7/14/25.
//  Updated with Phase 2 Accessibility - February 23, 2026
//

import SwiftUI

struct MealBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var refreshManager: RefreshManager
    @StateObject private var mealService = MealBuilderService.shared
    @State private var showingDatePicker = false
    @State private var showingConfirmation = false
    @State private var showingDiscard = false
    @State private var showingFoodOptions = false
    @State private var editingFoodItem: FoodItem?
    @State private var showingTemplateSave = false
    @State private var showingTemplateSaved = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Meal details section
            VStack(spacing: 16) {
                // Meal name field
                TextField("Meal name", text: $mealService.mealName)
                    .typography(Typography.headline)
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorTheme.border, lineWidth: 1)
                    )
                    .accessibleFormField(label: "Meal name")
                    .accessibilityHint("Enter a descriptive name for this meal, like Breakfast or Chicken Salad")
                    .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.mealNameField)
                
                VStack(spacing: 12) {
                    // Meal type pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                let isSelected = mealService.mealType == type
                                Button(action: {
                                    mealService.mealType = type
                                    HapticManager.shared.selection()
                                }) {
                                    Text(type.rawValue.capitalized)
                                        .typography(Typography.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? ColorTheme.primary : ColorTheme.surface)
                                        .foregroundColor(isSelected ? .white : ColorTheme.primaryText)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(isSelected ? Color.clear : ColorTheme.border, lineWidth: 1)
                                        )
                                }
                                .accessibilityLabel(type.rawValue.capitalized)
                                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                                .accessibilityHint("Select \(type.rawValue.capitalized) as the meal type")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(ColorTheme.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorTheme.border, lineWidth: 1)
                    )
                    .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.mealTypePicker)
                    
                    // Date/time button
                    Button(action: {
                        HapticManager.shared.light()
                        showingDatePicker = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(ColorTheme.primary)
                                .accessibleDecorative()
                            Text(mealService.formattedDateTime)
                                .typography(Typography.body)
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
                    .accessibleButton(
                        label: "Date and time: \(mealService.formattedDateTime)",
                        hint: "Tap to change the date and time of this meal"
                    )
                    .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.dateTimeButton)
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
                        .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.nutritionSummary)
                    
                    // Food items
                    if mealService.currentMeal.isEmpty {
                        emptyStateView
                            .padding()
                            .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.emptyState)
                    } else {
                        ForEach(Array(mealService.currentMeal.enumerated()), id: \.element.id) { index, item in
                            UnifiedFoodItemRow(
                                item: item,
                                style: .mealBuilder,
                                actions: FoodItemActions(
                                    onTap: {
                                        HapticManager.shared.light()
                                        editingFoodItem = item
                                    },
                                    onDelete: {
                                        HapticManager.shared.warning()
                                        mealService.removeFoodItem(item)
                                        
                                        // Announce deletion to VoiceOver
                                        AccessibilityAnnouncement.announce("\(item.name) removed from meal")
                                    }
                                )
                            )
                            .padding(.horizontal)
                            .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.foodItem(index))
                        }
                    }
                    
                    // Notes field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .typography(Typography.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)
                        
                        TextEditor(text: $mealService.notes)
                            .typography(Typography.body)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(ColorTheme.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ColorTheme.border, lineWidth: 1)
                            )
                            .accessibleFormField(label: "Notes")
                            .accessibilityHint("Add any additional notes about this meal, like how you felt or special ingredients")
                            .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.notesField)
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
                    HapticManager.shared.medium()
                    showingFoodOptions = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Food Item")
                            .typography(Typography.button)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .accessibleButton(
                    label: "Add Food Item",
                    hint: "Tap to search for and add food items to your meal"
                )
                .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.addFoodButton)
                
                HStack(spacing: 12) {
                    // Cancel button
                    Button(action: {
                        HapticManager.shared.light()
                        if !mealService.currentMeal.isEmpty {
                            showingDiscard = true
                        } else {
                            dismiss()
                        }
                    }) {
                        Text("Cancel")
                            .typography(Typography.button)
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
                    .accessibleButton(
                        label: "Cancel",
                        hint: mealService.currentMeal.isEmpty 
                            ? "Discard this meal and return to the previous screen"
                            : "Confirm discarding this meal before returning"
                    )
                    .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.cancelButton)
                    
                    // Save button
                    Button(action: {
                        Task {
                            do {
                                HapticManager.shared.success()
                                _ = try await mealService.saveMeal()
                                showingConfirmation = true
                                
                                // Announce to VoiceOver
                                AccessibilityAnnouncement.announce("Meal saved successfully")
                            } catch {
                                HapticManager.shared.error()
                                // TODO: Show error alert
                                Swift.print("❌ Failed to save meal: \(error)")
                                AccessibilityAnnouncement.announce("Failed to save meal")
                            }
                        }
                    }) {
                        Text("Save Meal")
                            .typography(Typography.button)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.accent)
                            .foregroundColor(ColorTheme.text)
                            .cornerRadius(12)
                    }
                    .disabled(mealService.currentMeal.isEmpty)
                    .opacity(mealService.currentMeal.isEmpty ? 0.6 : 1)
                    .accessibleButton(
                        label: "Save Meal",
                        hint: mealService.currentMeal.isEmpty 
                            ? "Add food items before saving"
                            : "Save this meal to your food diary"
                    )
                    .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.saveButton)
                    
                    // Save as Template button (only show when meal name is provided)
                    if !mealService.mealName.isEmpty && !mealService.currentMeal.isEmpty {
                        Button(action: {
                            HapticManager.shared.medium()
                            showingTemplateSave = true
                        }) {
                            HStack {
                                Image(systemName: "square.on.square")
                                    .font(.title3)
                                Text("Save as Template")
                                    .typography(Typography.button)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .accessibleButton(
                            label: "Save as Template",
                            hint: "Save this meal as a reusable template for future use"
                        )
                        .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.saveTemplateButton)
                    }
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
        .sheet(isPresented: $showingFoodOptions) {
            NavigationStack {
                FoodSearchView { foodItem in
                    MealBuilderService.shared.addFoodItem(foodItem)
                    showingFoodOptions = false
                }
                .environmentObject(router)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Save as Template", isPresented: $showingTemplateSave) {
            Button("Save Template") {
                Task {
                    do {
                        _ = try await mealService.saveAsTemplate()
                        showingTemplateSaved = true
                    } catch {
                        print("Error saving template: \(error)")
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Save '\(mealService.mealName)' as a reusable meal template?")
        }
        .alert("Template Saved", isPresented: $showingTemplateSaved) {
            Button("OK") { }
        } message: {
            Text("'\(mealService.mealName)' has been saved as a reusable template!")
        }
        .sheet(item: $editingFoodItem) { foodItem in
            UnifiedFoodDetailView(
                foodItem: foodItem, 
                style: .full,
                onUpdate: { updatedItem in
                    mealService.updateFoodItem(updatedItem)
                    editingFoodItem = nil
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
                .accessibleDecorative()
            
            Text("No food items yet")
                .typography(Typography.headline)
                .foregroundColor(ColorTheme.secondaryText)
            
            Text("Tap \"Add Food Item\" to start building your meal")
                .typography(Typography.caption)
                .foregroundColor(ColorTheme.secondaryText.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(ColorTheme.surface)
        .cornerRadius(12)
        .accessibleGroup(
            label: "No food items yet. Tap Add Food Item button to start building your meal",
            hint: nil
        )
    }
}

struct NutritionSummaryCard: View {
    let nutrition: NutritionInfo
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Nutrition Summary")
                    .typography(Typography.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                Text("\(Int(nutrition.calories ?? 0)) calories")
                    .typography(Typography.headline)
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
        .accessibleGroup(
            label: AccessibilityText.nutritionSummary(
                calories: Int(nutrition.calories ?? 0),
                protein: nutrition.protein ?? 0,
                carbs: nutrition.carbs ?? 0,
                fat: nutrition.fat ?? 0
            ),
            hint: "Total nutrition information for all food items in this meal"
        )
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
                .typography(Typography.caption)
                .foregroundColor(ColorTheme.secondaryText)
            
            Text("\(String(format: "%.1f", value ?? 0)) \(unit)")
                .typography(Typography.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \(String(format: "%.1f", value ?? 0)) \(unit)")
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
                    .accessibleFormField(
                        label: "Date and time",
                        value: date.formatted(date: .abbreviated, time: .shortened)
                    )
                    .accessibilityHint("Choose the date and time when you ate this meal")
                
                Spacer()
                
                Button("Done") {
                    HapticManager.shared.light()
                    AccessibilityAnnouncement.announce("Date and time updated")
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .accessibleButton(
                    label: "Done",
                    hint: "Confirm the selected date and time"
                )
            }
            .navigationTitle("Select Date & Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.shared.light()
                        dismiss()
                    }
                    .accessibleButton(
                        label: "Cancel",
                        hint: "Discard changes and close"
                    )
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
