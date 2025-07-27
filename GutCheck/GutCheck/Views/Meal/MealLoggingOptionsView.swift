//
//  MealLoggingOptionsView.swift
//  GutCheck
//
//  Fixed navigation to properly connect to existing views
//

import SwiftUI

struct MealLoggingOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @State private var showingSearchView = false
    @State private var showingBarcodeScannerView = false
    @State private var showingLiDARScannerView = false
    @State private var showingRecentItemsView = false
    @State private var showingFavoritesView = false
    @State private var showingTemplatesView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                Text("How would you like to log your meal?")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                    .multilineTextAlignment(.center)
                
                // Grid of options
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 16),
                        GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 16)
                    ],
                    alignment: .center,
                    spacing: 16
                ) {
                    // Manual search
                    LoggingOptionCard(
                        icon: "magnifyingglass",
                        title: "Search",
                        description: "Search for food items",
                        color: ColorTheme.primary
                    ) {
                        showingSearchView = true
                    }
                    
                    // Barcode scan
                    LoggingOptionCard(
                        icon: "barcode.viewfinder",
                        title: "Barcode",
                        description: "Scan product barcode",
                        color: ColorTheme.secondary
                    ) {
                        showingBarcodeScannerView = true
                    }
                    
                    // LiDAR scan
                    LoggingOptionCard(
                        icon: "camera.metering.matrix",
                        title: "LiDAR Scan",
                        description: "Estimate portions with camera",
                        color: ColorTheme.accent
                    ) {
                        showingLiDARScannerView = true
                    }
                    
                    // Recent items
                    LoggingOptionCard(
                        icon: "clock",
                        title: "Recent",
                        description: "Previously logged foods",
                        color: ColorTheme.primary.opacity(0.8)
                    ) {
                        showingRecentItemsView = true
                    }
                    
                    // Favorites
                    LoggingOptionCard(
                        icon: "star.fill",
                        title: "Favorites",
                        description: "Your favorite meals",
                        color: ColorTheme.secondary.opacity(0.8)
                    ) {
                        showingFavoritesView = true
                    }
                    
                    // Templates
                    LoggingOptionCard(
                        icon: "square.on.square",
                        title: "Templates",
                        description: "Saved meal templates",
                        color: ColorTheme.accent.opacity(0.8)
                    ) {
                        showingTemplatesView = true
                    }
                }
                
                Spacer()
                
                // Cancel button
                CustomButton(
                    title: "Cancel",
                    action: {
                        dismiss()
                    },
                    style: .outline
                )
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Present each view as a sheet instead of using navigation
        .sheet(isPresented: $showingSearchView) {
            FoodSearchView()
                .environmentObject(navigationCoordinator)
        }
        .sheet(isPresented: $showingBarcodeScannerView) {
            BarcodeScannerView()
                .environmentObject(navigationCoordinator)
        }
        .sheet(isPresented: $showingLiDARScannerView) {
            LiDARScannerView()
                .environmentObject(navigationCoordinator)
        }
        .sheet(isPresented: $showingRecentItemsView) {
            RecentItemsView()
                .environmentObject(navigationCoordinator)
        }
        .sheet(isPresented: $showingFavoritesView) {
            FavoriteMealsView()
        }
        .sheet(isPresented: $showingTemplatesView) {
            MealTemplatesView()
        }
    }
}

struct LoggingOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    // Fixed dimensions for consistent sizing
    private let cardWidth: CGFloat = UIScreen.main.bounds.width / 2 - 24 // Account for padding
    private let cardHeight: CGFloat = 180
    private let iconSize: CGFloat = 32
    private let iconContainerSize: CGFloat = 60
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundColor(.white)
                    .frame(width: iconContainerSize, height: iconContainerSize)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color)
                    )
                
                // Title
                Text(title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Description
                Text(description)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 32)
            }
            .padding()
            .frame(width: cardWidth, height: cardHeight)
            .background(ColorTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Missing Views (Updated implementations)

struct RecentItemsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @StateObject private var viewModel = RecentItemsViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.recentItems.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(viewModel.recentItems) { item in
                            FoodItemResultRow(item: item) {
                                // Add item to meal and navigate to meal builder
                                viewModel.addToMeal(item)
                                dismiss()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Recent Items")
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
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundColor(ColorTheme.secondaryText.opacity(0.5))
            
            Text("No Recent Items")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            Text("Items you've previously logged will appear here")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading recent items...")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

struct FavoriteMealsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "star")
                        .font(.system(size: 48))
                        .foregroundColor(ColorTheme.secondaryText.opacity(0.5))
                    
                    Text("No Favorite Meals")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Mark meals as favorites to quickly log them again")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 200)
            }
            .navigationTitle("Favorite Meals")
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

struct MealTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "square.on.square")
                        .font(.system(size: 48))
                        .foregroundColor(ColorTheme.secondaryText.opacity(0.5))
                    
                    Text("No Meal Templates")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Create meal templates for recurring meals")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 200)
            }
            .navigationTitle("Meal Templates")
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

// MARK: - Recent Items ViewModel

@MainActor
class RecentItemsViewModel: ObservableObject {
    @Published var recentItems: [FoodItem] = []
    @Published var isLoading = false
    
    func loadRecentItems() {
        isLoading = true
        
        // For now, we'll use mock data
        // In a real app, this would load from UserDefaults or Firebase
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.recentItems = [
                FoodItem(
                    name: "Oatmeal with Banana",
                    quantity: "1 cup",
                    estimatedWeightInGrams: 240,
                    nutrition: NutritionInfo(calories: 200, protein: 6, carbs: 35, fat: 4)
                ),
                FoodItem(
                    name: "Grilled Chicken Breast",
                    quantity: "6 oz",
                    estimatedWeightInGrams: 170,
                    nutrition: NutritionInfo(calories: 280, protein: 54, carbs: 0, fat: 6)
                ),
                FoodItem(
                    name: "Greek Yogurt",
                    quantity: "1 cup",
                    estimatedWeightInGrams: 245,
                    nutrition: NutritionInfo(calories: 150, protein: 20, carbs: 9, fat: 4)
                )
            ]
            self.isLoading = false
        }
    }
    
    func addToMeal(_ foodItem: FoodItem) {
        // Add to meal builder singleton
        MealBuilder.shared.addFoodItem(foodItem)
    }
}

// Preview
#Preview {
    MealLoggingOptionsView()
        .environmentObject(NavigationCoordinator())
}