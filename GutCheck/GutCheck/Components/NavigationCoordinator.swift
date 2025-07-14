//
//  NavigationCoordinator.swift
//  GutCheck
//
//  Centralized navigation management to replace mixed NavigationView/NavigationStack usage
//

import SwiftUI

@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: CustomTabBar.Tab = .home
    @Published var navigationPath = NavigationPath()
    @Published var isShowingProfile = false
    @Published var isShowingSettings = false
    
    // Additional property for meal logging options
    @Published var isShowingMealLoggingOptions = false
    
    // Tab-specific navigation paths
    @Published var homeNavigationPath = NavigationPath()
    @Published var mealNavigationPath = NavigationPath()
    @Published var symptomsNavigationPath = NavigationPath()
    @Published var insightsNavigationPath = NavigationPath()
    
    // Current navigation path based on selected tab
    var currentNavigationPath: Binding<NavigationPath> {
        switch selectedTab {
        case .home:
            return Binding(
                get: { self.homeNavigationPath },
                set: { self.homeNavigationPath = $0 }
            )
        case .meal:
            return Binding(
                get: { self.mealNavigationPath },
                set: { self.mealNavigationPath = $0 }
            )
        case .symptoms:
            return Binding(
                get: { self.symptomsNavigationPath },
                set: { self.symptomsNavigationPath = $0 }
            )
        case .insights:
            return Binding(
                get: { self.insightsNavigationPath },
                set: { self.insightsNavigationPath = $0 }
            )
        case .plus:
            return Binding(
                get: { self.homeNavigationPath },
                set: { self.homeNavigationPath = $0 }
            )
        }
    }
    
    // Navigation destinations
    enum Destination: Hashable {
        case profile(User)
        case settings
        case mealDetail(Meal)
        case symptomDetail(Symptom)
        case logMeal
        case logSymptom
        case calendar(Date)
        case insights
        case userReminders
    }
    
    // Navigation actions
    func navigateTo(_ destination: Destination) {
        switch destination {
        case .profile:
            isShowingProfile = true
        case .settings:
            isShowingSettings = true
        case .logMeal:
            isShowingMealLoggingOptions = true
        case .logSymptom:
            selectedTab = .symptoms
            symptomsNavigationPath.append(destination)
        case .calendar, .mealDetail, .symptomDetail, .insights, .userReminders:
            currentNavigationPath.wrappedValue.append(destination)
        }
    }
    
    func popToRoot() {
        currentNavigationPath.wrappedValue = NavigationPath()
    }
    
    func switchTab(to tab: CustomTabBar.Tab) {
        selectedTab = tab
    }
    
    func dismissProfile() {
        isShowingProfile = false
    }
    
    func dismissSettings() {
        isShowingSettings = false
    }
}

// MARK: - NavigationCoordinator Environment Key
struct NavigationCoordinatorKey: EnvironmentKey {
    @MainActor static var defaultValue: NavigationCoordinator = NavigationCoordinator()
}

extension EnvironmentValues {
    var navigationCoordinator: NavigationCoordinator {
        get { self[NavigationCoordinatorKey.self] }
        set { self[NavigationCoordinatorKey.self] = newValue }
    }
}
