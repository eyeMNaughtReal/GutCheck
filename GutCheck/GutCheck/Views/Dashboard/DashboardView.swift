import SwiftUI

struct DashboardView: View {
    @StateObject private var dashboardStore = DashboardDataStore()
    @State private var selectedTab: CustomTabBar.Tab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        GreetingHeaderView()
                        
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

                        RecentActivityListView(
                            meals: dashboardStore.todaysMeals,
                            symptoms: dashboardStore.todaysSymptoms
                        )

                        GraphPreviewView(
                            meals: dashboardStore.todaysMeals,
                            symptoms: dashboardStore.todaysSymptoms
                        )

                        CalendarShortcutButton()
                    }
                    .padding(.bottom, 80)
                    .padding(.top)
                }
                .navigationTitle("Dashboard")
                .onAppear {
                    dashboardStore.refresh()
                }
            }

            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    DashboardView()
}
