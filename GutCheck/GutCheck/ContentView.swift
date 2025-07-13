//
//  ContentView.swift
//  GutCheck
//
//  Updated ContentView with centralized navigation and consistent patterns
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
                    case .home:
                        DashboardView()
                    case .meal:
                        MealCalendarView()
                    case .symptoms:
                        SymptomCalendarView()
                    case .insights:
                        InsightsView()
                    case .plus:
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
        case .logMeal:
            LogMealView()
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
            navigationCoordinator.navigateTo(.logMeal)
        case .logSymptom:
            navigationCoordinator.navigateTo(.logSymptom)
        }
    }
}

// MARK: - Tab Bar Actions
enum TabBarAction {
    case logMeal
    case logSymptom
}

// MARK: - Placeholder Views (to be implemented)
struct MealCalendarView: View {
    var body: some View {
        Text("Meal Calendar")
            .navigationTitle("Meals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileAvatarButton {
                        // Handle profile action
                    }
                }
            }
    }
}

struct SymptomCalendarView: View {
    var body: some View {
        Text("Symptom Calendar")
            .navigationTitle("Symptoms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileAvatarButton {
                        // Handle profile action
                    }
                }
            }
    }
}

struct MealDetailView: View {
    let meal: Meal
    
    var body: some View {
        VStack {
            Text("Meal Detail: \(meal.name)")
        }
        .navigationTitle(meal.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct SymptomDetailView: View {
    let symptom: Symptom
    
    var body: some View {
        VStack {
            Text("Symptom Detail")
        }
        .navigationTitle("Symptom Details")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
