//
//  MealLoggingOptionsView.swift
//  GutCheck
//
//  Fixed navigation to properly connect to existing views
//

import SwiftUI

struct MealLoggingOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter
    @State private var showingSmartScannerView = false
    @State private var showingSearchView = false
    @State private var showingBarcodeScannerView = false
    @State private var showingLiDARScannerView = false
    @State private var showingRecentItemsView = false
    @State private var showingTemplatesView = false
    @State private var showingAddWaterView = false
    
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
                    // Water
                    DropdownOptionRow(
                        icon: "drop.fill",
                        title: "Water",
                        color: Color.blue
                    ) {
                        showingAddWaterView = true
                    }
                    
                    // Recent items
                    DropdownOptionRow(
                        icon: "clock",
                        title: "Recent",
                        color: ColorTheme.primary.opacity(0.8)
                    ) {
                        showingRecentItemsView = true
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
        .sheet(isPresented: $showingSmartScannerView) {
            SmartFoodScannerView()
                .environmentObject(router)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingBarcodeScannerView) {
            BarcodeScannerView()
                .environmentObject(router)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingLiDARScannerView) {
            LiDARScannerView()
                .environmentObject(router)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingRecentItemsView) {
            RecentItemsView()
                .environmentObject(router)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTemplatesView) {
            MealTemplatesView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAddWaterView) {
            AddWaterView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
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
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = RecentItemsViewModel()
    @State private var selectedFoodItem: FoodItem?
    
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
                            UnifiedFoodItemRow(
                                item: item,
                                style: .recentItem,
                                actions: FoodItemActions(
                                    onTap: {
                                        // Show details view for the item
                                        selectedFoodItem = item
                                    },
                                    onAdd: {
                                        // Add item to meal and navigate to meal builder
                                        viewModel.addToMeal(item)
                                        dismiss()
                                    }
                                )
                            )
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
            .sheet(item: $selectedFoodItem) { foodItem in
                UnifiedFoodDetailView(
                    foodItem: foodItem,
                    style: .full,
                    onUpdate: { updatedItem in
                        // For recent items, we can just add the updated item to the meal
                        viewModel.addToMeal(updatedItem)
                        selectedFoodItem = nil
                        dismiss()
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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

struct MealTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingMealBuilder = false
    @State private var templates: [MealTemplate] = []
    @State private var isLoading = true
    @State private var error: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Build Custom Meal - Prominent option at the top
                    Button(action: {
                        showingMealBuilder = true
                    }) {
                        HStack {
                            Image(systemName: "plus.rectangle.on.rectangle")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Build Custom Meal")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Create a meal from scratch")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        .background(ColorTheme.primary)
                        .cornerRadius(12)
                        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    
                    // Templates section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Saved Templates")
                                .font(.headline)
                                .foregroundColor(ColorTheme.primaryText)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView("Loading templates...")
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if let error = error {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(ColorTheme.error)
                                
                                Text("Error Loading Templates")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.primaryText)
                                
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.secondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(ColorTheme.surface)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else if templates.isEmpty {
                            // Placeholder for when no templates exist
                            VStack(spacing: 16) {
                                Image(systemName: "square.on.square")
                                    .font(.system(size: 48))
                                    .foregroundColor(ColorTheme.secondaryText.opacity(0.5))
                                
                                Text("No Meal Templates")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.primaryText)
                                
                                Text("Save frequently used meals as templates for quick access")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.secondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(ColorTheme.surface)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            // Display actual templates
                            LazyVStack(spacing: 12) {
                                ForEach(templates) { template in
                                    TemplateCard(template: template)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
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
        .sheet(isPresented: $showingMealBuilder) {
            MealBuilderView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task {
            await loadTemplates()
        }
    }
    
    private func loadTemplates() async {
        isLoading = true
        error = nil
        
        do {
            guard let userId = AuthService().currentUser?.id else {
                error = "Please sign in to view your templates"
                isLoading = false
                return
            }
            
            templates = try await MealTemplateRepository.shared.fetchTemplates(for: userId)
            isLoading = false
        } catch {
            self.error = "Failed to load templates: \(error.localizedDescription)"
            isLoading = false
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
        
        // TODO: Load real recent items from user's history
        // For now, show empty state until real data is implemented
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.recentItems = []
            self.isLoading = false
        }
    }
    
    func addToMeal(_ foodItem: FoodItem) {
        // Add to unified meal builder service
        MealBuilderService.shared.addFoodItem(foodItem)
    }
}

// MARK: - Template Card View

struct TemplateCard: View {
    let template: MealTemplate
    @State private var showingMealBuilder = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Template header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    HStack(spacing: 8) {
                        Text(template.type.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ColorTheme.primary.opacity(0.1))
                            .foregroundColor(ColorTheme.primary)
                            .cornerRadius(8)
                        
                        if template.usageCount > 0 {
                            Text("Used \(template.usageCount) times")
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                Menu {
                    Button("Use Template") {
                        showingMealBuilder = true
                    }
                    
                    Button("Delete Template", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(ColorTheme.secondaryText)
                }
            }
            
            // Food items preview
            VStack(alignment: .leading, spacing: 6) {
                ForEach(template.foodItems.prefix(3)) { item in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 4))
                            .foregroundColor(ColorTheme.secondaryText)
                        
                        Text(item.name)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Spacer()
                    }
                }
                
                if template.foodItems.count > 3 {
                    Text("+ \(template.foodItems.count - 3) more items")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                }
            }
            
            // Notes if available
            if let notes = template.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorTheme.border.opacity(0.3), lineWidth: 1)
        )
        .sheet(isPresented: $showingMealBuilder) {
            MealBuilderView()
                .onAppear {
                    // Load the template into the meal builder
                    MealBuilderService.shared.loadTemplate(template)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Delete Template", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteTemplate()
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(template.name)'? This action cannot be undone.")
        }
    }
    
    private func deleteTemplate() async {
        do {
            try await MealTemplateRepository.shared.delete(id: template.id)
            // Refresh the templates list (this would need to be handled by the parent view)
        } catch {
            print("Error deleting template: \(error)")
        }
    }
}

// Preview
#Preview {
    MealLoggingOptionsView()
        .environmentObject(AppRouter.shared)
}

// MARK: - Recent Food Item Row Component

