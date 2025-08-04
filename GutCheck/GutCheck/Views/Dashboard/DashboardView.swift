import SwiftUI
import FirebaseAuth

#if DEBUG
@_spi(Preview) import FirebaseAuth // For preview support
#endif

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @StateObject private var dashboardStore = DashboardDataStore(preview: false)
    @StateObject private var recentActivityViewModel = RecentActivityViewModel()
    @State private var showProfileSheet = false
    @State private var showCalendar = false
    @State private var selectedCalendarDate: Date? = nil
    // Removed floating + button state
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        GreetingHeaderView()
                        
                        WeekSelector(selectedDate: $dashboardStore.selectedDate) { date in
                            dashboardStore.selectedDate = date
                            selectedCalendarDate = date
                            showCalendar = true
                        }
                        
                        // Combined Today's Summary and Activity
                        TodaysActivitySummaryView(
                            viewModel: recentActivityViewModel,
                            selectedDate: dashboardStore.selectedDate
                        )

                        if let insight = dashboardStore.insightMessage {
                            InsightsCardView(message: insight)
                        }
                        
                        if !dashboardStore.triggerAlerts.isEmpty {
                            TriggerAlertBanner(alerts: dashboardStore.triggerAlerts)
                        }
                        
                        // Spacer for tab bar
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                .navigationTitle("Dashboard")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showProfileSheet = true
                        }) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                                .foregroundColor(ColorTheme.accent)
                        }
                    }
                }
                .sheet(isPresented: $showProfileSheet) {
                    ProfileSheetView()
                        .environmentObject(authService)
                }
                .navigationDestination(isPresented: $showCalendar) {
                    if let date = selectedCalendarDate {
                        CalendarView(selectedDate: date)
                    }
                }
                .onAppear {
                    print("📱 DashboardView: onAppear - checking auth state and loading data")
                    if authService.isAuthenticated && authService.currentUser != nil {
                        print("📱 DashboardView: User is authenticated with currentUser, loading recent activity data")
                        recentActivityViewModel.loadRecentActivity(for: dashboardStore.selectedDate, authService: authService)
                    } else {
                        print("📱 DashboardView: User not fully authenticated yet (isAuth: \(authService.isAuthenticated), currentUser: \(authService.currentUser != nil)), waiting for auth state change")
                    }
                }
                .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                    print("🔐 DashboardView: Authentication state changed to \(isAuthenticated)")
                    if isAuthenticated && authService.currentUser != nil {
                        print("🔐 DashboardView: User authenticated with currentUser, loading recent activity data")
                        recentActivityViewModel.loadRecentActivity(for: dashboardStore.selectedDate, authService: authService)
                    }
                }
                .onChange(of: authService.currentUser) { _, currentUser in
                    print("👤 DashboardView: CurrentUser changed to \(currentUser?.id ?? "nil")")
                    if authService.isAuthenticated && currentUser != nil {
                        print("👤 DashboardView: CurrentUser is now available, loading recent activity data")
                        recentActivityViewModel.loadRecentActivity(for: dashboardStore.selectedDate, authService: authService)
                    }
                }
                .onChange(of: dashboardStore.selectedDate) { _, newDate in
                    print("📅 DashboardView: Date changed to \(newDate) - reloading recent activity")
                    if authService.isAuthenticated && authService.currentUser != nil {
                        recentActivityViewModel.loadRecentActivity(for: newDate, authService: authService)
                    }
                }
                .onChange(of: navigationCoordinator.shouldRefreshDashboard) { _, _ in
                    print("🔄 DashboardView: Refresh triggered by NavigationCoordinator")
                    if authService.isAuthenticated && authService.currentUser != nil {
                        recentActivityViewModel.loadRecentActivity(for: dashboardStore.selectedDate, authService: authService)
                    }
                }
            }
            // Floating + button for logging meal
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(PreviewAuthService())
        .environmentObject(DashboardDataStore(preview: true))
}
