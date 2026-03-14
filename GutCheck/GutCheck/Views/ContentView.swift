#Preview {
    ContentView()
        .environment(AuthService())
        .environment(AppRouter.shared)
}
//
//  ContentView.swift
//  GutCheck
//
//  Updated ContentView with meal logging and viewing functionality
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) var authService
    @Bindable var router = AppRouter.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack(path: $router.dashboardPath) {
                Group {
                    switch router.selectedTab {
                    case .dashboard:
                        DashboardView()
                    case .meals, .symptoms:
                        CalendarView(selectedTab: router.selectedTab)
                    case .medications:
                        MedicationsView()
                    case .insights:
                        InsightsView()
                    }
                }
                .navigationDestination(for: AppDestination.self) { destination in
                    destinationView(for: destination)
                }
                .navigationDestination(for: SettingsRoute.self) { route in
                    SettingsRoute.destinationView(for: route)
                }
                .sheet(item: $router.activeSheet) { sheet in
                    sheetView(for: sheet)
                }

            }

            CustomTabBar(selectedTab: $router.selectedTab) { action in
                handleTabBarAction(action)
            }
        }
        .environment(router)
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
        case .symptomHistory(let symptom):
            SymptomDetailView(symptom: symptom)
        case .medicationList:
            MedicationListView()
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
                .environment(router)
        case .symptomForm(_):
            LogSymptomView()
                .environment(router)
        case .logEntry:
            LogEntryView()
                .environment(router)
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


