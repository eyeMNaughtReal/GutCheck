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
    @State private var navigationPath = NavigationPath()
    var onSelect: ((FoodItem) -> Void)?
    
    init(onSelect: ((FoodItem) -> Void)? = nil) {
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Search bar with prominent Search button
                VStack(spacing: 12) {
                    HStack {
                        TextField("Search foods", text: $viewModel.searchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                viewModel.search()
                            }
                        
                        Button(action: {
                            viewModel.search()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "magnifyingglass")
                                Text("Search")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(ColorTheme.accent)
                            .cornerRadius(8)
                        }
                        .disabled(viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    // Clear button if there's text
                    if !viewModel.searchQuery.isEmpty {
                        HStack {
                            Spacer()
                            Button("Clear") {
                                viewModel.searchQuery = ""
                                viewModel.searchResults = []
                                viewModel.hasSearched = false
                            }
                            .foregroundColor(ColorTheme.accent)
                            .font(.caption)
                        }
                    }
                }
                .padding()

                // Results or suggestions
                if viewModel.isSearching {
                    loadingView
                } else if !viewModel.hasSearched && viewModel.searchQuery.isEmpty {
                    suggestionsList
                } else if viewModel.searchResults.isEmpty && viewModel.hasSearched {
                    noResultsView
                } else if !viewModel.searchResults.isEmpty {
                    resultsList
                } else {
                    // Show suggestions when user has typed but not searched yet
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(ColorTheme.accent.opacity(0.6))
                        
                        Text("Ready to Search")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text("Tap the Search button to find foods")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Search Food")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: FoodItem.self) { foodItem in
                UnifiedFoodDetailView(foodItem: foodItem)
            }
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
                let customFoodItem = FoodItem(
                    name: viewModel.searchQuery,
                    quantity: "1 serving",
                    nutrition: NutritionInfo()
                )
                navigationPath.append(customFoodItem)
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
                    FoodItemResultRow(
                        item: item,
                        onSelect: {
                            // Navigate to food detail view
                            navigationPath.append(item)
                        },
                        onAdd: {
                            // Tap on + button -> use the callback if provided, otherwise navigate to detail view
                            if let onSelect = onSelect {
                                onSelect(item)
                            } else {
                                navigationPath.append(item)
                            }
                        }
                    )
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
                            SimpleRecentFoodRow(
                                item: item,
                                onSelect: {
                                    // Tap on item details -> navigate to comprehensive food detail view
                                    navigationPath.append(item)
                                },
                                onAdd: {
                                    // Tap on + button -> use the callback if provided, otherwise navigate to detail view
                                    if let onSelect = onSelect {
                                        onSelect(item)
                                    } else {
                                        navigationPath.append(item)
                                    }
                                }
                            )
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
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Food image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(ColorTheme.accent.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "fork.knife")
                        .foregroundColor(ColorTheme.accent)
                )
            
            // Details - tappable area for showing detail view
            Button(action: onSelect) {
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
                    
                    // Much cleaner with convenience initializers
                    item.nutrition.compactPreview()
                    
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
            }
            .buttonStyle(PlainButtonStyle())
            
            // Add button - separate action for direct add
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(ColorTheme.primary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

struct SimpleRecentFoodRow: View {
    let item: FoodItem
    let onSelect: () -> Void
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Food image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(ColorTheme.accent.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "fork.knife")
                        .foregroundColor(ColorTheme.accent)
                        .font(.system(size: 16))
                )
            
            // Details - tappable area for showing detail view
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(item.quantity)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    // Nutrition preview - matching screenshot style
                    HStack(spacing: 8) {
                        if let calories = item.nutrition.calories {
                            Text("\(Int(calories)) kcal")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ColorTheme.accent.opacity(0.2))
                                .foregroundColor(ColorTheme.accent)
                                .cornerRadius(4)
                        }
                        
                        if let protein = item.nutrition.protein {
                            Text("\(String(format: "%.1f", protein)) P")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        if let carbs = item.nutrition.carbs {
                            Text("\(String(format: "%.1f", carbs)) C")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                        
                        if let fat = item.nutrition.fat {
                            Text("\(String(format: "%.1f", fat)) F")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                        }
                    }
                    
                    // Allergens display
                    if !item.allergens.isEmpty {
                        HStack {
                            ForEach(item.allergens.prefix(2), id: \.self) { allergen in
                                Text(allergen)
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(ColorTheme.error.opacity(0.2))
                                    .foregroundColor(ColorTheme.error)
                                    .cornerRadius(4)
                            }
                            if item.allergens.count > 2 {
                                Text("+\(item.allergens.count - 2)")
                                    .font(.caption2)
                                    .foregroundColor(ColorTheme.secondaryText)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Add button - separate action for direct add
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(ColorTheme.primary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
    }
}

// Preview
#Preview {
    FoodSearchView()
}
