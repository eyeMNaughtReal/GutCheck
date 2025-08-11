//
//  DashboardView.swift
//  GutCheck
//
//  Main dashboard view that provides users with a comprehensive overview of their health status.
//  Features include:
//  - Today's activity summary
//  - Health insights (score, focus, avoidance tips)
//  - Week selector for historical data browsing
//  - Quick action buttons for logging meals and symptoms
//  - Real-time data updates via RefreshManager
//
//  Created by Mark Conley on 7/12/25.
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
    @EnvironmentObject var authService: AuthService
    
    /// Navigation router for programmatic navigation
    @EnvironmentObject var router: AppRouter
    
    /// Data store containing dashboard-specific data and insights
    @StateObject private var dashboardStore = DashboardDataStore(preview: false)
    
    /// View model for recent activity display
    @StateObject private var recentActivityViewModel = RecentActivityViewModel()
    
    /// Manager for coordinating data refresh across the app
    @EnvironmentObject private var refreshManager: RefreshManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // User greeting and welcome message
                GreetingHeaderView()
                
                // Week selector for browsing historical data without navigation
                // Users can tap different dates to see insights for those specific days
                WeekSelector(selectedDate: $dashboardStore.selectedDate) { selectedDate in
                    // When a date is selected, refresh the dashboard data
                    dashboardStore.selectedDate = selectedDate
                    dashboardStore.loadDataForSelectedDate()
                    recentActivityViewModel.loadRecentActivity(for: selectedDate, authService: authService)
                }
                
                // Combined Today's Summary and Activity
                // Shows meals and symptoms logged for the selected date
                TodaysActivitySummaryView(
                    viewModel: recentActivityViewModel,
                    selectedDate: dashboardStore.selectedDate
                )

                // Dashboard Insights - NEW FEATURE (December 2025)
                // Provides users with actionable health information:
                // 1. Health Score: 1-10 rating based on symptoms and meals
                // 2. Today's Focus: Personalized health recommendations
                // 3. Avoidance Tip: Pattern-based food trigger warnings
                DashboardInsightsView(
                    healthScore: dashboardStore.todaysHealthScore,
                    todaysFocus: dashboardStore.todaysFocus,
                    avoidanceTip: dashboardStore.avoidanceTip
                )

                // Legacy insight message (deprecated - replaced by DashboardInsightsView)
                if let insight = dashboardStore.insightMessage {
                    InsightsCardView(message: insight)
                }
                
                // Trigger alerts for immediate health warnings
                if !dashboardStore.triggerAlerts.isEmpty {
                    TriggerAlertBanner(alerts: dashboardStore.triggerAlerts)
                }
                
                // Quick action buttons for immediate logging
                // These provide fast access to core app functionality
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
            // When user selects a different date, refresh dashboard data for that date
            // This enables historical browsing without leaving the dashboard
            dashboardStore.loadDataForSelectedDate()
        }
        .onChange(of: refreshManager.refreshToken) { _, _ in
            print("📱 DashboardView: Refresh triggered by RefreshManager")
            loadDataIfAuthenticated()
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads dashboard data if the user is authenticated
    /// This method ensures data is only loaded for authenticated users
    private func loadDataIfAuthenticated() {
        guard authService.isAuthenticated, authService.currentUser != nil else {
            print("📱 DashboardView: Cannot load data - user not authenticated or currentUser nil")
            return
        }
        
        print("📱 DashboardView: Loading data for \(dashboardStore.selectedDate)")
        recentActivityViewModel.loadRecentActivity(for: dashboardStore.selectedDate, authService: authService)
    }
}

// MARK: - Dashboard Insights View

/// Dashboard insights component that displays three key health metrics:
/// 1. Health Score: Visual 1-10 rating with color-coded bar
/// 2. Today's Focus: Actionable health recommendation
/// 3. Avoidance Tip: Pattern-based food trigger warning
///
/// This view automatically updates based on the selected date and provides
/// users with immediate, actionable health information without requiring
/// navigation to other screens.
struct DashboardInsightsView: View {
    // MARK: - Properties
    
    /// Current health score (1-10) calculated from symptoms and meals
    let healthScore: Int
    
    /// Personalized health focus for the selected day
    let todaysFocus: String
    
    /// Smart recommendation about what to avoid today
    let avoidanceTip: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Health Score Section
            // Displays a visual 1-10 rating with color-coded progress bar
            VStack(spacing: 12) {
                HStack {
                    Text("Today's Health Score")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    Spacer()
                    Text("\(healthScore)/10")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(healthScoreColor)
                }
                
                // Health Score Bar
                // Visual representation of the health score with color coding
                HStack(spacing: 4) {
                    ForEach(1...10, id: \.self) { index in
                        Rectangle()
                            .fill(index <= healthScore ? healthScoreColor : ColorTheme.border)
                            .frame(height: 8)
                            .cornerRadius(4)
                    }
                }
            }
            .padding()
            .background(ColorTheme.surface)
            .cornerRadius(12)
            
            // Today's Focus Section
            // Provides actionable health advice based on current symptoms
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.blue)
                    Text("Today's Focus")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(todaysFocus)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(ColorTheme.surface)
            .cornerRadius(12)
            
            // Avoidance Tip Section
            // Warns about potential food triggers based on recent patterns
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Avoidance Tip")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(avoidanceTip)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(ColorTheme.surface)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Returns the appropriate color for the health score
    /// Color coding helps users quickly understand their health status:
    /// - Red (1-3): Poor health day - requires attention
    /// - Orange (4-6): Fair health day - room for improvement
    /// - Yellow (7-8): Good health day - maintaining wellness
    /// - Green (9-10): Excellent health day - optimal wellness
    private var healthScoreColor: Color {
        switch healthScore {
        case 1...3: return .red
        case 4...6: return .orange
        case 7...8: return .yellow
        case 9...10: return .green
        default: return .gray
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(PreviewAuthService())
        .environmentObject(AppRouter.shared)
        .environmentObject(RefreshManager.shared)

}
