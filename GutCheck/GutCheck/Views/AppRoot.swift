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
                }
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                
                NavigationStack {
                    CalendarView(selectedTab: .meals)
                }
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                
                NavigationStack {
                    CalendarView(selectedTab: .symptoms)
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
                
                // This is just a placeholder - tapping will open the LogEntryView sheet
                Color.clear
                    .tabItem {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                    .onTapGesture {
                        router.presentLogEntryView()
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
        .sheet(item: $router.symptomDetailSheet) { symptomSheet in
            SymptomDetailView(symptomId: symptomSheet.symptomId)
                .environmentObject(router)
                .environmentObject(refreshManager)
        }
        .sheet(item: $router.mealDetailSheet) { mealSheet in
            MealDetailView(mealId: mealSheet.mealId)
                .environmentObject(router)
                .environmentObject(refreshManager)
        }
        .environmentObject(router)
        .environmentObject(refreshManager)
    }
}

#Preview {
    AppRoot()
        .environmentObject(PreviewAuthService())
}
