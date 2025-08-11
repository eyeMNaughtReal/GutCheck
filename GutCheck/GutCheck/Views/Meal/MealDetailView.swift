import SwiftUI
import FirebaseFirestore

struct MealDetailView: View {
    @StateObject private var viewModel: MealDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var refreshManager: RefreshManager
    
    // New initializer that takes a meal ID
    init(mealId: String) {
        self._viewModel = StateObject(wrappedValue: MealDetailViewModel(mealId: mealId))
    }
    
    // Keep the original initializer for backward compatibility
    init(meal: Meal) {
        self._viewModel = StateObject(wrappedValue: MealDetailViewModel(meal: meal))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else {
                mealContentView
            }
        }
        .onAppear {
            if viewModel.mealId != nil {
                Task {
                    await viewModel.loadMeal()
                }
            }
        }
    }
    
    private func mealBadge(type: MealType) -> some View {
        Text(type.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(mealTypeColor(type).opacity(0.2))
            .foregroundColor(mealTypeColor(type))
            .cornerRadius(12)
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
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack {
            ProgressView("Loading meal details...")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mealContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                mealHeaderSection
                foodItemsSection
                nutritionSummarySection
                notesSection
            }
            .padding(.bottom, viewModel.isEditing ? 120 : 80)
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.isEditing {
                    editMenuButton
                }
            }
        }
        .overlay(alignment: .bottom) {
            if viewModel.isEditing {
                editingBottomBar
            }
        }
        .alert("Error", isPresented: $viewModel.showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .confirmationDialog(
            "Are you sure you want to delete this meal?",
            isPresented: $viewModel.showingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.deleteMeal() {
                        refreshManager.triggerRefresh()
                        router.navigateBack()
                    }
                }
            }
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                router.navigateBack()
            }
        }
    }
    
    private var mealHeaderSection: some View {
        VStack(spacing: 8) {
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
    }
    
    @ViewBuilder
    private var foodItemsSection: some View {
        if !viewModel.meal.foodItems.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Food Items")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                    .padding(.horizontal)
                
                ForEach(viewModel.meal.foodItems, id: \.id) { foodItem in
                    foodItemRow(foodItem)
                }
            }
        }
    }
    
    @ViewBuilder
    private var nutritionSummarySection: some View {
        if !viewModel.meal.foodItems.isEmpty {
            let totalNutrition = calculateTotalNutrition()
            VStack(alignment: .leading, spacing: 16) {
                Text("Nutrition Summary")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                    .padding(.horizontal)
                
                nutritionSummaryCard(nutrition: totalNutrition)
                    .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    private var notesSection: some View {
        if viewModel.isEditing {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                    .padding(.horizontal)
                
                TextField("Add notes about this meal...", text: Binding(
                    get: { viewModel.meal.notes ?? "" },
                    set: { viewModel.meal.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                    .lineLimit(3...6)
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        } else if let notes = viewModel.meal.notes, !notes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                    .padding(.horizontal)
                
                Text(notes)
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
    }
    
    private var editMenuButton: some View {
        Menu {
            Button {
                viewModel.isEditing = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                viewModel.showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    // MARK: - UI Components
    
    private var editingBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    viewModel.isEditing = false
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(ColorTheme.surface)
                .foregroundColor(ColorTheme.primaryText)
                .cornerRadius(8)
                
                Button("Save") {
                    Task {
                        if await viewModel.saveMeal() {
                            refreshManager.triggerRefresh()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(ColorTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(viewModel.isSaving)
            }
            .padding()
            .background(ColorTheme.background)
        }
    }
    
    private func foodItemRow(_ foodItem: FoodItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(foodItem.name)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(foodItem.quantity)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
            
            if let calories = foodItem.nutrition.calories {
                Text("\(calories) calories")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func nutritionSummaryCard(nutrition: NutritionInfo) -> some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Total Nutrition")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                Text("\(nutrition.calories ?? 0) calories")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primary)
            }
            
            Divider()
            
            // Macros
            HStack(spacing: 16) {
                nutritionItem(name: "Protein", value: nutrition.protein, unit: "g", color: .blue)
                nutritionItem(name: "Carbs", value: nutrition.carbs, unit: "g", color: .green)
                nutritionItem(name: "Fat", value: nutrition.fat, unit: "g", color: .red)
            }
            
            if let fiber = nutrition.fiber, fiber > 0 {
                HStack(spacing: 16) {
                    nutritionItem(name: "Fiber", value: fiber, unit: "g", color: .orange)
                    nutritionItem(name: "Sugar", value: nutrition.sugar, unit: "g", color: .purple)
                    nutritionItem(name: "Sodium", value: nutrition.sodium, unit: "mg", color: .gray)
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
    
    private func nutritionItem(name: String, value: Double?, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
            
            Text("\(String(format: "%.1f", value ?? 0))\(unit)")
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Functions
    
    private func calculateTotalNutrition() -> NutritionInfo {
        var total = NutritionInfo()
        
        for foodItem in viewModel.meal.foodItems {
            let nutrition = foodItem.nutrition
            
            total.calories = (total.calories ?? 0) + (nutrition.calories ?? 0)
            total.protein = (total.protein ?? 0) + (nutrition.protein ?? 0)
            total.carbs = (total.carbs ?? 0) + (nutrition.carbs ?? 0)
            total.fat = (total.fat ?? 0) + (nutrition.fat ?? 0)
            total.fiber = (total.fiber ?? 0) + (nutrition.fiber ?? 0)
            total.sugar = (total.sugar ?? 0) + (nutrition.sugar ?? 0)
            total.sodium = (total.sodium ?? 0) + (nutrition.sodium ?? 0)
        }
        
        return total
    }
}

#Preview {
    MealDetailView(meal: Meal.sampleMeal)
        .environmentObject(AppRouter.shared)
        .environmentObject(RefreshManager.shared)
}