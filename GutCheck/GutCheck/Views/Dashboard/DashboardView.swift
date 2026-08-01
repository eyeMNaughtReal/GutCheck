//
//  DashboardView.swift
//  GutCheck
//
//  Main dashboard view that provides users with a comprehensive overview of their health status.
//  Features include:
//  - Today's activity summary
//  - Health insights (score, focus, avoidance tips)
//  - Week selector for historical data browsing
//  - Real-time data updates via RefreshManager
//
//  Created by Mark Conley on 7/12/25.
//  Updated with Phase 2 Accessibility - February 23, 2026
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if DEBUG
#endif

struct DashboardView: View {
    // MARK: - Environment Objects
    
    /// Authentication service for user management and data access
    @Environment(LocalUserService.self) var userService
    
    /// Navigation router for programmatic navigation
    @Environment(AppRouter.self) var router
    
    /// Data store containing dashboard-specific data and insights
    @State private var dashboardStore = DashboardDataStore(preview: false)
    
    /// View model for recent activity display
    @State private var recentActivityViewModel = RecentActivityViewModel()

    /// Manager for coordinating data refresh across the app
    @Environment(RefreshManager.self) private var refreshManager

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // User greeting and welcome message
                    GreetingHeaderView()
                        .padding(.top, 8)
                    
                    // Week selector with refined design
                    WeekSelector(selectedDate: $dashboardStore.selectedDate) { selectedDate in
                        dashboardStore.selectedDate = selectedDate
                        dashboardStore.loadDataForSelectedDate()
                        recentActivityViewModel.loadRecentActivity(for: selectedDate, userService: userService)
                    }
                    .padding(.horizontal, -4)
                    
                    // Combined Today's Summary and Activity with enhanced card
                    TodaysActivitySummaryView(
                        viewModel: recentActivityViewModel,
                        selectedDate: dashboardStore.selectedDate
                    )

                    // Dashboard Insights - Redesigned for visual hierarchy
                    VStack(spacing: 16) {
                        // Insights Grid - Side by side for better use of space
                        HStack(spacing: 16) {
                            // Today's Focus Card
                            DashboardInsightCard(
                                icon: "target",
                                iconColor: .blue,
                                title: "Today's Focus",
                                content: dashboardStore.todaysFocus
                            )
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Today's Focus: \(dashboardStore.todaysFocus)")
                            .accessibilityIdentifier(AccessibilityIdentifiers.Dashboard.todaysFocusCard)
                            
                            // Avoidance Tip Card
                            DashboardInsightCard(
                                icon: "exclamationmark.shield",
                                iconColor: .orange,
                                title: "Watch Out",
                                content: dashboardStore.avoidanceTip
                            )
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Watch Out: \(dashboardStore.avoidanceTip)")
                            .accessibilityIdentifier(AccessibilityIdentifiers.Dashboard.avoidanceTipCard)
                        }
                    }
                    
                    // AI Insights Card
                    AIInsightsCard(
                        summary: dashboardStore.aiInsightSummary,
                        severity: dashboardStore.aiInsightSeverity
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("AI Insights: \(dashboardStore.aiInsightSummary)")
                    .accessibilityIdentifier(AccessibilityIdentifiers.Dashboard.aiInsightsCard)
                    
                    // Trigger alerts with better styling
                    if !dashboardStore.triggerAlerts.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(dashboardStore.triggerAlerts, id: \.self) { alert in
                                TriggerAlertCard(alert: alert)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(ColorTheme.background)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // The avatar and settings button live in GreetingHeaderView now, so the
        // toolbar is intentionally empty here — a second avatar would duplicate it.
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            loadData()
        }
        .onChange(of: userService.currentUser) { _, _ in
            loadData()
        }
        .onChange(of: dashboardStore.selectedDate) { _, _ in
            dashboardStore.loadDataForSelectedDate()
        }
        .onChange(of: refreshManager.refreshToken) { _, _ in
            loadData()
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads dashboard data for the currently selected date.
    private func loadData() {
        // Also refresh the insight store here. It was previously only reachable
        // via onChange(of: selectedDate), so on a cold launch — where the date
        // never changes — Today's Focus, Watch Out and AI Insights stayed empty
        // until the user tapped a date.
        dashboardStore.loadDataForSelectedDate()
        recentActivityViewModel.loadRecentActivity(for: dashboardStore.selectedDate, userService: userService)
    }
}

#Preview {
    DashboardView()
        .environment(LocalUserService.shared)
        .environment(AppRouter.shared)
        .environment(RefreshManager.shared)

}
