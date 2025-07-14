//
//  MealLoggingOptionsView.swift
//  GutCheck
//
//  Created on 7/14/25.
//

import SwiftUI

struct MealLoggingOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack {
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
                        navigationCoordinator.mealNavigationPath.append(MealLoggingDestination.search)
                    }
                    
                    // Barcode scan
                    LoggingOptionCard(
                        icon: "barcode.viewfinder",
                        title: "Barcode",
                        description: "Scan product barcode",
                        color: ColorTheme.secondary
                    ) {
                        navigationCoordinator.mealNavigationPath.append(MealLoggingDestination.barcode)
                    }
                    
                    // LiDAR scan
                    LoggingOptionCard(
                        icon: "camera.metering.matrix",
                        title: "LiDAR Scan",
                        description: "Estimate portions with camera",
                        color: ColorTheme.accent
                    ) {
                        navigationCoordinator.mealNavigationPath.append(MealLoggingDestination.lidar)
                    }
                    
                    // Recent items
                    LoggingOptionCard(
                        icon: "clock",
                        title: "Recent",
                        description: "Previously logged foods",
                        color: ColorTheme.primary.opacity(0.8)
                    ) {
                        navigationCoordinator.mealNavigationPath.append(MealLoggingDestination.recent)
                    }
                    
                    // Favorites
                    LoggingOptionCard(
                        icon: "star.fill",
                        title: "Favorites",
                        description: "Your favorite meals",
                        color: ColorTheme.secondary.opacity(0.8)
                    ) {
                        navigationCoordinator.mealNavigationPath.append(MealLoggingDestination.favorites)
                    }
                    
                    // Templates
                    LoggingOptionCard(
                        icon: "square.on.square",
                        title: "Templates",
                        description: "Saved meal templates",
                        color: ColorTheme.accent.opacity(0.8)
                    ) {
                        navigationCoordinator.mealNavigationPath.append(MealLoggingDestination.templates)
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

// Placeholder views
struct FoodSearchView: View {
    var body: some View {
        Text("Food Search View")
    }
}

struct BarcodeScannerView: View {
    var body: some View {
        Text("Barcode Scanner View")
    }
}

struct LiDARScannerView: View {
    var body: some View {
        Text("LiDAR Scanner View")
    }
}

struct RecentItemsView: View {
    var body: some View {
        Text("Recent Items View")
    }
}

struct FavoriteMealsView: View {
    var body: some View {
        Text("Favorite Meals View")
    }
}

struct MealTemplatesView: View {
    var body: some View {
        Text("Meal Templates View")
    }
}

// Preview
#Preview {
    MealLoggingOptionsView()
        .environmentObject(NavigationCoordinator())
}
