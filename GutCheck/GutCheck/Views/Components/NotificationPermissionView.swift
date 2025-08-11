//
//  NotificationPermissionView.swift
//  GutCheck
//
//  Notification permission request component following iOS 18.5+ guidelines
//

import SwiftUI

struct NotificationPermissionView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var isRequesting = false
    
    let title: String
    let message: String
    let onPermissionResult: (Bool) -> Void
    
    init(
        title: String = "Stay on Track with Reminders",
        message: String = "Get gentle reminders to log your meals and symptoms for better health insights.",
        onPermissionResult: @escaping (Bool) -> Void = { _ in }
    ) {
        self.title = title
        self.message = message
        self.onPermissionResult = onPermissionResult
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon and title
            VStack(spacing: 16) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 64))
                    .foregroundColor(ColorTheme.primary)
                
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.secondaryText)
                    .lineLimit(nil)
            }
            
            // Reminder benefits
            reminderBenefitsView
            
            // Permission status
            notificationStatusCard
            
            // Action buttons
            actionButtons
        }
        .padding(24)
        .background(ColorTheme.cardBackground)
        .cornerRadius(16)
        .onAppear {
            permissionManager.updateAllPermissionStates()
        }
        .onChange(of: permissionManager.notificationStatus) { _, status in
            onPermissionResult(status.isGranted)
        }
    }
    
    private var reminderBenefitsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Helpful reminders for:")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                reminderBenefit("🍽️", "Meal logging", "Never miss tracking a meal")
                reminderBenefit("📝", "Symptom tracking", "Record symptoms when they occur")
                reminderBenefit("📊", "Weekly summaries", "Review your health patterns")
                reminderBenefit("💊", "Medication reminders", "If you take digestive supplements")
            }
        }
        .padding(16)
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
    
    private func reminderBenefit(_ icon: String, _ title: String, _ description: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
        }
    }
    
    private var notificationStatusCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: permissionManager.notificationStatus.statusIcon)
                    .foregroundColor(permissionManager.notificationStatus.statusColor)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Permission")
                        .font(.subheadline.bold())
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text(permissionManager.notificationStatus.statusText)
                        .font(.caption)
                        .foregroundColor(permissionManager.notificationStatus.statusColor)
                }
                
                Spacer()
            }
            
            if permissionManager.notificationStatus == .denied {
                VStack(alignment: .leading, spacing: 8) {
                    Text("To enable notifications:")
                        .font(.caption.bold())
                        .foregroundColor(ColorTheme.primaryText)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. Open Settings → Notifications")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.secondaryText)
                        Text("2. Find 'GutCheck' and tap it")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.secondaryText)
                        Text("3. Turn on 'Allow Notifications'")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(permissionManager.notificationStatus.statusColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if permissionManager.notificationStatus.needsRequest {
                Button(action: {
                    requestNotificationPermission()
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Enable Notifications")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.primary)
                .cornerRadius(12)
                .disabled(isRequesting)
                
                Button("Maybe Later") {
                    onPermissionResult(false)
                }
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
                
            } else if permissionManager.notificationStatus.canOpenSettings {
                Button("Open Settings") {
                    permissionManager.openAppSettings()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.primary)
                .cornerRadius(12)
                
                Button("Continue Without Notifications") {
                    onPermissionResult(false)
                }
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
                
            } else if permissionManager.notificationStatus.isGranted {
                Button("Continue") {
                    onPermissionResult(true)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.success)
                .cornerRadius(12)
            }
        }
    }
    
    private func requestNotificationPermission() {
        isRequesting = true
        
        Task {
            let granted = await permissionManager.requestNotificationPermission()
            
            await MainActor.run {
                self.isRequesting = false
                self.onPermissionResult(granted)
            }
        }
    }
}

// MARK: - Specialized Notification Views

struct ReminderSetupNotificationView: View {
    let onPermissionResult: (Bool) -> Void
    
    var body: some View {
        NotificationPermissionView(
            title: "Set Up Meal Reminders",
            message: "Allow notifications to receive personalized reminders for logging meals and symptoms at your preferred times.",
            onPermissionResult: onPermissionResult
        )
    }
}

struct OnboardingNotificationView: View {
    let onPermissionResult: (Bool) -> Void
    
    var body: some View {
        NotificationPermissionView(
            title: "Stay Consistent with Reminders",
            message: "Consistent tracking leads to better insights. Let us send gentle reminders to help you build healthy habits.",
            onPermissionResult: onPermissionResult
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        NotificationPermissionView { granted in
            print("Permission result: \(granted)")
        }
        
        ReminderSetupNotificationView { granted in
            print("Reminder permission: \(granted)")
        }
    }
    .padding()
    .background(ColorTheme.background)
}

