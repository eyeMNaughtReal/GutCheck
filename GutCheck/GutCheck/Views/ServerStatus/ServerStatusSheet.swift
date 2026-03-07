//
//  ServerStatusSheet.swift
//  GutCheck
//
//  Half-sheet / full-sheet showing server status details, recheck countdown,
//  and lists of working vs. limited features.
//

import SwiftUI

struct ServerStatusSheet: View {
    @EnvironmentObject private var serverStatus: ServerStatusService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Recheck countdown pill
                    HStack {
                        Spacer()
                        recheckCountdownPill
                        Spacer()
                    }

                    // Warning badges
                    warningBadges

                    // What's happening
                    whatsHappeningSection

                    // What still works
                    whatStillWorksSection

                    // Temporarily limited
                    temporarilyLimitedSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(ColorTheme.background)
            .navigationTitle("Server Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: "icloud.slash")
                        .foregroundColor(ColorTheme.warning)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    .accessibilityId(AccessibilityIdentifiers.ServerStatus.dismissButton)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onChange(of: serverStatus.isOffline) { _, isOffline in
            if !isOffline {
                dismiss()
            }
        }
    }

    // MARK: - Recheck Countdown Pill

    private var recheckCountdownPill: some View {
        HStack(spacing: 6) {
            if serverStatus.isRechecking {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.7)
                Text("Checking...")
                    .font(.caption)
                    .fontWeight(.medium)
            } else {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                Text("Rechecking in \(serverStatus.secondsUntilRecheck)s")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Capsule().fill(ColorTheme.warning))
        .accessibilityId(AccessibilityIdentifiers.ServerStatus.recheckCountdown)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            serverStatus.isRechecking
                ? "Checking server connectivity"
                : "Rechecking server in \(serverStatus.secondsUntilRecheck) seconds"
        )
    }

    // MARK: - Warning Badges

    private var warningBadges: some View {
        VStack(spacing: 8) {
            if !serverStatus.isNetworkAvailable {
                warningBadge("No internet connection")
            }
            if !serverStatus.isFirebaseReachable && serverStatus.isNetworkAvailable {
                warningBadge("Firebase is experiencing issues")
            }
            if serverStatus.isDebugOfflineMode {
                warningBadge("Simulated server outage (debug)")
            }
        }
    }

    private func warningBadge(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(ColorTheme.warning)
            Text(message)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.warning)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ColorTheme.warning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorTheme.warning.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - What's Happening

    private var whatsHappeningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's happening")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)

            ServerStatusRow(
                icon: "exclamationmark.triangle.fill",
                iconColor: ColorTheme.warning,
                title: "Services degraded",
                subtitle: serverStatus.isNetworkAvailable
                    ? "Firebase servers are unreachable"
                    : "No internet connection detected"
            )

            ServerStatusRow(
                icon: "lock.shield.fill",
                iconColor: ColorTheme.success,
                title: "Your data is safe",
                subtitle: "All entries are stored locally on this device"
            )

            ServerStatusRow(
                icon: "arrow.triangle.2.circlepath",
                iconColor: ColorTheme.info,
                title: "Automatic sync",
                subtitle: "Any changes you make will sync automatically when servers return"
            )

            ServerStatusRow(
                icon: "clock.fill",
                iconColor: ColorTheme.warning,
                title: "Pending changes",
                subtitle: "\(serverStatus.pendingChangesCount) item\(serverStatus.pendingChangesCount == 1 ? "" : "s") waiting to sync"
            )
        }
        .accessibilityId(AccessibilityIdentifiers.ServerStatus.whatsHappeningSection)
    }

    // MARK: - What Still Works

    private var whatStillWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What still works")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)

            ServerStatusRow(
                icon: "checkmark.circle.fill",
                iconColor: ColorTheme.success,
                title: "Logging food"
            )

            ServerStatusRow(
                icon: "checkmark.circle.fill",
                iconColor: ColorTheme.success,
                title: "Viewing your journal"
            )

            ServerStatusRow(
                icon: "checkmark.circle.fill",
                iconColor: ColorTheme.success,
                title: "Tracking daily totals"
            )

            ServerStatusRow(
                icon: "checkmark.circle.fill",
                iconColor: ColorTheme.success,
                title: "Saving meals"
            )
        }
        .accessibilityId(AccessibilityIdentifiers.ServerStatus.whatStillWorksSection)
    }

    // MARK: - Temporarily Limited

    private var temporarilyLimitedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Temporarily limited")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)

            ServerStatusRow(
                icon: "exclamationmark.triangle.fill",
                iconColor: ColorTheme.warning,
                title: "AI food analysis"
            )

            ServerStatusRow(
                icon: "exclamationmark.triangle.fill",
                iconColor: ColorTheme.warning,
                title: "Cross-device sync"
            )
        }
        .accessibilityId(AccessibilityIdentifiers.ServerStatus.temporarilyLimitedSection)
    }
}

// MARK: - Preview

#Preview {
    ServerStatusSheet()
        .environmentObject(ServerStatusService.shared)
}
