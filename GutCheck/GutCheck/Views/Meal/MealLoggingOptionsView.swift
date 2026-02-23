//
//  MealLoggingOptionsView.swift
//  GutCheck
//
//  Simplified to focus on food search only
//

import SwiftUI

struct MealLoggingOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter
    @State private var showingSearchView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Icon
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ColorTheme.accent)
                
                // Title
                Text("Add Food")
                    .font(.title.bold())
                    .foregroundColor(ColorTheme.primaryText)
                
                // Description
                Text("Search our database to find and log your food")
                    .font(.body)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        showingSearchView = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search Foods")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.surface)
                            .foregroundColor(ColorTheme.primaryText)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(ColorTheme.background)
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingSearchView) {
            NavigationStack {
                FoodSearchView { foodItem in
                    // Add food item to meal builder
                    MealBuilderService.shared.addFoodItem(foodItem)
                    
                    // Close the search sheet to return to MealBuilderView
                    showingSearchView = false
                }
                .environmentObject(router)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// Preview
#Preview {
    MealLoggingOptionsView()
        .environmentObject(AppRouter.shared)
}

