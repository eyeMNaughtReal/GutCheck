import SwiftUI

struct AppRoot: View {
    @StateObject private var router = AppRouter.shared
    @StateObject private var refreshManager = RefreshManager.shared
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                NavigationStack(path: $router.path) {
                    DashboardView()
                        .navigationDestination(for: AppDestination.self) { destination in
                            switch destination {
                            case .dashboard:
                                DashboardView()
                            case .calendar(let date):
                                CalendarView(selectedDate: date)
                            case .mealDetail(let id):
                                if let id = id {
                                    MealDetailView(mealId: id)
                                        .environmentObject(router)
                                        .environmentObject(refreshManager)
                                } else {
                                    Text("Invalid meal")
                                }
                            case .symptomDetail(let id):
                                if let id = id {
                                    SymptomDetailView(symptomId: id)
                                        .environmentObject(router)
                                        .environmentObject(refreshManager)
                                } else {
                                    Text("Invalid symptom")
                                }
                            case .settings:
                                SettingsView()
                            case .analytics:
                                InsightsView()
                            }
                        }
                }
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                
                NavigationStack(path: $router.path) {
                    CalendarView(selectedTab: .meals)
                        .navigationDestination(for: AppDestination.self) { destination in
                            switch destination {
                            case .dashboard:
                                DashboardView()
                            case .calendar(let date):
                                CalendarView(selectedDate: date)
                            case .mealDetail(let id):
                                if let id = id {
                                    MealDetailView(mealId: id)
                                        .environmentObject(router)
                                        .environmentObject(refreshManager)
                                } else {
                                    Text("Invalid meal")
                                }
                            case .symptomDetail(let id):
                                if let id = id {
                                    SymptomDetailView(symptomId: id)
                                        .environmentObject(router)
                                        .environmentObject(refreshManager)
                                } else {
                                    Text("Invalid symptom")
                                }
                            case .settings:
                                SettingsView()
                            case .analytics:
                                InsightsView()
                            }
                        }
                }
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                
                NavigationStack(path: $router.path) {
                    CalendarView(selectedTab: .symptoms)
                        .navigationDestination(for: AppDestination.self) { destination in
                            switch destination {
                            case .dashboard:
                                DashboardView()
                            case .calendar(let date):
                                CalendarView(selectedDate: date)
                            case .mealDetail(let id):
                                if let id = id {
                                    MealDetailView(mealId: id)
                                        .environmentObject(router)
                                        .environmentObject(refreshManager)
                                } else {
                                    Text("Invalid meal")
                                }
                            case .symptomDetail(let id):
                                if let id = id {
                                    SymptomDetailView(symptomId: id)
                                        .environmentObject(router)
                                        .environmentObject(refreshManager)
                                } else {
                                    Text("Invalid symptom")
                                }
                            case .settings:
                                SettingsView()
                            case .analytics:
                                InsightsView()
                            }
                        }
                }
                .tabItem {
                    Label("Symptoms", systemImage: "heart.text.square.fill")
                }
                
                NavigationStack {
                    InsightsView()
                }
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
            }
            
            // Handle the sheet presentations
            .sheet(item: $router.activeSheet) { sheetType in
                NavigationStack {
                    switch sheetType {
                    case .profile:
                        if let currentUser = authService.currentUser {
                            UserProfileView(user: currentUser)
                                .environmentObject(authService)
                        } else {
                            Text("User information unavailable")
                                .environmentObject(authService)
                        }
                    case .mealForm(let id):
                        if id != nil {
                            // Edit existing meal - MealBuilderView supports editing with meal ID
                            MealBuilderView()
                                .environmentObject(router)
                                .environmentObject(refreshManager)
                        } else {
                            // Create new meal
                            MealBuilderView()
                                .environmentObject(router)
                                .environmentObject(refreshManager)
                        }
                    case .symptomForm(let id):
                        if id != nil {
                            // Edit existing symptom - need to create LogSymptomView_New with id support
                            LogSymptomView()
                                .environmentObject(router)
                                .environmentObject(refreshManager)
                        } else {
                            // Create new symptom
                            LogSymptomView()
                                .environmentObject(router)
                                .environmentObject(refreshManager)
                        }
                    case .logEntry:
                        LogEntryView()
                            .environmentObject(router)
                    }
                }
            }
        }

        .environmentObject(router)
        .environmentObject(refreshManager)
    }
}

#Preview {
    AppRoot()
        .environmentObject(PreviewAuthService())
}
