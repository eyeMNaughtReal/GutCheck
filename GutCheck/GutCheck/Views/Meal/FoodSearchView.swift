//
//  FoodSearchView.swift
//  GutCheck
//
//  Enhanced version with full nutrition data and serving size adjustments

import SwiftUI
import Combine

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FoodSearchViewModel()
    @State private var selectedFoodItem: FoodItem? = nil
    @State private var showDetailSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    TextField("Search foods", text: $viewModel.searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            viewModel.search()
                        }
                    
                    Button(action: {
                        viewModel.search()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(ColorTheme.accent)
                    }
                }
                .padding()

                // Results or suggestions
                if viewModel.isSearching {
                    loadingView
                } else if viewModel.searchResults.isEmpty {
                    if viewModel.searchQuery.isEmpty {
                        suggestionsList
                    } else {
                        noResultsView
                    }
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadRecentItems()
            }
            .sheet(isPresented: $showDetailSheet) {
                if let item = selectedFoodItem {
                    EnhancedFoodItemDetailView(foodItem: item) { addedItem in
                        viewModel.addToMeal(addedItem)
                        showDetailSheet = false
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Searching...")
                .foregroundColor(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(ColorTheme.secondaryText.opacity(0.5))
            
            Text("No Results Found")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            Text("Try searching with different keywords")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Add Custom Food") {
                selectedFoodItem = FoodItem(
                    name: viewModel.searchQuery,
                    quantity: "1 serving",
                    nutrition: NutritionInfo()
                )
                showDetailSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(viewModel.searchResults) { item in
                    FoodItemResultRow(item: item) {
                        selectedFoodItem = item
                        showDetailSheet = true
                    }
                }
            }
            .padding(.top)
        }
    }

    private var suggestionsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Recent searches
                if !viewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Searches")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        ForEach(viewModel.recentSearches, id: \.self) { searchTerm in
                            Button(action: {
                                viewModel.searchQuery = searchTerm
                                viewModel.search()
                            }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(ColorTheme.secondaryText)
                                    Text(searchTerm)
                                        .foregroundColor(ColorTheme.primaryText)
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                        .foregroundColor(ColorTheme.secondaryText)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Common food categories
                VStack(alignment: .leading, spacing: 8) {
                    Text("Common Categories")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(viewModel.foodCategories, id: \.self) { category in
                            Button(action: {
                                viewModel.searchQuery = category
                                viewModel.search()
                            }) {
                                HStack {
                                    Text(category)
                                        .font(.subheadline)
                                        .foregroundColor(ColorTheme.primaryText)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(ColorTheme.surface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorTheme.border, lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Recent items
                if !viewModel.recentItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Items")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        ForEach(viewModel.recentItems) { item in
                            FoodItemResultRow(item: item) {
                                selectedFoodItem = item
                                showDetailSheet = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
    }
}

struct FoodItemResultRow: View {
    let item: FoodItem
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Food image placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(ColorTheme.accent.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(ColorTheme.accent)
                    )
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    if let brand = item.nutritionDetails["brand"] {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.accent)
                    }
                    
                    Text(item.quantity)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    // Nutrition preview
                    HStack(spacing: 8) {
                        if let calories = item.nutrition.calories {
                            NutritionBadge(value: "\(calories)", unit: "kcal", color: .orange)
                        }
                        
                        if let protein = item.nutrition.protein {
                            NutritionBadge(value: String(format: "%.1f", protein), unit: "P", color: .blue)
                        }
                        
                        if let carbs = item.nutrition.carbs {
                            NutritionBadge(value: String(format: "%.1f", carbs), unit: "C", color: .green)
                        }
                        
                        if let fat = item.nutrition.fat {
                            NutritionBadge(value: String(format: "%.1f", fat), unit: "F", color: .red)
                        }
                    }
                    
                    // Allergens preview
                    if !item.allergens.isEmpty {
                        HStack {
                            ForEach(item.allergens.prefix(3), id: \.self) { allergen in
                                Text(allergen)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ColorTheme.error.opacity(0.2))
                                    .foregroundColor(ColorTheme.error)
                                    .cornerRadius(4)
                            }
                            if item.allergens.count > 3 {
                                Text("+\(item.allergens.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(ColorTheme.secondaryText)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Add button
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(ColorTheme.primary)
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(12)
            .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

// Preview
#Preview {
    FoodSearchView()
}
