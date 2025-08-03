import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TodaysActivitySummaryView: View {
    @StateObject private var viewModel = RecentActivityViewModel()
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
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
            
            // Summary counts (always visible)
            HStack(spacing: 16) {
                Label("\(mealsCount) Meals", systemImage: "fork.knife")
                    .foregroundColor(ColorTheme.accent)
                Spacer()
                Label("\(symptomsCount) Symptoms", systemImage: "exclamationmark.triangle")
                    .foregroundColor(ColorTheme.warning)
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
        .onAppear {
            viewModel.loadRecentActivity(for: selectedDate, authService: authService)
        }
        .onChange(of: selectedDate) { _, newDate in
            viewModel.loadRecentActivity(for: newDate, authService: authService)
        }
    }
    
    private func handleEntryTap(_ entry: ActivityEntry) {
        switch entry.type {
        case .meal(let meal):
            navigationCoordinator.navigateTo(.mealDetail(meal))
        case .symptom(let symptom):
            navigationCoordinator.navigateTo(.symptomDetail(symptom))
        }
    }
}

// MARK: - Preview
#Preview {
    TodaysActivitySummaryView(selectedDate: Date())
        .environmentObject(NavigationCoordinator())
        .environmentObject(PreviewAuthService())
        .padding()
}
