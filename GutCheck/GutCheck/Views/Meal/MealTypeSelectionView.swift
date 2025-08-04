//
//  MealTypeSelectionView.swift
//  GutCheck
//
//  View for selecting meal type before adding food items to a meal
//

import SwiftUI

struct MealTypeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let foodItem: FoodItem
    let onMealTypeSelected: (MealType) -> Void
    
    @State private var selectedMealType: MealType = .lunch
    
    // Define meal types locally to avoid import issues
    private let mealTypes: [(type: String, display: String, description: String)] = [
        ("breakfast", "Breakfast", "Morning meal"),
        ("lunch", "Lunch", "Midday meal"),
        ("dinner", "Dinner", "Evening meal"),
        ("snack", "Snack", "Between meals"),
        ("drink", "Drink", "Beverages")
    ]
    
    init(foodItem: FoodItem, onMealTypeSelected: @escaping (MealType) -> Void) {
        self.foodItem = foodItem
        self.onMealTypeSelected = onMealTypeSelected
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Food item preview
                VStack(spacing: 12) {
                    Text("Add to Meal")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Select which meal to add \(foodItem.name) to:")
                        .font(.body)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Food item card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(foodItem.name)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            if let brand = foodItem.nutritionDetails["brand"], !brand.isEmpty {
                                Text(brand)
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            if let calories = foodItem.nutrition.calories {
                                Text("\(Int(calories)) cal")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .padding()
                .background(ColorTheme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ColorTheme.border, lineWidth: 1)
                )
                
                // Meal type selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Meal Type")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    VStack(spacing: 8) {
                        ForEach(mealTypes.indices, id: \.self) { index in
                            let mealTypeInfo = mealTypes[index]
                            let isSelected = selectedMealType.rawValue == mealTypeInfo.type
                            
                            Button(action: {
                                if let mealType = MealType(rawValue: mealTypeInfo.type) {
                                    selectedMealType = mealType
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mealTypeInfo.display)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(isSelected ? .white : ColorTheme.primaryText)
                                        
                                        Text(mealTypeInfo.description)
                                            .font(.caption)
                                            .foregroundColor(isSelected ? .white.opacity(0.8) : ColorTheme.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isSelected ? .white : ColorTheme.secondaryText)
                                }
                                .padding()
                                .background(isSelected ? ColorTheme.primary : ColorTheme.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? ColorTheme.primary : ColorTheme.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
                
                // Add to meal button
                Button(action: {
                    onMealTypeSelected(selectedMealType)
                    dismiss()
                }) {
                    Text("Add to \(mealTypes.first(where: { $0.type == selectedMealType.rawValue })?.display ?? "Meal")")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.primary)
                        .cornerRadius(12)
                }
                .padding(.bottom)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.primary)
                }
            }
        }
    }
}


