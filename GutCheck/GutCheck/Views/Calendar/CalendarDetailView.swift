import SwiftUI

struct CalendarDetailView: View {
    let date: Date
    @StateObject private var viewModel = CalendarDetailViewModel()
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            content
                .task {
                    await viewModel.loadData(for: date, authService: authService)
                }
        }
    }
    
    var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Meals Section
                if !viewModel.meals.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meals")
                            .font(.title2)
                            .bold()
                        
                        ForEach(viewModel.meals) { meal in
                            MealSummaryCard(meal: meal)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Symptoms Section
                if !viewModel.symptoms.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Symptoms")
                            .font(.title2)
                            .bold()
                        
                        ForEach(viewModel.symptoms) { symptom in
                            Button(action: {
                                navigationCoordinator.navigateTo(.symptomDetail(symptom))
                            }) {
                                SymptomSummaryCard(symptom: symptom)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Analysis Section
                if viewModel.hasAnalysis {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Analysis")
                            .font(.title2)
                            .bold()
                        
                        if let triggers = viewModel.potentialTriggers {
                            TriggerSummaryCard(triggers: triggers)
                        }
                        
                        if let patterns = viewModel.patterns {
                            PatternSummaryCard(patterns: patterns)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // No Data View
                if viewModel.isEmpty {
                    EmptyStateView(
                        message: "Log meals and symptoms to see them here",
                        imageName: "calendar.badge.plus"
                    )
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(date.formatted(.dateTime.month().day().weekday()))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData(for: date, authService: authService)
        }
    }
}

#Preview {
    NavigationView {
        CalendarDetailView(date: Date())
    }
    .environmentObject(AuthService())
    .environmentObject(NavigationCoordinator())
}
