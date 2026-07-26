//
//  FoodSearchView.swift
//  GutCheck
//
//  Enhanced version with full nutrition data and serving size adjustments
//  Updated with Phase 2 Accessibility - February 23, 2026

import SwiftUI
import Combine

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ServerStatusService.self) private var serverStatus
    @State private var viewModel = FoodSearchViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var selectedFoodItem: FoodItem?
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
                            .typography(Typography.body)
                            .onSubmit {
                                guard !serverStatus.isOffline else { return }
                                HapticManager.shared.light()
                                viewModel.search()
                            }
                            .accessibleFormField(label: "Search foods")
                            .accessibilityHint("Enter a food name to search the database")
                            .accessibilityIdentifier(AccessibilityIdentifiers.FoodSearch.searchField)
                        
                        Button(action: {
                            HapticManager.shared.medium()
                            viewModel.search()
                            AccessibilityAnnouncement.announce("Searching for \(viewModel.searchQuery)")
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "magnifyingglass")
                                Text("Search")
                                    .typography(Typography.button)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(ColorTheme.accent)
                            .clipShape(.rect(cornerRadius: 8))
                        }
                        .disabled(viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || serverStatus.isOffline)
                        .accessibleButton(
                            label: "Search",
                            hint: viewModel.searchQuery.isEmpty 
                                ? "Enter a search term first"
                                : "Search for \(viewModel.searchQuery)"
                        )
                        .accessibilityIdentifier(AccessibilityIdentifiers.FoodSearch.searchButton)
                    }
                    
                    // Clear button if there's text
                    if !viewModel.searchQuery.isEmpty {
                        HStack {
                            Spacer()
                            Button("Clear") {
                                HapticManager.shared.light()
                                viewModel.searchQuery = ""
                                viewModel.searchResults = []
                                viewModel.hasSearched = false
                                AccessibilityAnnouncement.announce("Search cleared")
                            }
                            .typography(Typography.caption)
                            .foregroundStyle(ColorTheme.accent)
                            .accessibleButton(
                                label: "Clear search",
                                hint: "Clear the search field and results"
                            )
                            .accessibilityIdentifier(AccessibilityIdentifiers.FoodSearch.clearButton)
                        }
                    }
                }
                .padding()

                // Results or suggestions
                if serverStatus.isOffline {
                    offlineView
                } else if viewModel.isSearching {
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
                            .foregroundStyle(ColorTheme.accent.opacity(0.6))

                        Text("Ready to Search")
                            .font(.headline)
                            .foregroundStyle(ColorTheme.primaryText)

                        Text("Tap the Search button to find foods")
                            .font(.subheadline)
                            .foregroundStyle(ColorTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Search Food")
            .navigationBarTitleDisplayMode(.inline)
            // Remove navigationDestination - will use sheet instead
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        HapticManager.shared.light()
                        dismiss()
                    }
                    .accessibleButton(
                        label: "Cancel",
                        hint: "Close food search and return"
                    )
                    .accessibilityIdentifier(AccessibilityIdentifiers.FoodSearch.cancelButton)
                }
            }
            .onAppear {
                viewModel.loadRecentItems()
            }
        }
        .sheet(item: $selectedFoodItem) { foodItem in
            UnifiedFoodDetailView(
                foodItem: foodItem,
                style: .full,
                onUpdate: { updatedItem in
                    // Handle the updated item if needed
                    if let onSelect = onSelect {
                        onSelect(updatedItem)
                    }
                    selectedFoodItem = nil
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var offlineView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(ColorTheme.warning)

            Text("You're Offline")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            Text("Food search requires an internet connection.\nYou can still add food manually.")
                .typography(Typography.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                HapticManager.shared.medium()
                let customFoodItem = FoodItem(
                    name: viewModel.searchQuery.isEmpty ? "Custom Food" : viewModel.searchQuery,
                    quantity: "1 serving",
                    nutrition: NutritionInfo()
                )
                selectedFoodItem = customFoodItem
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Custom Food")
                        .typography(Typography.button)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(ColorTheme.primary)
                .clipShape(.rect(cornerRadius: 10))
            }
            .accessibleButton(
                label: "Add Custom Food",
                hint: "Create a custom food item with manual entry"
            )
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Searching...")
                .typography(Typography.body)
                .foregroundStyle(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Searching for foods")
        .accessibilityIdentifier(AccessibilityIdentifiers.FoodSearch.loadingIndicator)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(ColorTheme.secondaryText.opacity(0.5))
                .accessibleDecorative()
            
            Text("No Results Found")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)
            
            Text("Try searching with different keywords")
                .typography(Typography.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Add Custom Food") {
                HapticManager.shared.medium()
                let customFoodItem = FoodItem(
                    name: viewModel.searchQuery,
                    quantity: "1 serving",
                    nutrition: NutritionInfo()
                )
                selectedFoodItem = customFoodItem
            }
            .buttonStyle(.borderedProminent)
            .accessibleButton(
                label: "Add Custom Food",
                hint: "Create a custom food item with the name \(viewModel.searchQuery)"
            )
            .accessibilityIdentifier(AccessibilityIdentifiers.FoodSearch.createCustomButton)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier(AccessibilityIdentifiers.FoodSearch.emptyState)
    }
    
    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, item in
                    FoodItemResultRow(
                        item: item,
                        onSelect: {
                            HapticManager.shared.light()
                            selectedFoodItem = item
                        },
                        onAdd: {
                            HapticManager.shared.success()
                            if let onSelect = onSelect {
                                onSelect(item)
                                AccessibilityAnnouncement.announce("\(item.name) added to meal")
                            } else {
                                selectedFoodItem = item
                            }
                        }
                    )
                    .accessibilityIdentifier(AccessibilityIdentifiers.FoodSearch.searchResult(index))
                }
            }
            .padding(.top)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.FoodSearch.resultsList)
    }

    private var suggestionsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Recent searches
                if !viewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Searches")
                            .typography(Typography.headline)
                            .foregroundStyle(ColorTheme.primaryText)
                            .accessibleHeader("Recent Searches")
                        ForEach(Array(viewModel.recentSearches.enumerated()), id: \.element) { index, searchTerm in
                            Button(action: {
                                HapticManager.shared.light()
                                viewModel.searchQuery = searchTerm
                                viewModel.search()
                            }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundStyle(ColorTheme.secondaryText)
                                        .accessibleDecorative()
                                    Text(searchTerm)
                                        .typography(Typography.body)
                                        .foregroundStyle(ColorTheme.primaryText)
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                        .foregroundStyle(ColorTheme.secondaryText)
                                        .accessibleDecorative()
                                }
                                .padding(.vertical, 8)
                            }
                            .accessibleButton(
                                label: "Search for \(searchTerm)",
                                hint: "Tap to search for this item again"
                            )
                            .accessibilityIdentifier(AccessibilityIdentifiers.FoodSearch.recentSearch(index))
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Common food categories
                VStack(alignment: .leading, spacing: 8) {
                    Text("Common Categories")
                        .typography(Typography.headline)
                        .foregroundStyle(ColorTheme.primaryText)
                        .accessibleHeader("Common Categories")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(viewModel.foodCategories, id: \.self) { category in
                            Button(action: {
                                HapticManager.shared.selection()
                                viewModel.searchQuery = category
                                viewModel.search()
                            }) {
                                HStack {
                                    Text(category)
                                        .typography(Typography.subheadline)
                                        .foregroundStyle(ColorTheme.primaryText)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(ColorTheme.surface)
                                .clipShape(.rect(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorTheme.border, lineWidth: 1)
                                )
                            }
                            .accessibleButton(
                                label: "Search \(category)",
                                hint: "Tap to search for \(category) foods"
                            )
                            .accessibilityIdentifier(AccessibilityIdentifiers.FoodSearch.category(category))
                        }
                    }
                }
                .padding(.horizontal)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(AccessibilityIdentifiers.FoodSearch.categoriesSection)
                
                // Recent items
                if !viewModel.recentItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Items")
                            .typography(Typography.headline)
                            .foregroundStyle(ColorTheme.primaryText)
                            .accessibleHeader("Recent Items")
                        ForEach(viewModel.recentItems) { item in
                            SimpleRecentFoodRow(
                                item: item,
                                onSelect: {
                                    HapticManager.shared.light()
                                    selectedFoodItem = item
                                },
                                onAdd: {
                                    HapticManager.shared.success()
                                    if let onSelect = onSelect {
                                        onSelect(item)
                                        AccessibilityAnnouncement.announce("\(item.name) added to meal")
                                    } else {
                                        selectedFoodItem = item
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
                        .foregroundStyle(ColorTheme.accent)
                )
                .accessibleDecorative()
            
            // Details - tappable area for showing detail view
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .typography(Typography.headline)
                        .foregroundStyle(ColorTheme.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    if let brand = item.nutritionDetails["brand"] {
                        Text(brand)
                            .typography(Typography.subheadline)
                            .foregroundStyle(ColorTheme.accent)
                    }
                    
                    Text(item.quantity)
                        .typography(Typography.subheadline)
                        .foregroundStyle(ColorTheme.secondaryText)
                    
                    // Much cleaner with convenience initializers
                    item.nutrition.compactPreview()
                    
                    // Allergens preview
                    if !item.allergens.isEmpty {
                        HStack {
                            ForEach(item.allergens.prefix(3), id: \.self) { allergen in
                                Text(allergen)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ColorTheme.error.opacity(0.2))
                                    .foregroundStyle(ColorTheme.error)
                                    .clipShape(.rect(cornerRadius: 4))
                            }
                            if item.allergens.count > 3 {
                                Text("+\(item.allergens.count - 3)")
                                    .font(.caption)
                                    .foregroundStyle(ColorTheme.secondaryText)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibleButton(
                label: buildAccessibilityLabel(),
                hint: "Tap for more details about this food"
            )
            
            // Add button - separate action for direct add
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(ColorTheme.primary)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibleButton(
                label: "Add \(item.name) to meal",
                hint: "Tap to add this food item directly to your meal"
            )
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private func buildAccessibilityLabel() -> String {
        var label = item.name
        if let brand = item.nutritionDetails["brand"] {
            label += ", \(brand)"
        }
        label += ", \(item.quantity)"
        
        if let calories = item.nutrition.calories {
            label += ", \(Int(calories)) calories"
        }
        
        if !item.allergens.isEmpty {
            label += ", Contains allergens: \(item.allergens.joined(separator: ", "))"
        }
        
        return label
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
                        .foregroundStyle(ColorTheme.accent)
                        .font(.system(size: 16))
                )
                .accessibleDecorative()
            
            // Details - tappable area for showing detail view
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .typography(Typography.headline)
                        .foregroundStyle(ColorTheme.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(item.quantity)
                        .typography(Typography.subheadline)
                        .foregroundStyle(ColorTheme.secondaryText)
                    
                    // Nutrition preview - matching screenshot style
                    HStack(spacing: 8) {
                        if let calories = item.nutrition.calories {
                            Text("\(Int(calories)) calories")
                                .typography(Typography.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ColorTheme.accent.opacity(0.2))
                                .foregroundStyle(ColorTheme.accent)
                                .clipShape(.rect(cornerRadius: 4))
                        }
                        
                        if let protein = item.nutrition.protein {
                            Text("\(protein.formatted(.number.precision(.fractionLength(1)))) P")
                                .typography(Typography.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundStyle(.blue)
                                .clipShape(.rect(cornerRadius: 4))
                        }
                        
                        if let carbs = item.nutrition.carbs {
                            Text("\(carbs.formatted(.number.precision(.fractionLength(1)))) C")
                                .typography(Typography.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundStyle(.green)
                                .clipShape(.rect(cornerRadius: 4))
                        }
                        
                        if let fat = item.nutrition.fat {
                            Text("\(fat.formatted(.number.precision(.fractionLength(1)))) F")
                                .typography(Typography.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.2))
                                .foregroundStyle(.red)
                                .clipShape(.rect(cornerRadius: 4))
                        }
                    }
                    
                    // Allergens display
                    if !item.allergens.isEmpty {
                        HStack {
                            ForEach(item.allergens.prefix(2), id: \.self) { allergen in
                                Text(allergen)
                                    .font(.caption)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(ColorTheme.error.opacity(0.2))
                                    .foregroundStyle(ColorTheme.error)
                                    .clipShape(.rect(cornerRadius: 4))
                            }
                            if item.allergens.count > 2 {
                                Text("+\(item.allergens.count - 2)")
                                    .font(.caption)
                                    .foregroundStyle(ColorTheme.secondaryText)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibleButton(
                label: buildAccessibilityLabel(),
                hint: "Tap for more details about this food"
            )
            
            // Add button - separate action for direct add
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(ColorTheme.primary)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibleButton(
                label: "Add \(item.name) to meal",
                hint: "Tap to add this food item directly to your meal"
            )
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
    }
    
    private func buildAccessibilityLabel() -> String {
        var label = "\(item.name), \(item.quantity)"
        
        if let calories = item.nutrition.calories {
            label += ", \(Int(calories)) calories"
        }
        
        if let protein = item.nutrition.protein {
            label += ", \(protein.formatted(.number.precision(.fractionLength(1)))) grams protein"
        }
        
        if let carbs = item.nutrition.carbs {
            label += ", \(carbs.formatted(.number.precision(.fractionLength(1)))) grams carbohydrates"
        }
        
        if let fat = item.nutrition.fat {
            label += ", \(fat.formatted(.number.precision(.fractionLength(1)))) grams fat"
        }
        
        if !item.allergens.isEmpty {
            label += ", Contains allergens: \(item.allergens.joined(separator: ", "))"
        }
        
        return label
    }
}

// Preview
#Preview {
    FoodSearchView()
}
