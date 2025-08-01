import SwiftUI

struct LogMealView: View {
    @StateObject private var viewModel = LogMealViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Log Meal")
                            .font(.title2.bold())
                            .foregroundColor(ColorTheme.primaryText)
                        TextField("Meal name", text: $viewModel.mealName)
                            .font(.headline)
                            .padding()
                            .background(ColorTheme.surface)
                            .cornerRadius(12)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Meal Type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meal Type")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorTheme.primaryText)

                        Picker("Meal Type", selection: $viewModel.mealType) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Food Items List
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Food Items")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorTheme.primaryText)
                            Spacer()
                            Button(action: {
                                viewModel.showFoodSearch = true
                            }) {
                                Label("Add", systemImage: "plus")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.primary)
                            }
                        }
                        
                        if viewModel.foodItems.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 36))
                                    .foregroundColor(ColorTheme.secondaryText.opacity(0.5))
                                Text("No food items")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.secondaryText)
                                Text("Tap + to add food items to this meal")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.secondaryText.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(ColorTheme.surface)
                            .cornerRadius(12)
                        } else {
                            ForEach(viewModel.foodItems) { item in
                                UnifiedFoodDetailView(foodItem: item, style: .compact)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(ColorTheme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ColorTheme.border.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: { dismiss() }) {
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
                            Task {
                                do {
                                    try await viewModel.saveMeal()
                                    dismiss()
                                } catch {
                                    // Handle error appropriately
                                    print("Error saving meal: \(error)")
                                }
                            }
                        }) {
                            HStack {
                                if viewModel.isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(viewModel.isSaving ? "Saving..." : "Save")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.accent)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isSaving)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(ColorTheme.background)
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showFoodSearch) { 
                FoodSearchView { selectedFood in
                    viewModel.foodItems.append(selectedFood)
                    viewModel.showFoodSearch = false
                }
            }
        }
    }
}

// Using shared FoodItemDetailRow component from Components/

#Preview {
    NavigationStack {
        LogMealView()
            .environmentObject(NavigationCoordinator())
    }
}
