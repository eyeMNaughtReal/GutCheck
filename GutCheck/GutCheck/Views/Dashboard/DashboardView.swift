import SwiftUI
import FirebaseAuth

#if DEBUG
@_spi(Preview) import FirebaseAuth // For preview support
#endif

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var dashboardStore = DashboardDataStore(preview: false)
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
                        
                        TodaySummaryView(
                            mealsCount: dashboardStore.todaysMeals.count,
                            symptomsCount: dashboardStore.todaysSymptoms.count
                        )

                        if let insight = dashboardStore.insightMessage {
                            InsightsCardView(message: insight)
                        }
                        
                        if !dashboardStore.triggerAlerts.isEmpty {
                            TriggerAlertBanner(alerts: dashboardStore.triggerAlerts)
                        }
                        
                        // Use the enhanced RecentActivityListView
                        RecentActivityListView(selectedDate: dashboardStore.selectedDate)
                        
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
