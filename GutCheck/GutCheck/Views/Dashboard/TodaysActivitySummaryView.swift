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
    
    private var medicationsCount: Int {
        viewModel.recentEntries.filter { entry in
            if case .medication = entry.type {
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
            
            // Summary counts (always visible) - Stacked vertically to avoid wrapping
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .foregroundColor(ColorTheme.accent)
                        .frame(width: 20)
                    Text("\(mealsCount) \(mealsCount == 1 ? "Meal" : "Meals")")
                        .foregroundColor(ColorTheme.accent)
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(ColorTheme.warning)
                        .frame(width: 20)
                    Text("\(symptomsCount) \(symptomsCount == 1 ? "Symptom" : "Symptoms")")
                        .foregroundColor(ColorTheme.warning)
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "pills")
                        .foregroundColor(ColorTheme.primary)
                        .frame(width: 20)
                    Text("\(medicationsCount) \(medicationsCount == 1 ? "Medication" : "Medications")")
                        .foregroundColor(ColorTheme.primary)
                    Spacer()
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
        print("🔄 TodaysActivitySummaryView: Entry tapped - type: \(entry.type)")
        
        switch entry.type {
        case .meal(let meal):
            print("🍽️ TodaysActivitySummaryView: Showing meal detail sheet: \(meal.id)")
            router.viewMealDetails(id: meal.id)
        case .symptom(let symptom):
            print("🏥 TodaysActivitySummaryView: Showing symptom detail sheet: \(symptom.id)")
            router.viewSymptomDetails(id: symptom.id)
        case .medication(let medication):
            print("💊 TodaysActivitySummaryView: Medication tapped: \(medication.name)")
            // For now, we'll just show a simple alert since we don't have a medication detail view yet
            // In the future, this could navigate to a medication detail view
            break
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
