//
//  PermissionStatus+Display.swift
//  GutCheck
//
//  Display helpers for PermissionManager.PermissionStatus.
//
//  These lived at the bottom of PermissionRequestView.swift, a view nothing
//  presented. Deleting that file broke CameraPermissionView and
//  NotificationPermissionView, which both read `statusColor` — the view was
//  dead but these extensions were not. Moved here so they no longer depend on
//  an unrelated screen surviving.
//

import SwiftUI

extension PermissionManager.PermissionStatus {
    var statusIcon: String {
        switch self {
        case .notDetermined: return "circle"
        case .requesting: return "arrow.clockwise"
        case .granted, .limited: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .restricted: return "exclamationmark.triangle.fill"
        }
    }

    var statusColor: Color {
        switch self {
        case .notDetermined: return ColorTheme.secondaryText
        case .requesting: return ColorTheme.primary
        case .granted, .limited: return ColorTheme.success
        case .denied: return ColorTheme.error
        case .restricted: return ColorTheme.warning
        }
    }

    var statusText: String {
        switch self {
        case .notDetermined: return "Not requested"
        case .requesting: return "Requesting..."
        case .granted: return "Granted"
        case .limited: return "Limited access"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        }
    }
}
