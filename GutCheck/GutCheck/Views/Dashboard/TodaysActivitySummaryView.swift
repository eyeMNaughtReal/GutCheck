import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TodaysActivitySummaryView: View {
    @ObservedObject var viewModel: RecentActivityViewModel
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authService: AuthService
    let selectedDate: Date
    @State private var isExpanded = false
    
    // Computed counts from loaded data
    private var mealsCount: Int {
        viewModel.recentEntries.filter { entry in
            if case .meal = entry.type {
                return true
            }
            return false
        }.count
    }
    
    private var symptomsCount: Int {
        viewModel.recentEntries.filter { entry in
            if case .symptom = entry.type {
                return true
            }
            return false
        }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title
            HStack {
                Text("Today's Summary")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                if !viewModel.recentEntries.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "See Less" : "See All")
                                .font(.caption)
                                .foregroundColor(ColorTheme.primary)
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundColor(ColorTheme.primary)
                        }
                    }
                }
            }
            
            // Summary counts (always visible) - Fixed alignment
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "fork.knife")
                        .foregroundColor(ColorTheme.accent)
                    Text("\(mealsCount) Meals")
                        .foregroundColor(ColorTheme.accent)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(ColorTheme.warning)
                    Text("\(symptomsCount) Symptoms")
                        .foregroundColor(ColorTheme.warning)
                }
            }
            .font(.subheadline)
            
            // Expanded activity list
            if isExpanded {
                Divider()
                    .padding(.vertical, 4)
                
                if viewModel.isLoading {
                    LoadingStateView()
                } else if viewModel.recentEntries.isEmpty {
                    RecentActivityEmptyStateView()
                } else {
                    VStack(spacing: 8) {
                        ForEach(viewModel.recentEntries) { entry in
                            ActivityRowView(entry: entry) {
                                handleEntryTap(entry)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
        .refreshable {
            print("🔄 TodaysActivitySummaryView: Manual refresh triggered")
            viewModel.loadRecentActivity(for: selectedDate, authService: authService)
        }
    }
    
    private func handleEntryTap(_ entry: ActivityEntry) {
        switch entry.type {
        case .meal(let meal):
            router.navigateTo(.mealDetail(meal.id))
        case .symptom(let symptom):
            router.navigateTo(.symptomDetail(symptom.id))
        }
    }
}

// MARK: - Preview
#Preview {
    TodaysActivitySummaryView(
        viewModel: RecentActivityViewModel(),
        selectedDate: Date()
    )
    .environmentObject(AppRouter.shared)
    .environmentObject(PreviewAuthService())
    .padding()
}
