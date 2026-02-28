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
    @EnvironmentObject var authService: AuthService
    
    /// Navigation router for programmatic navigation
    @EnvironmentObject var router: AppRouter
    
    /// Data store containing dashboard-specific data and insights
    @StateObject private var dashboardStore = DashboardDataStore(preview: false)
    
    /// View model for recent activity display
    @StateObject private var recentActivityViewModel = RecentActivityViewModel()

    /// Manager for coordinating data refresh across the app
    @EnvironmentObject private var refreshManager: RefreshManager

    @State private var showingLogMedication = false
    
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
            
            // Action Buttons - Side by side at bottom
            HStack(spacing: 16) {
                Button(action: {
                    HapticManager.shared.medium()
                    router.startMealLogging()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 18, weight: .semibold))
                            .accessibleDecorative()
                        Text("Log Meal")
                            .typography(Typography.button)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .accessibleButton(
                    label: "Log Meal",
                    hint: "Tap to log a new meal"
                )
                .accessibilityIdentifier(AccessibilityIdentifiers.Dashboard.logMealButton)
                
                Button(action: {
                    HapticManager.shared.medium()
                    router.startSymptomLogging()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 18, weight: .semibold))
                            .accessibleDecorative()
                        Text("Log Symptom")
                            .typography(Typography.button)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundColor(.white)
                    .background(Color.purple)
                    .cornerRadius(12)
                }
                .accessibleButton(
                    label: "Log Symptom",
                    hint: "Tap to log symptoms"
                )
                .accessibilityIdentifier(AccessibilityIdentifiers.Dashboard.logSymptomButton)

                Button(action: {
                    HapticManager.shared.medium()
                    showingLogMedication = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .accessibleDecorative()
                        Text("Log Meds")
                            .typography(Typography.button)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundColor(.white)
                    .background(Color(red: 0.5, green: 0.2, blue: 0.7))
                    .cornerRadius(12)
                }
                .accessibleButton(
                    label: "Log Meds",
                    hint: "Tap to log a medication dose"
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(ColorTheme.cardBackground)
            .shadow(color: ColorTheme.shadowColor.opacity(0.1), radius: 8, x: 0, y: -2)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
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
            dashboardStore.loadDataForSelectedDate()
        }
        .onChange(of: refreshManager.refreshToken) { _, _ in
            print("📱 DashboardView: Refresh triggered by RefreshManager")
            loadDataIfAuthenticated()
        }
        .sheet(isPresented: $showingLogMedication) {
            LogMedicationDoseView { }
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

// MARK: - Modern Dashboard Components

/// Health Score Card - Large prominent display of overall health
struct HealthScoreCard: View {
    let score: Int
    
    private var scoreColor: Color {
        switch score {
        case 1...3: return .red
        case 4...6: return .orange
        case 7...8: return Color(red: 0.8, green: 0.8, blue: 0.2) // Yellow
        case 9...10: return .green
        default: return .gray
        }
    }
    
    private var scoreLabel: String {
        switch score {
        case 1...3: return "Needs Attention"
        case 4...6: return "Could Be Better"
        case 7...8: return "Doing Well"
        case 9...10: return "Excellent!"
        default: return "Unknown"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Health Score")
                        .typography(Typography.headline)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(score)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor)
                        
                        Text("/10")
                            .typography(Typography.title)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    
                    Text(scoreLabel)
                        .typography(Typography.subheadline)
                        .foregroundColor(scoreColor)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Circular progress indicator
                ZStack {
                    Circle()
                        .stroke(ColorTheme.border.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 10.0)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: score)
                    
                    Image(systemName: score >= 7 ? "checkmark.circle.fill" : "heart.fill")
                        .font(.system(size: 28))
                        .foregroundColor(scoreColor)
                }
                .accessibleDecorative()
            }
            
            // Progress bar alternative
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(ColorTheme.border.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * CGFloat(score) / 10.0, height: 6)
                        .cornerRadius(3)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: score)
                }
            }
            .frame(height: 6)
            .accessibleDecorative()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ColorTheme.cardBackground)
                .shadow(color: ColorTheme.shadowColor.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health Score: \(score) out of 10, \(scoreLabel)")
        .accessibilityIdentifier(AccessibilityIdentifiers.Dashboard.healthScoreCard)
    }
}

/// Dashboard Insight Card - Compact card for Focus and Avoidance tips
struct DashboardInsightCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(8)
                    .accessibleDecorative()
                
                Text(title)
                    .typography(Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.primaryText)
            }
            
            Text(content)
                .typography(Typography.caption)
                .foregroundColor(ColorTheme.secondaryText)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ColorTheme.cardBackground)
                .shadow(color: ColorTheme.shadowColor.opacity(0.08), radius: 6, x: 0, y: 2)
        )
    }
}

/// Floating Action Button - Modern circular button with label
struct FloatingActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.medium()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .accessibleDecorative()
                
                Text(label)
                    .typography(Typography.button)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
            )
        }
        .accessibleButton(
            label: label,
            hint: "Tap to \(label.lowercased())"
        )
    }
}

/// Trigger Alert Card - Warning card for health triggers
struct TriggerAlertCard: View {
    let alert: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(.orange)
            
            Text(alert)
                .font(.subheadline)
                .foregroundColor(ColorTheme.primaryText)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Legacy Dashboard Insights View (Deprecated)

/// Dashboard insights component that displays three key health metrics
/// 
/// ⚠️ DEPRECATED: This view has been replaced by individual modern components
/// (HealthScoreCard, InsightCard) for better visual hierarchy and flexibility.
/// Keeping for backward compatibility but should be removed in next major version.
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
