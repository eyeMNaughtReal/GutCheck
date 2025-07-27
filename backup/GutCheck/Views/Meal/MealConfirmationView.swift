import SwiftUI

struct MealConfirmationView: View {
    let meal: Meal
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @StateObject private var viewModel = MealConfirmationViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Meal Summary Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(meal.name)
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text(meal.date.formatted(.dateTime.hour().minute()))
                            .foregroundColor(.secondary)
                    }
                    
                    if let notes = meal.notes {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Label("\(meal.type.rawValue)", systemImage: "clock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .roundedCard()
                
                // Nutrition Summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Nutrition Summary")
                        .font(.title2)
                        .bold()
                    
                    if let nutrition = viewModel.totalNutrition {
                        NutritionSummaryView(nutrition: nutrition)
                    }
                }
                .padding()
                .roundedCard()
                
                // Food Items
                VStack(alignment: .leading, spacing: 16) {
                    Text("Food Items")
                        .font(.title2)
                        .bold()
                    
                    ForEach(meal.foodItems) { item in
                        MealConfirmationFoodItemRow(item: item)
                    }
                }
                .padding()
                .roundedCard()
                
                // AI Analysis
                if let analysis = viewModel.aiAnalysis {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Smart Analysis")
                            .font(.title2)
                            .bold()
                        
                        ForEach(analysis.insights, id: \.self) { insight in
                            Label(insight, systemImage: "brain")
                                .font(.subheadline)
                                .padding(.vertical, 4)
                        }
                        
                        if !analysis.warnings.isEmpty {
                            Divider()
                            
                            ForEach(analysis.warnings, id: \.self) { warning in
                                Label(warning, systemImage: "exclamationmark.triangle")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding()
                    .roundedCard()
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: confirmMeal) {
                        if viewModel.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Confirm & Save")
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Edit Meal") {
                        navigationCoordinator.currentNavigationPath.wrappedValue.removeLast()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.background)
                    .foregroundColor(ColorTheme.primary)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(ColorTheme.primary, lineWidth: 1)
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Confirm Meal")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error Saving Meal", isPresented: $viewModel.showError, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        })
        .task {
            await viewModel.analyzeMeal(meal)
        }
    }
    
    private func confirmMeal() {
        Task {
            if await viewModel.saveMeal(meal) {
                navigationCoordinator.popToRoot()
            }
        }
    }
}

// MARK: - Supporting Views

private struct NutritionSummaryView: View {
    let nutrition: NutritionInfo
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                NutritionValueView(
                    label: "Calories",
                    value: "\(Int(nutrition.calories ?? 0))",
                    unit: "kcal"
                )
                Divider()
                NutritionValueView(
                    label: "Protein",
                    value: String(format: "%.1f", nutrition.protein ?? 0),
                    unit: "g"
                )
                Divider()
                NutritionValueView(
                    label: "Carbs",
                    value: String(format: "%.1f", nutrition.carbs ?? 0),
                    unit: "g"
                )
                Divider()
                NutritionValueView(
                    label: "Fat",
                    value: String(format: "%.1f", nutrition.fat ?? 0),
                    unit: "g"
                )
            }
            
            if let fiber = nutrition.fiber {
                HStack {
                    Label("Fiber", systemImage: "leaf")
                    Spacer()
                    Text("\(String(format: "%.1f", fiber))g")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            if let sugar = nutrition.sugar {
                HStack {
                    Label("Sugar", systemImage: "cube")
                    Spacer()
                    Text("\(String(format: "%.1f", sugar))g")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
    }
}

private struct NutritionValueView: View {
    let label: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MealConfirmationFoodItemRow: View {
    let item: FoodItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Food image placeholder - FoodItem doesn't have imageUrl property
            Image(systemName: "fork.knife.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(ColorTheme.primary.opacity(0.3))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.headline)
                
                Text(item.quantity)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let brand = item.nutritionDetails["brand"] {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let calories = item.nutrition.calories {
                Text("\(Int(calories)) cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Supporting Types

struct MealAnalysis {
    let insights: [String]
    let warnings: [String]
}

#Preview {
    NavigationView {
        MealConfirmationView(meal: Meal(
            name: "Lunch",
            date: Date(),
            type: .lunch,
            source: .manual,
            foodItems: [
                FoodItem(
                    name: "Greek Yogurt",
                    quantity: "1 cup",
                    nutrition: NutritionInfo(calories: 120)
                ),
                FoodItem(
                    name: "Granola",
                    quantity: "0.5 cup",
                    nutrition: NutritionInfo(calories: 200)
                )
            ],
            notes: "Quick lunch at home",
            createdBy: "preview-user"
        ))
        .environmentObject(NavigationCoordinator())
    }
}
