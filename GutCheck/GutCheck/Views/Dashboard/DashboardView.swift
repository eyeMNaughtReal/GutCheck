import SwiftUI

struct DashboardView: View {
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
                        // Horizontal week selector with navigation on date tap
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
                .navigationBarItems(
                    trailing: ProfileAvatarButton {
                        showProfileSheet = true
                    }
                )
                .sheet(isPresented: $showProfileSheet) {
                    ProfileMenuSheet()
                }
                .navigationDestination(isPresented: $showCalendar) {
                    if let date = selectedCalendarDate {
                        CalendarView(selectedDate: date)
                    }
                }
            }
            CustomTabBar(selectedTab: $selectedTab)
        }

    }
}

#Preview {
    DashboardView()
}
