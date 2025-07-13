import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var dashboardStore = DashboardDataStore()
    @State private var showProfileSheet = false
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
                        
                        // Spacer instead of GraphPreviewView if needed
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
            }
        }
    }
}

#Preview {
    DashboardView()
}
