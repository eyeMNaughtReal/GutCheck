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
import FirebaseAuth
#if canImport(UIKit)
import UIKit
#endif

#if DEBUG
@_spi(Preview) import FirebaseAuth // For preview support
#endif

struct DashboardView: View {
    // MARK: - Environment Objects
    
    /// Authentication service for user management and data access
    @Environment(AuthService.self) var authService
    
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
                        recentActivityViewModel.loadRecentActivity(for: selectedDate, authService: authService)
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
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
            dashboardStore.loadDataForSelectedDate()
        }
        .onChange(of: refreshManager.refreshToken) { _, _ in
            loadDataIfAuthenticated()
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads dashboard data if the user is authenticated
    /// This method ensures data is only loaded for authenticated users
    private func loadDataIfAuthenticated() {
        guard authService.isAuthenticated, authService.currentUser != nil else {
            return
        }
        
        recentActivityViewModel.loadRecentActivity(for: dashboardStore.selectedDate, authService: authService)
    }
}

#Preview {
    DashboardView()
        .environment(PreviewAuthService())
        .environment(AppRouter.shared)
        .environment(RefreshManager.shared)

}
