//
//  OfflineBannerView.swift
//  GutCheck
//
//  Tappable orange "Offline" pill that appears at the top of the app
//  when Firebase is unreachable. Opens the ServerStatusSheet on tap.
//

import SwiftUI

struct OfflineBannerView: View {
    @Environment(ServerStatusService.self) private var serverStatus
    @Binding var showingStatusSheet: Bool

    var body: some View {
        if serverStatus.isOffline {
            Button {
                HapticManager.shared.medium()
                showingStatusSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "icloud.slash")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Offline")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(ColorTheme.warning)
                )
            }
            .accessibilityId(AccessibilityIdentifiers.ServerStatus.offlineBanner)
            .accessibilityLabel("Offline status")
            .accessibilityHint("Tap to view server status details")
            .transition(.move(edge: .top).combined(with: .opacity))
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
    }
}
