import SwiftUI

struct AppRoot: View {
    @State private var router = AppRouter.shared
    @State private var refreshManager = RefreshManager.shared
    @Environment(LocalUserService.self) var userService
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $router.selectedTab) {
                SwiftUI.Tab("Dashboard", systemImage: "house.fill", value: GutCheck.Tab.dashboard) {
                    NavigationStack(path: $router.dashboardPath) {
                        DashboardView()
                            .withAppNavigationDestinations(router: router, refreshManager: refreshManager)
                    }
                }

                SwiftUI.Tab("Meals", systemImage: "fork.knife", value: GutCheck.Tab.meals) {
                    NavigationStack(path: $router.mealsPath) {
                        CalendarView(selectedTab: .meals)
                            .withAppNavigationDestinations(router: router, refreshManager: refreshManager)
                    }
                }

                SwiftUI.Tab("Symptoms", systemImage: "heart.text.square.fill", value: GutCheck.Tab.symptoms) {
                    NavigationStack(path: $router.symptomsPath) {
                        CalendarView(selectedTab: .symptoms)
                            .withAppNavigationDestinations(router: router, refreshManager: refreshManager)
                    }
                }

                SwiftUI.Tab("Meds", systemImage: "pills.fill", value: GutCheck.Tab.medications) {
                    NavigationStack {
                        MedicationCalendarView()
                            .withAppNavigationDestinations(router: router, refreshManager: refreshManager)
                    }
                }

                SwiftUI.Tab("Insights", systemImage: "chart.bar.fill", value: GutCheck.Tab.insights) {
                    NavigationStack {
                        InsightsView()
                    }
                }
            }

            // Handle the sheet presentations
            .sheet(item: $router.activeSheet) { sheetType in
                NavigationStack {
                    switch sheetType {
                    case .profile:
                        if let currentUser = userService.currentUser {
                            UserProfileView(user: currentUser)
                                .environment(userService)
                        } else {
                            Text("User information unavailable")
                                .environment(userService)
                        }
                    case .mealForm(let id):
                        MealBuilderView(mealId: id)
                            .environment(router)
                            .environment(refreshManager)
                    case .symptomForm(let id):
                        if id != nil {
                            // Edit existing symptom - need to create LogSymptomView_New with id support
                            LogSymptomView()
                                .environment(router)
                                .environment(refreshManager)
                        } else {
                            // Create new symptom
                            LogSymptomView()
                                .environment(router)
                                .environment(refreshManager)
                        }
                    case .logEntry:
                        LogEntryView()
                            .environment(router)
                    }
                }
            }
        }

        .environment(router)
        .environment(refreshManager)
    }
}

// MARK: - Shared Navigation Destinations

private struct AppNavigationDestinations: ViewModifier {
    var router: AppRouter
    var refreshManager: RefreshManager

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .dashboard:
                    DashboardView()
                case .calendar(let date):
                    CalendarView(selectedDate: date)
                case .mealDetail(let id):
                    if let id = id {
                        MealDetailView(mealId: id)
                            .environment(router)
                            .environment(refreshManager)
                    } else {
                        Text("Invalid meal")
                    }
                case .symptomDetail(let id):
                    if let id = id {
                        SymptomDetailView(symptomId: id)
                            .environment(router)
                            .environment(refreshManager)
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
            .navigationDestination(for: SettingsRoute.self) { route in
                SettingsRoute.destinationView(for: route)
            }
    }
}

extension View {
    func withAppNavigationDestinations(router: AppRouter, refreshManager: RefreshManager) -> some View {
        modifier(AppNavigationDestinations(router: router, refreshManager: refreshManager))
    }
}

#Preview {
    AppRoot()
        .environment(LocalUserService.shared)
}
