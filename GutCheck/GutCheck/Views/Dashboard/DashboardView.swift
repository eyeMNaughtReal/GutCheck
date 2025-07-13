import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService  // Add this line
    @State private var showProfileSheet = false
    @StateObject private var dashboardStore = DashboardDataStore()
    @State private var selectedTab: CustomTabBar.Tab = .home
    @State private var showCalendar = false
    @State private var selectedCalendarDate: Date? = nil
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
                           TodaySummaryView(
                               mealsCount: dashboardStore.todaysMeals.count,
                               symptomsCount: dashboardStore.todaysSymptoms.count
                           )

                           if let insight = dashboardStore.insightMessage {
                               InsightsCardView(message: insight)
                           }
                           if !dashboardStore.triggerAlerts.isEmpty {
                               TriggerAlertView(alerts: dashboardStore.triggerAlerts)
                           }
                           RecentActivityListView(meals: dashboardStore.todaysMeals, symptoms: dashboardStore.todaysSymptoms)
                           GraphPreviewView(meals: dashboardStore.todaysMeals, symptoms: dashboardStore.todaysSymptoms)
                       }
                       .padding(.bottom, 80)
                       .padding(.top)
                   }
                   .navigationTitle("Dashboard")
                   .toolbar {
                       ToolbarItem(placement: .navigationBarTrailing) {
                           ProfileAvatarButton {
                               showProfileSheet = true
                           }
                       }
                   }
                   .sheet(isPresented: $showProfileSheet) {
                       if let currentUser = authService.currentUser {
                           UserProfileView(user: currentUser)
                       } else {
                           VStack(spacing: 20) {
                               ProgressView()
                               Text("Loading profile...")
                                   .foregroundColor(.secondary)
                           }
                           .frame(maxWidth: .infinity, maxHeight: .infinity)
                           .background(Color(.systemBackground))
                       }
                   }
                   .navigationDestination(isPresented: $showCalendar) {
                       if let date = selectedCalendarDate {
                           CalendarView(selectedDate: date)
                       }
                   }
               }
               CustomTabBar(selectedTab: $selectedTab) { action in
                   // Handle tab bar actions
               }
           }
       }
   }

#Preview {
    DashboardView()
}
