// MARK: - Preview
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthService())
            .environmentObject(NavigationCoordinator())
    }
}
#endif
//
//  ContentView.swift
//  GutCheck
//
//  Updated ContentView with meal logging and viewing functionality
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack(path: navigationCoordinator.currentNavigationPath) {
                Group {
                    switch navigationCoordinator.selectedTab {
                    case .dashboard:
                        DashboardView()
                    case .meals, .symptoms:
                        CalendarView(selectedTab: navigationCoordinator.selectedTab)
                    case .insights:
                        InsightsView()
                    case .add:
                        DashboardView() // Plus button shows actions, doesn't navigate
                    }
                }
                .navigationDestination(for: NavigationCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
                }
                .sheet(isPresented: $navigationCoordinator.isShowingProfile) {
                    if let currentUser = authService.currentUser {
                        UserProfileView(user: currentUser)
                    }
                }
                .sheet(isPresented: $navigationCoordinator.isShowingSettings) {
                    SettingsView()
                }
            }

            CustomTabBar(selectedTab: $navigationCoordinator.selectedTab) { action in
                handleTabBarAction(action)
            }
        }
        .environmentObject(navigationCoordinator)
        .background(ColorTheme.background.ignoresSafeArea())
        .sheet(isPresented: $navigationCoordinator.isShowingMealLoggingOptions) {
            MealLoggingOptionsView()
                .environmentObject(navigationCoordinator)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $navigationCoordinator.isShowingSymptomLoggingSheet) {
            LogSymptomView()
                .environmentObject(authService)
                .environmentObject(navigationCoordinator)
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationCoordinator.Destination) -> some View {
        switch destination {
        case .profile(let user):
            UserProfileView(user: user)
        case .settings:
            SettingsView()
        case .mealDetail(let meal):
            MealDetailView(meal: meal)
        case .symptomDetail(let symptom):
            SymptomDetailView(symptom: symptom)
        case .foodDetail(let foodItem):
            UnifiedFoodDetailView(foodItem: foodItem)  // Full comprehensive view with all health details
        case .logMeal:
            // This now goes to options view as a sheet instead
            EmptyView()
        case .logSymptom:
            LogSymptomView()
        case .calendar(let date):
            CalendarView(selectedDate: date)
        case .insights:
            InsightsView()
        case .userReminders:
            UserRemindersView()
        }
    }
    
    private func handleTabBarAction(_ action: TabBarAction) {
        switch action {
        case .logMeal:
            // Show meal logging options as a sheet
            navigationCoordinator.isShowingMealLoggingOptions = true
        case .logSymptom:
            navigationCoordinator.isShowingSymptomLoggingSheet = true
        }
    }
}

// MARK: - Tab Bar Actions
enum TabBarAction {
    case logMeal
    case logSymptom
}


