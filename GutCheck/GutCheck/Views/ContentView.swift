// MARK: - Preview
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthService())
            .environmentObject(AppRouter.shared)
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
    @ObservedObject var router = AppRouter.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack(path: $router.path) {
                Group {
                    switch router.selectedTab {
                    case .dashboard:
                        DashboardView()
                    case .meals, .symptoms:
                        CalendarView(selectedTab: router.selectedTab)
                    case .insights:
                        InsightsView()
                    }
                }
                .navigationDestination(for: AppDestination.self) { destination in
                    destinationView(for: destination)
                }
                .sheet(item: $router.activeSheet) { sheet in
                    sheetView(for: sheet)
                }

            }

            CustomTabBar(selectedTab: $router.selectedTab) { action in
                handleTabBarAction(action)
            }
        }
        .environmentObject(router)
        .background(ColorTheme.background.ignoresSafeArea())

    }
    
    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .dashboard:
            DashboardView()
        case .calendar(let date):
            CalendarView(selectedDate: date)
        case .mealDetail(let id):
            if let id = id {
                // Use the new sheet-based approach instead of navigation
                EmptyView()
                    .onAppear {
                        router.viewMealDetails(id: id)
                    }
            } else {
                Text("Invalid meal")
            }
        case .symptomDetail(let id):
            if let id = id {
                // Use the new sheet-based approach instead of navigation
                EmptyView()
                    .onAppear {
                        router.viewSymptomDetails(id: id)
                    }
            } else {
                Text("Invalid symptom")
            }
        case .settings:
            SettingsView()
        case .analytics:
            InsightsView()
        }
    }
    
    @ViewBuilder
    private func sheetView(for sheet: SheetDestination) -> some View {
        switch sheet {
        case .profile:
            if let currentUser = authService.currentUser {
                UserProfileView(user: currentUser)
            } else {
                Text("User information unavailable")
            }
        case .mealForm(_):
            MealBuilderView()
                .environmentObject(router)
        case .symptomForm(_):
            LogSymptomView()
                .environmentObject(router)
        case .logEntry:
            LogEntryView()
                .environmentObject(router)
        }
    }
    
    private func handleTabBarAction(_ action: TabBarAction) {
        switch action {
        case .logMeal:
            // Show meal logging options as a sheet
            router.presentLogEntryView()
        case .logSymptom:
            router.startSymptomLogging()
        case .tabTapped(_):
            // Handle same tab tapped - already handled in CustomTabBar
            break
        }
    }
}

// MARK: - Tab Bar Actions
enum TabBarAction {
    case logMeal
    case logSymptom
    case tabTapped(Tab)
}


