import SwiftUI
import FirebaseAuth
#if canImport(UIKit)
import UIKit
#endif

#if DEBUG
@_spi(Preview) import FirebaseAuth // For preview support
#endif

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var router: AppRouter
    @StateObject private var dashboardStore = DashboardDataStore(preview: false)
    @StateObject private var recentActivityViewModel = RecentActivityViewModel()
    @EnvironmentObject private var refreshManager: RefreshManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                GreetingHeaderView()
                
                WeekSelector(selectedDate: $dashboardStore.selectedDate) { date in
                    dashboardStore.selectedDate = date
                    // Navigate to calendar view using the AppRouter
                    router.navigateToCalendar(date: date)
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
                
                // Quick action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        router.startMealLogging()
                    }) {
                        VStack {
                            Image(systemName: "fork.knife")
                                .font(.title)
                            Text("Log Meal")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        router.startSymptomLogging()
                    }) {
                        VStack {
                            Image(systemName: "heart.text.square")
                                .font(.title)
                            Text("Log Symptom")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding(.top, 10)
                
                // Spacer for tab bar
                Spacer(minLength: 80)
            }
            .padding(.horizontal)
            .padding(.top)
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ProfileAvatarButton(user: authService.currentUser) {
                    router.showProfile()
                }
            }
        }
        .onAppear {
            loadDataIfAuthenticated()
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated && authService.currentUser != nil {
                loadDataIfAuthenticated()
            }
        }
        .onChange(of: authService.currentUser) { _, _ in
            loadDataIfAuthenticated()
        }
        .onChange(of: dashboardStore.selectedDate) { _, _ in
            loadDataIfAuthenticated()
        }
        .onChange(of: refreshManager.refreshToken) { _, _ in
            print("📱 DashboardView: Refresh triggered by RefreshManager")
            loadDataIfAuthenticated()
        }
    }
    
    private func loadDataIfAuthenticated() {
        guard authService.isAuthenticated, authService.currentUser != nil else {
            print("📱 DashboardView: Cannot load data - user not authenticated or currentUser nil")
            return
        }
        
        print("📱 DashboardView: Loading data for \(dashboardStore.selectedDate)")
        recentActivityViewModel.loadRecentActivity(for: dashboardStore.selectedDate, authService: authService)
    }
    

}

#Preview {
    DashboardView()
        .environmentObject(PreviewAuthService())
        .environmentObject(AppRouter.shared)
        .environmentObject(RefreshManager.shared)

}
