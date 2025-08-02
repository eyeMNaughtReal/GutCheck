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
    @State private var showingSmartScannerView = false
    @State private var showingSearchView = false
    @State private var showingBarcodeScannerView = false
    @State private var showingLiDARScannerView = false
    @State private var showingRecentItemsView = false
    @State private var showingFavoritesView = false
    @State private var showingTemplatesView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header

                // Primary options grid (large cards)
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 8),
                        GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 8)
                    ],
                    alignment: .center,
                    spacing: 8
                ) {
                    // Smart Scanner (Primary recommendation)
                    LoggingOptionCard(
                        icon: "viewfinder.circle.fill",
                        title: "Smart Scan",
                        color: ColorTheme.accent
                    ) {
                        showingSmartScannerView = true
                    }
                    
                    // Manual search (Fallback)
                    LoggingOptionCard(
                        icon: "magnifyingglass",
                        title: "Search",
                        color: ColorTheme.primary
                    ) {
                        showingSearchView = true
                    }
                    
                    // LiDAR only (For foods without barcodes)
                    LoggingOptionCard(
                        icon: "camera.metering.matrix",
                        title: "LiDAR",
                        color: ColorTheme.accent.opacity(0.8)
                    ) {
                        showingLiDARScannerView = true
                    }
                    
                    // Barcode only (For users who prefer traditional method)
                    LoggingOptionCard(
                        icon: "barcode.viewfinder",
                        title: "Barcode",
                        color: ColorTheme.secondary
                    ) {
                        showingBarcodeScannerView = true
                    }
                }
                
                // Secondary options (dropdown-style list)
                VStack(spacing: 4) {
                    // Water quick-log
                    DropdownOptionRow(
                        icon: "drop.fill",
                        title: "Water",
                        color: Color.blue
                    ) {
                        logWater()
                    }
                    
                    // Recent items
                    DropdownOptionRow(
                        icon: "clock",
                        title: "Recent",
                        color: ColorTheme.primary.opacity(0.8)
                    ) {
                        showingRecentItemsView = true
                    }
                    
                    // Favorites
                    DropdownOptionRow(
                        icon: "star.fill",
                        title: "Favorites",
                        color: ColorTheme.secondary.opacity(0.8)
                    ) {
                        showingFavoritesView = true
                    }
                    
                    // Templates
                    DropdownOptionRow(
                        icon: "square.on.square",
                        title: "Templates",
                        color: ColorTheme.accent.opacity(0.8)
                    ) {
                        showingTemplatesView = true
                    }
                }
                
                Spacer()
                
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(ColorTheme.background)
            .navigationBarTitleDisplayMode(.inline)
        }
        // Present each view as a sheet instead of using navigation
        .sheet(isPresented: $showingSearchView) {
            FoodSearchView()
                .environmentObject(navigationCoordinator)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSmartScannerView) {
            SmartFoodScannerView()
                .environmentObject(navigationCoordinator)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingBarcodeScannerView) {
            BarcodeScannerView()
                .environmentObject(navigationCoordinator)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingLiDARScannerView) {
            LiDARScannerView()
                .environmentObject(navigationCoordinator)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingRecentItemsView) {
            RecentItemsView()
                .environmentObject(navigationCoordinator)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingFavoritesView) {
            FavoriteMealsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTemplatesView) {
            MealTemplatesView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Helper Functions
    
    private func logWater() {
        // Quick log 8 oz of water
        let waterItem = FoodItem(
            name: "Water",
            quantity: "8 fl oz",
            estimatedWeightInGrams: 240,
            nutrition: NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0)
        )
        
        // Add to meal builder service
        MealBuilderService.shared.addFoodItem(waterItem)
        
        // Show success feedback
        // TODO: Add haptic feedback or toast notification
        
        dismiss()
    }
}

struct DropdownOptionRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 20, height: 20)
                
                // Title
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                // Chevron (optional, for dropdown appearance)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: ColorTheme.shadowColor.opacity(0.2), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LoggingOptionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    init(icon: String, title: String, color: Color, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }
    
    // Card dimensions - increased back to 100px height
    private let cardHeight: CGFloat = 100 // Back to previous size
    private let iconSize: CGFloat = 20 // Increased back up
    private let iconContainerSize: CGFloat = 40 // Increased proportionally
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) { // Increased spacing back up
                // Icon
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundColor(.white)
                    .frame(width: iconContainerSize, height: iconContainerSize)
                    .background(
                        RoundedRectangle(cornerRadius: 10) // Increased back to 10
                            .fill(color)
                    )
                
                // Title
                Text(title)
                    .font(.subheadline) // Changed back from .caption
                    .foregroundColor(ColorTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(10) // Increased back to 10
            .frame(height: cardHeight)
            .frame(maxWidth: .infinity) // Use flexible width instead of fixed
            .background(Color.white) // Changed to white for better contrast
            .cornerRadius(10) // Increased back to 10
            .shadow(color: ColorTheme.shadowColor.opacity(0.3), radius: 2, x: 0, y: 1) // Slightly increased shadow
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
        // Add to unified meal builder service
        MealBuilderService.shared.addFoodItem(foodItem)
    }
}

// Preview
#Preview {
    MealLoggingOptionsView()
        .environmentObject(NavigationCoordinator())
}