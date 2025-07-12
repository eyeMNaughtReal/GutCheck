
import SwiftUI

struct DashboardView: View {
    @State private var todaysMeals: [Meal] = [] // Loaded from Firebase/Core Data
    @State private var todaysSymptoms: [Symptom] = []
    @State private var triggerAlerts: [String] = [] // AI-generated
    @State private var insightMessage: String? = nil
    @State private var selectedTab: CustomTabBar.Tab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        GreetingHeaderView()
                        TodaySummaryView(
                            mealsCount: todaysMeals.count,
                            symptomsCount: todaysSymptoms.count
                        )
                        if let insight = insightMessage {
                            InsightsCardView(message: insight)
                        }
                        if !triggerAlerts.isEmpty {
                            TriggerAlertView(alerts: triggerAlerts)
                        }
                        RecentActivityListView(meals: todaysMeals, symptoms: todaysSymptoms)
                        GraphPreviewView(meals: todaysMeals, symptoms: todaysSymptoms)
                        CalendarShortcutButton()
                    }
                    .padding(.bottom, 80) // Space for tab bar
                    .padding(.top)
                }
                .navigationTitle("Dashboard")
                .onAppear {
                    loadDashboardData()
                }
            }
            CustomTabBar(selectedTab: $selectedTab)
        }
    }

    private func loadDashboardData() {
        // TODO: Load meals and symptoms from local Core Data or Firebase
        // TODO: Query AI trigger insights
    }
}

#Preview {
    DashboardView()
}
