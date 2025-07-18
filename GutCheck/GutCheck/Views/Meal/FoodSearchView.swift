//  FoodSearchView.swift
//  GutCheck
//
//  Created on 7/14/25.

import SwiftUI
import Combine

struct FoodSearchView: View {
    @StateObject private var viewModel = FoodSearchViewModel()
    @State private var selectedFoodItem: FoodItem? = nil
    @State private var showDetailSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    TextField("Search foods", text: $viewModel.searchQuery, onCommit: {
                        viewModel.search()
                    })
                    .padding(12)
                    .background(ColorTheme.surface)
                    .cornerRadius(12)
                    .overlay(
                        HStack {
                            Spacer()
                            if viewModel.isSearching {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(.trailing, 8)
                            }
                        }
                    )
                    Button(action: {
                        viewModel.search()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(ColorTheme.accent)
                    }
                }
                .padding()

                // Results or suggestions
                if viewModel.searchResults.isEmpty {
                    if viewModel.searchQuery.isEmpty && viewModel.recentSearches.isEmpty && viewModel.recentItems.isEmpty {
                        VStack {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.yellow)
                            Text("Start typing to search for foods.")
                                .font(.headline)
                                .foregroundColor(ColorTheme.secondaryText)
                                .padding(.top, 8)
                            Spacer()
                        }
                    } else {
                        suggestionsList
                    }
                } else {
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
            }
            .navigationTitle("Search Food")
            .onAppear {
                viewModel.loadRecentItems()
            }
            .sheet(isPresented: $showDetailSheet) {
                if let item = selectedFoodItem {
                    FoodItemDetailView(foodItem: item) { addedItem in
                        viewModel.addToMeal(addedItem)
                        showDetailSheet = false
                    }
                }
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

// ...existing code...

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
                    // ...existing code...
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
