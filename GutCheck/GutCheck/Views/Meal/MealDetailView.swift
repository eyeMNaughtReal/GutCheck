import SwiftUI
import FirebaseFirestore

struct MealDetailView: View {
    @StateObject private var viewModel: MealDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var refreshManager: RefreshManager
    
    // New initializer that takes a meal ID
    init(mealId: String) {
        self._viewModel = StateObject(wrappedValue: MealDetailViewModel(mealId: mealId))
    }
    
    // Keep the original initializer for backward compatibility
    init(meal: Meal) {
        self._viewModel = StateObject(wrappedValue: MealDetailViewModel(meal: meal))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    ProgressView("Loading meal details...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text(viewModel.isEditing ? "Edit Meal" : "Meal Details")
                                .font(.title2.bold())
                                .foregroundColor(ColorTheme.primaryText)
                            
                            if viewModel.isEditing {
                                TextField("Meal name", text: $viewModel.meal.name)
                                    .font(.headline)
                                    .padding()
                                    .background(ColorTheme.surface)
                                    .cornerRadius(12)
                                    .multilineTextAlignment(.center)
                            } else {
                                Text(viewModel.meal.name)
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.primaryText)
                            }
                            
                            HStack {
                                mealBadge(type: viewModel.meal.type)
                                
                                Text(viewModel.formattedDateTime)
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.secondaryText)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Rest of the existing view...
                        // (Keep all the existing content)
                    }
                    .padding(.bottom, 80)
                }
                .navigationTitle("Meal Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            if viewModel.isEditing {
                                Button("Save") {
                                    Task {
                                        if await viewModel.saveMeal() {
                                            refreshManager.triggerRefresh()
                                        }
                                    }
                                }
                                .disabled(viewModel.isSaving)
                            } else {
                                Menu {
                                    Button {
                                        viewModel.isEditing = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        viewModel.showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        if viewModel.isEditing {
                            Button("Cancel") {
                                viewModel.isEditing = false
                            }
                        }
                    }
                }
                .alert("Error", isPresented: $viewModel.showingErrorAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(viewModel.errorMessage)
                }
                .confirmationDialog(
                    "Are you sure you want to delete this meal?",
                    isPresented: $viewModel.showingDeleteConfirmation
                ) {
                    Button("Delete", role: .destructive) {
                        Task {
                            if await viewModel.deleteMeal() {
                                refreshManager.triggerRefresh()
                                router.navigateBack()
                            }
                        }
                    }
                }
                .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
                    if shouldDismiss {
                        router.navigateBack()
                    }
                }
            }
        }
        .onAppear {
            if viewModel.mealId != nil {
                Task {
                    await viewModel.loadMeal()
                }
            }
        }
    }
    
    private func mealBadge(type: MealType) -> some View {
        Text(type.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(mealTypeColor(type).opacity(0.2))
            .foregroundColor(mealTypeColor(type))
            .cornerRadius(12)
    }
    
    private func mealTypeColor(_ type: MealType) -> Color {
        switch type {
        case .breakfast:
            return .orange
        case .lunch:
            return .green
        case .dinner:
            return .blue
        case .snack:
            return .purple
        case .drink:
            return .cyan
        }
    }
}

#Preview {
    MealDetailView(meal: Meal.sampleMeal)
        .environmentObject(AppRouter.shared)
        .environmentObject(RefreshManager.shared)
}