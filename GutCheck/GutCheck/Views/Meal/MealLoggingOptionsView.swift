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
    
    var body: some View {
        NavigationStack(path: navigationCoordinator.currentNavigationPath) {
            VStack(spacing: 24) {
                // Header
                Text("How would you like to log your meal?")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                    .multilineTextAlignment(.center)
                
                // Grid of options
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    // Manual search
                    LoggingOptionCard(
                        icon: "magnifyingglass",
                        title: "Search",
                        description: "Search for food items",
                        color: ColorTheme.primary
                    ) {
                        dismiss() // Close the sheet first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigationCoordinator.currentNavigationPath.wrappedValue.append(MealLoggingDestination.search)
                        }
                    }
                    
                    // Barcode scan
                    LoggingOptionCard(
                        icon: "barcode.viewfinder",
                        title: "Barcode",
                        description: "Scan product barcode",
                        color: ColorTheme.secondary
                    ) {
                        dismiss() // Close the sheet first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigationCoordinator.currentNavigationPath.wrappedValue.append(MealLoggingDestination.barcode)
                        }
                    }
                    
                    // LiDAR scan
                    LoggingOptionCard(
                        icon: "camera.metering.matrix",
                        title: "LiDAR Scan",
                        description: "Estimate portions with camera",
                        color: ColorTheme.accent
                    ) {
                        dismiss() // Close the sheet first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigationCoordinator.currentNavigationPath.wrappedValue.append(MealLoggingDestination.lidar)
                        }
                    }
                    
                    // Recent items
                    LoggingOptionCard(
                        icon: "clock",
                        title: "Recent",
                        description: "Previously logged foods",
                        color: ColorTheme.primary.opacity(0.8)
                    ) {
                        dismiss() // Close the sheet first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigationCoordinator.currentNavigationPath.wrappedValue.append(MealLoggingDestination.recent)
                        }
                    }
                    
                    // Favorites
                    LoggingOptionCard(
                        icon: "star.fill",
                        title: "Favorites",
                        description: "Your favorite meals",
                        color: ColorTheme.secondary.opacity(0.8)
                    ) {
                        dismiss() // Close the sheet first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigationCoordinator.currentNavigationPath.wrappedValue.append(MealLoggingDestination.favorites)
                        }
                    }
                    
                    // Templates
                    LoggingOptionCard(
                        icon: "square.on.square",
                        title: "Templates",
                        description: "Saved meal templates",
                        color: ColorTheme.accent.opacity(0.8)
                    ) {
                        dismiss() // Close the sheet first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigationCoordinator.currentNavigationPath.wrappedValue.append(MealLoggingDestination.templates)
                        }
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
            .navigationDestination(for: MealLoggingDestination.self) { destination in
                switch destination {
                case .search:
                    FoodSearchView()
                case .barcode:
                    BarcodeScannerView()
                case .lidar:
                    LiDARScannerView()
                case .recent:
                    RecentItemsView()
                case .favorites:
                    FavoriteMealsView()
                case .templates:
                    MealTemplatesView()
                case .mealBuilder:
                    MealBuilderView()
                }
            }
        }
    }
}

struct LoggingOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color)
                    )
                
                // Title
                Text(title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                // Description
                Text(description)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 32)
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Navigation destinations for meal logging
enum MealLoggingDestination: Hashable {
    case search
    case barcode
    case lidar
    case recent
    case favorites
    case templates
    case mealBuilder
}

// MARK: - Missing Views (Placeholder implementations)

struct RecentItemsView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @StateObject private var viewModel = RecentItemsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.recentItems.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.recentItems) { item in
                        FoodItemResultRow(item: item) {
                            // Navigate to food detail or add to meal
                            navigationCoordinator.currentNavigationPath.wrappedValue.append(MealLoggingDestination.mealBuilder)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Recent Items")
        .onAppear {
            viewModel.loadRecentItems()
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
}

struct FavoriteMealsView: View {
    var body: some View {
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
    }
}

struct MealTemplatesView: View {
    var body: some View {
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
}

// Preview
#Preview {
    MealLoggingOptionsView()
        .environmentObject(NavigationCoordinator())
}
