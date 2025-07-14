//
//  FoodSearchView.swift
//  GutCheck
//
//  Created on 7/14/25.
//

import SwiftUI

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FoodSearchViewModel()
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ColorTheme.secondaryText)
                
                TextField("Search for food items", text: $viewModel.searchQuery)
                    .submitLabel(.search)
                    .onSubmit {
                        viewModel.search()
                    }
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                }
            }
            .padding()
            .background(ColorTheme.surface)
            
            // Divider
            Rectangle()
                .fill(ColorTheme.border)
                .frame(height: 1)
            
            // Results or suggestions
            if viewModel.isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasSearched && viewModel.searchResults.isEmpty {
                emptyResultsView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.searchQuery.isEmpty || viewModel.hasSearched {
                searchResultsList
            } else {
                suggestionsList
            }
        }
        .navigationTitle("Search Foods")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.selectedFoodItem) { foodItem in
            FoodItemDetailView(foodItem: foodItem) { updatedItem in
                viewModel.addToMeal(updatedItem)
                navigationCoordinator.mealNavigationPath.append(MealLoggingDestination.mealBuilder)
            }
        }
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(ColorTheme.secondaryText.opacity(0.5))
            
            Text("No results found")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            Text("Try a different search term or add a custom food item")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.createCustomFoodItem()
            }) {
                Text("Create Custom Food Item")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(ColorTheme.primary)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                if !viewModel.searchResults.isEmpty {
                    Section {
                        ForEach(viewModel.searchResults) { item in
                            FoodItemResultRow(item: item) {
                                viewModel.selectFoodItem(item)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Search Results")
                                .font(.headline)
                                .foregroundColor(ColorTheme.primaryText)
                            Spacer()
                            Text("\(viewModel.searchResults.count) items")
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                        .padding()
                        .background(ColorTheme.background.opacity(0.9))
                    }
                }
                
                // Add custom item button
                Button(action: {
                    viewModel.createCustomFoodItem()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(ColorTheme.primary)
                        Text("Create Custom Food Item")
                            .foregroundColor(ColorTheme.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(ColorTheme.primary, lineWidth: 1)
                    )
                }
                .padding()
            }
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
                    .padding(.horizontal)
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
                                viewModel.selectFoodItem(item)
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
                // Optional image
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
                    
                    Text(item.quantity)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    // Nutrition preview
                    if let calories = item.nutrition.calories {
                        Text("\(calories) kcal")
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Add button
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(ColorTheme.primary)
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct FoodItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var foodItem: FoodItem
    let onAdd: (FoodItem) -> Void
    
    init(foodItem: FoodItem, onAdd: @escaping (FoodItem) -> Void) {
        self._foodItem = State(initialValue: foodItem)
        self.onAdd = onAdd
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Food image placeholder
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ColorTheme.accent.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.system(size: 48))
                                .foregroundColor(ColorTheme.accent)
                        )
                    
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
                    
                    // Add button
                    Button(action: {
                        onAdd(foodItem)
                        dismiss()
                    }) {
                        Text("Add to Meal")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.accent)
                            .cornerRadius(12)
                    }
                    .padding(.top, 16)
                }
                .padding()
            }
            .navigationTitle("Food Details")
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
    FoodSearchView()
        .environmentObject(NavigationCoordinator())
}
