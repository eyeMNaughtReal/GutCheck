import SwiftUI

struct AppRoot: View {
    @StateObject private var router = AppRouter.shared
    @StateObject private var refreshManager = RefreshManager.shared
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var serverStatusService: ServerStatusService
    @State private var showingServerStatusSheet = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $router.selectedTab) {
                NavigationStack(path: $router.dashboardPath) {
                    DashboardView()
                        .withAppNavigationDestinations(router: router, refreshManager: refreshManager)
                }
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(Tab.dashboard)
                
                NavigationStack(path: $router.mealsPath) {
                    CalendarView(selectedTab: .meals)
                        .withAppNavigationDestinations(router: router, refreshManager: refreshManager)
                }
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                .tag(Tab.meals)
                
                NavigationStack(path: $router.symptomsPath) {
                    CalendarView(selectedTab: .symptoms)
                        .withAppNavigationDestinations(router: router, refreshManager: refreshManager)
                }
                .tabItem {
                    Label("Symptoms", systemImage: "heart.text.square.fill")
                }
                .tag(Tab.symptoms)
                
                NavigationStack {
                    MedicationCalendarView()
                }
                .tabItem {
                    Label("Meds", systemImage: "pills.fill")
                }
                .tag(Tab.medications)

                NavigationStack {
                    InsightsView()
                }
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(Tab.insights)
            }
            
            .safeAreaInset(edge: .top) {
                OfflineBannerView(showingStatusSheet: $showingServerStatusSheet)
                    .animation(.easeInOut(duration: 0.3), value: serverStatusService.isOffline)
            }
            
            // Server status sheet (separate from router sheets)
            .sheet(isPresented: $showingServerStatusSheet) {
                ServerStatusSheet()
                    .environmentObject(serverStatusService)
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
                        MealBuilderView(mealId: id)
                            .environmentObject(router)
                            .environmentObject(refreshManager)
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

// MARK: - Shared Navigation Destinations

private struct AppNavigationDestinations: ViewModifier {
    @ObservedObject var router: AppRouter
    @ObservedObject var refreshManager: RefreshManager

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
}

extension View {
    func withAppNavigationDestinations(router: AppRouter, refreshManager: RefreshManager) -> some View {
        modifier(AppNavigationDestinations(router: router, refreshManager: refreshManager))
    }
}

#Preview {
    AppRoot()
        .environmentObject(PreviewAuthService())
}
