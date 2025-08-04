import SwiftUI

// Temporary enums for the simplified view
enum TempMealType: String, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch" 
    case dinner = "dinner"
    case snack = "snack"
    case drink = "drink"
}

/// Temporary simplified food detail view for testing navigation
struct SimpleFoodDetailView: View {
    let foodItem: FoodItem
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMealType: TempMealType = .lunch
    @State private var showingSuccessAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(foodItem.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(foodItem.quantity)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Basic nutrition
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nutrition")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Calories")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(foodItem.nutrition.calories ?? 0)")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Protein")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", foodItem.nutrition.protein ?? 0.0))g")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Carbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", foodItem.nutrition.carbs ?? 0.0))g")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Fat")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", foodItem.nutrition.fat ?? 0.0))g")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Ingredients
                if !foodItem.ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients")
                            .font(.headline)
                        
                        Text(foodItem.ingredients.joined(separator: ", "))
                            .font(.body)
                    }
                    .padding()
                }
                
                // Allergens
                if !foodItem.allergens.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Allergens")
                            .font(.headline)
                        
                        Text(foodItem.allergens.joined(separator: ", "))
                            .font(.body)
                            .foregroundColor(.red)
                    }
                    .padding()
                }
                
                // Meal Type Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add to Meal")
                        .font(.headline)
                    
                    // Meal type picker
                    Picker("Meal Type", selection: $selectedMealType) {
                        Text("Breakfast").tag(TempMealType.breakfast)
                        Text("Lunch").tag(TempMealType.lunch)
                        Text("Dinner").tag(TempMealType.dinner)
                        Text("Snack").tag(TempMealType.snack)
                        Text("Drink").tag(TempMealType.drink)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Add to Meal button
                    Button(action: {
                        addToMeal()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to \(selectedMealType.rawValue.capitalized)")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .navigationTitle("Food Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Added to Meal!", isPresented: $showingSuccessAlert) {
            Button("OK") { 
                dismiss() 
            }
        } message: {
            Text("\(foodItem.name) has been added to your \(selectedMealType.rawValue) meal.")
        }
    }
    
    private func addToMeal() {
        // For now, just show success alert
        // In the real implementation, this would use MealBuilderService
        print("🍽️ Adding \(foodItem.name) to \(selectedMealType.rawValue) meal")
        
        // TODO: Integrate with actual MealBuilderService
        // mealBuilder.mealType = selectedMealType.toMealType()
        // mealBuilder.addFoodItem(foodItem)
        
        // Show success alert
        showingSuccessAlert = true
    }
}

#Preview {
    NavigationStack {
        // Preview will be updated once FoodItem type is available
        Text("Preview not available - FoodItem type missing")
            .navigationTitle("Food Details")
    }
}
