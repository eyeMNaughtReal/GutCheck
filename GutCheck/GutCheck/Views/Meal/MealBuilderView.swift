//
//  MealBuilderView.swift
//  GutCheck
//
//  Created on 7/14/25.
//  Updated with Phase 2 Accessibility - February 23, 2026
//

import SwiftUI

struct MealBuilderView: View {
    var mealId: String? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) var router
    @Environment(RefreshManager.self) var refreshManager
    @State private var mealService = MealBuilderService.shared
    @State private var showingConfirmation = false
    @State private var showingDiscard = false
    @State private var showingFoodOptions = false
    @State private var showingPhotoIdentification = false
    @State private var showingVoiceLogging = false
    @State private var editingFoodItem: FoodItem?
@State private var loadError: String? = nil
    @State private var riskService = MealRiskPredictionService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Meal details section
            VStack(spacing: 16) {
                // Meal name field
                TextField("Meal name", text: $mealService.mealName)
                    .typography(Typography.headline)
                    .padding()
                    .background(ColorTheme.surface)
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorTheme.border, lineWidth: 1)
                    )
                    .accessibleFormField(label: "Meal name")
                    .accessibilityHint("Enter a descriptive name for this meal, like Breakfast or Chicken Salad")
                    .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.mealNameField)
                
                VStack(spacing: 12) {
                    // Meal type pills
                    ScrollView(.horizontal) {
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
                                        .foregroundStyle(isSelected ? .white : ColorTheme.primaryText)
                                        .clipShape(.rect(cornerRadius: 20))
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
                    .scrollIndicators(.hidden)
                    .background(ColorTheme.surface)
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorTheme.border, lineWidth: 1)
                    )
                    .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.mealTypePicker)
                    
                    // When the meal was eaten.
                    //
                    // A native DatePicker in place of a button that opened a
                    // separate sheet. The old control was the worse of the two
                    // patterns this app already contained: it copied the
                    // surface fill, corner radius and border of the meal-name
                    // field directly above it, so two controls looked identical
                    // while one typed and one presented a modal. Its value was
                    // also centred, which no iOS form does.
                    //
                    // The custom accessibility label is gone deliberately —
                    // DatePicker provides one, and both together made VoiceOver
                    // announce the date twice.
                    DatePicker(
                        "Date & Time",
                        // A meal cannot have been eaten in the future, and a
                        // stray future timestamp would place it outside the
                        // window symptom correlation examines.
                        selection: $mealService.mealDate,
                        in: ...Date.now,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .padding()
                    .background(ColorTheme.surface)
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorTheme.border, lineWidth: 1)
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
                    
                    // Risk assessment card
                    if !mealService.currentMeal.isEmpty,
                       let assessment = riskService.predictRisk(for: mealService.currentMeal) {
                        MealRiskAssessmentCard(assessment: assessment)
                            .padding(.horizontal)
                    }
                    
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
                            .foregroundStyle(ColorTheme.secondaryText)
                        
                        TextEditor(text: $mealService.notes)
                            .typography(Typography.body)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(ColorTheme.surface)
                            .clipShape(.rect(cornerRadius: 12))
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
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 12))
                }
                .accessibleButton(
                    label: "Add Food Item",
                    hint: "Tap to search for and add food items to your meal"
                )
                .accessibilityIdentifier(AccessibilityIdentifiers.MealBuilder.addFoodButton)

                // The two capture options, alongside search rather than behind
                // it: searching stays a single tap for the common case.
                //
                // Side by side rather than stacked. This bar already carried
                // three rows of chrome before voice existed (#428), and a
                // fourth full-width button pushed the food list off the
                // screen entirely on a 6.3" phone.
                HStack(spacing: 12) {
                    Button(action: {
                        HapticManager.shared.medium()
                        showingPhotoIdentification = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "camera.viewfinder")
                            Text("From Photo")
                                .typography(Typography.button)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ColorTheme.surface)
                        .foregroundStyle(ColorTheme.primaryText)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                    .accessibleButton(
                        label: "Identify from Photo",
                        hint: "Tap to photograph your plate and identify the foods on it"
                    )
                    .accessibilityIdentifier("mealBuilder.photoIdentify.button")

                    Button(action: {
                        HapticManager.shared.medium()
                        showingVoiceLogging = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "waveform")
                            Text("Speak It")
                                .typography(Typography.button)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ColorTheme.surface)
                        .foregroundStyle(ColorTheme.primaryText)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                    .accessibleButton(
                        label: "Speak Your Meal",
                        hint: "Tap to describe your meal out loud and have the foods looked up"
                    )
                    .accessibilityIdentifier("mealBuilder.voiceLog.button")
                }

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
                            .foregroundStyle(ColorTheme.primaryText)
                            .clipShape(.rect(cornerRadius: 12))
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
                                AccessibilityAnnouncement.announce("Failed to save meal")
                            }
                        }
                    }) {
                        Text("Save Meal")
                            .typography(Typography.button)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.accent)
                            .foregroundStyle(ColorTheme.text)
                            .clipShape(.rect(cornerRadius: 12))
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
                    
                }
            }
            .padding()
            .background(
                Rectangle()
                    .fill(ColorTheme.cardBackground)
                    .shadow(color: ColorTheme.shadowColor, radius: 8, x: 0, y: -4)
            )
        }
        .navigationTitle(mealId == nil ? "Build Your Meal" : "Edit Meal")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let id = mealId {
                do {
                    try await mealService.loadMeal(id: id)
                } catch {
                    loadError = error.localizedDescription
                }
            }
            await riskService.loadHistoricalData()
        }
        .alert("Failed to Load Meal", isPresented: .constant(loadError != nil)) {
            Button("OK") { loadError = nil; dismiss() }
        } message: {
            Text(loadError ?? "")
        }
        .sheet(isPresented: $showingFoodOptions) {
            NavigationStack {
                FoodSearchView { foodItem in
                    MealBuilderService.shared.addFoodItem(foodItem)
                    showingFoodOptions = false
                }
                .environment(router)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingPhotoIdentification) {
            // Declining or failing identification opens search, so the flow
            // always ends somewhere the person can finish logging.
            PhotoFoodLoggingView {
                showingFoodOptions = true
            }
        }
        .sheet(isPresented: $showingVoiceLogging) {
            // Same fallback as the photo flow: every dead end opens search.
            VoiceMealLoggingView {
                showingFoodOptions = true
            }
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
            Button("OK") { dismiss() }
        } message: {
            Text("Your meal has been successfully saved.")
        }
        // Clearing happens here rather than in saveMeal() or in the OK handler.
        // saveMeal() emptied the form while the sheet was still on screen, so
        // the confirmation appeared over a blank meal and read as a failure;
        // clearing on OK still let that blank frame show before the sheet
        // finished closing. By onDisappear the sheet is gone, so the emptied
        // form is never visible either way.
        .onDisappear {
            mealService.clearMeal()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundStyle(ColorTheme.secondaryText.opacity(0.5))
                .accessibleDecorative()
            
            Text("No food items yet")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.secondaryText)
            
            Text("Tap \"Add Food Item\" to start building your meal")
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
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
                    .foregroundStyle(ColorTheme.primaryText)
                
                Spacer()
                
                Text("\(Int(nutrition.calories ?? 0)) calories")
                    .typography(Typography.headline)
                    .foregroundStyle(ColorTheme.primary)
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
        .clipShape(.rect(cornerRadius: 12))
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
                .foregroundStyle(ColorTheme.secondaryText)
            
            Text("\((value ?? 0).formatted(.number.precision(.fractionLength(1)))) \(unit)")
                .typography(Typography.headline)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \((value ?? 0).formatted(.number.precision(.fractionLength(1)))) \(unit)")
    }
}


// Preview
#Preview {
    NavigationStack {
        MealBuilderView()
    }
}
