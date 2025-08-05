//
//  NavigationCoordinator.swift
//  GutCheck
//
//  Centralized navigation management to replace mixed NavigationView/NavigationStack usage
//

import SwiftUI

@MainActor
class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    // Published properties for navigation state
    @Published var selectedTab: Tab = .dashboard // Using shared Tab enum
    @Published private(set) var isResettingNavigation = false
    @Published var shouldRefreshDashboard = false // Add this for dashboard refresh
    
    func resetToRoot() {
        // Reset any navigation state, active sheets, etc.
        DispatchQueue.main.async {
            self.isResettingNavigation = true
            // Reset to dashboard tab
            self.selectedTab = .dashboard
            // Dismiss any presented sheets
            self.dismissAllSheets()
            // Clear navigation stacks
            self.clearNavigationStacks()
            // Reset the flag after a brief delay to allow animations to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isResettingNavigation = false
            }
        }
    }
    
    private func dismissAllSheets() {
        isShowingProfile = false
        isShowingSettings = false
        isShowingMealLoggingOptions = false
        isShowingSymptomLoggingSheet = false
    }
    
    private func clearNavigationStacks() {
        navigationPath.removeLast(navigationPath.count)
        homeNavigationPath.removeLast(homeNavigationPath.count)
        mealNavigationPath.removeLast(mealNavigationPath.count)
        symptomsNavigationPath.removeLast(symptomsNavigationPath.count)
        insightsNavigationPath.removeLast(insightsNavigationPath.count)
    }
    @Published var navigationPath = NavigationPath()
    @Published var isShowingProfile = false
    @Published var isShowingSettings = false
    
    // Additional property for meal logging options
    @Published var isShowingMealLoggingOptions = false
    @Published var isShowingSymptomLoggingSheet = false
    
    // Tab-specific navigation paths
    @Published var homeNavigationPath = NavigationPath()
    @Published var mealNavigationPath = NavigationPath()
    @Published var symptomsNavigationPath = NavigationPath()
    @Published var insightsNavigationPath = NavigationPath()
    
    // Current navigation path based on selected tab
    var currentNavigationPath: Binding<NavigationPath> {
        switch selectedTab {
        case .dashboard:
            return Binding(
                get: { self.homeNavigationPath },
                set: { self.homeNavigationPath = $0 }
            )
        case .meals:
            return Binding(
                get: { self.mealNavigationPath },
                set: { self.mealNavigationPath = $0 }
            )
        case .add:
            return Binding(
                get: { self.navigationPath },
                set: { self.navigationPath = $0 }
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
        }
    }
    
    // Navigation destinations
    enum Destination: Hashable {
        case profile(User)
        case settings
        case mealDetail(Meal)
        case symptomDetail(Symptom)
        case foodDetail(FoodItem)
        case logMeal
        case logSymptom
        case mealBuilder
        case calendar(Date)
        case insights
        case userReminders
    }
    
    // Navigation actions
    func navigateTo(_ destination: Destination) {
        print("🧭 NavigationCoordinator: Navigating to \(destination)")
        print("🧭 Current tab: \(selectedTab)")
        
        switch destination {
        case .profile:
            isShowingProfile = true
        case .settings:
            isShowingSettings = true
        case .logMeal:
            currentNavigationPath.wrappedValue.append(Destination.mealBuilder)
        case .mealBuilder:
            currentNavigationPath.wrappedValue.append(destination)
        case .logSymptom:
            currentNavigationPath.wrappedValue.append(destination)
        case .calendar, .mealDetail, .symptomDetail, .foodDetail, .insights, .userReminders:
            print("🧭 Appending to navigation path. Current path count: \(currentNavigationPath.wrappedValue.count)")
            currentNavigationPath.wrappedValue.append(destination)
            print("🧭 New path count: \(currentNavigationPath.wrappedValue.count)")
        }
    }
    
    func popToRoot() {
        currentNavigationPath.wrappedValue = NavigationPath()
    }
    
    func switchTab(to tab: Tab) {
        selectedTab = tab
    }
    
    func dismissProfile() {
        isShowingProfile = false
    }
    
    func dismissSettings() {
        isShowingSettings = false
    }
    
    // Method to trigger dashboard data refresh
    func refreshDashboard() {
        print("🔄 NavigationCoordinator: Triggering dashboard refresh")
        shouldRefreshDashboard.toggle()
    }
    
    // Method to show meal logging options from MealBuilderView
    func showMealLoggingOptions() {
        isShowingMealLoggingOptions = true
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
