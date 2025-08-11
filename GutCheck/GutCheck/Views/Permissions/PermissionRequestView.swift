//
//  PermissionRequestView.swift
//  GutCheck
//
//  Apple-compliant permission request interface for iOS 18.5+
//

import SwiftUI

struct PermissionRequestView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var isRequestingPermissions = false
    @State private var showingSettings = false
    
    // Define permission flow steps
    private let permissionSteps: [PermissionManager.PermissionType] = [.camera, .notifications]
    private let optionalSteps: [PermissionManager.PermissionType] = [.healthKit, .photoLibrary]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        if currentStep < permissionSteps.count {
                            // Core permissions
                            corePermissionView(permissionSteps[currentStep])
                        } else if currentStep < permissionSteps.count + optionalSteps.count {
                            // Optional permissions
                            let optionalIndex = currentStep - permissionSteps.count
                            optionalPermissionView(optionalSteps[optionalIndex])
                        } else {
                            // Completion view
                            completionView
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }
                
                bottomActionView
            }
            .background(ColorTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .onAppear {
            permissionManager.updateAllPermissionStates()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button("Skip") {
                    skipToEnd()
                }
                .font(.subheadline)
                .foregroundColor(ColorTheme.primary)
            }
            
            // Progress indicator
            ProgressView(value: Double(currentStep), total: Double(permissionSteps.count + optionalSteps.count))
                .progressViewStyle(LinearProgressViewStyle(tint: ColorTheme.primary))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Core Permission View
    private func corePermissionView(_ permissionType: PermissionManager.PermissionType) -> some View {
        return VStack(spacing: 32) {
            // Icon and title
            VStack(spacing: 16) {
                Image(systemName: permissionType.icon)
                    .font(.system(size: 64))
                    .foregroundColor(ColorTheme.primary)
                
                Text(permissionType.title)
                    .font(.largeTitle.bold())
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(permissionType.description)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.secondaryText)
                    .lineLimit(nil)
            }
            
            // Why this permission is needed
            permissionBenefitsView(permissionType)
            
            // Status indicator
            permissionStatusView(permissionType)
        }
    }
    
    // MARK: - Optional Permission View
    private func optionalPermissionView(_ permissionType: PermissionManager.PermissionType) -> some View {
        return VStack(spacing: 32) {
            // Icon and title
            VStack(spacing: 12) {
                Image(systemName: permissionType.icon)
                    .font(.system(size: 64))
                    .foregroundColor(ColorTheme.primary)
                
                VStack(spacing: 8) {
                    Text(permissionType.title)
                        .font(.largeTitle.bold())
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Optional")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(ColorTheme.surface)
                        .cornerRadius(8)
                }
                
                Text(permissionType.description)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.secondaryText)
                    .lineLimit(nil)
            }
            
            // Benefits for optional features
            permissionBenefitsView(permissionType)
            
            // Status indicator
            permissionStatusView(permissionType)
        }
    }
    
    // MARK: - Permission Benefits
    private func permissionBenefitsView(_ permissionType: PermissionManager.PermissionType) -> some View {
        return VStack(alignment: .leading, spacing: 12) {
            Text("This helps you:")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(getBenefits(for: permissionType), id: \.self) { benefit in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ColorTheme.success)
                            .font(.system(size: 16))
                        
                        Text(benefit)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Permission Status View
    private func permissionStatusView(_ permissionType: PermissionManager.PermissionType) -> some View {
        let status = permissionManager.getPermissionStatus(permissionType)
        
        return HStack(spacing: 12) {
            Image(systemName: status.statusIcon)
                .foregroundColor(status.statusColor)
                .font(.system(size: 16))
            
            Text(status.statusText)
                .font(.subheadline)
                .foregroundColor(status.statusColor)
            
            Spacer()
            
            if status.canOpenSettings {
                Button("Open Settings") {
                    permissionManager.openAppSettings()
                }
                .font(.caption)
                .foregroundColor(ColorTheme.primary)
            }
        }
        .padding(12)
        .background(status.statusColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(ColorTheme.success)
            
            VStack(spacing: 16) {
                Text("All Set!")
                    .font(.largeTitle.bold())
                    .foregroundColor(ColorTheme.primaryText)
                
                Text("GutCheck is ready to help you track your digestive health with personalized insights.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            // Summary of enabled permissions
            permissionSummaryView
        }
    }
    
    private var permissionSummaryView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enabled Features:")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            ForEach(PermissionManager.PermissionType.allCases, id: \.self) { type in
                if permissionManager.isPermissionGranted(type) {
                    HStack(spacing: 12) {
                        Image(systemName: type.icon)
                            .foregroundColor(ColorTheme.success)
                            .frame(width: 20)
                        
                        Text(type.title)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Bottom Action View
    private var bottomActionView: some View {
        VStack(spacing: 16) {
            if currentStep < permissionSteps.count + optionalSteps.count {
                // Permission request buttons
                let permissionType = getCurrentPermissionType()
                let status = permissionManager.getPermissionStatus(permissionType)
                
                if status.needsRequest {
                    Button(action: {
                        requestCurrentPermission()
                    }) {
                        HStack {
                            if isRequestingPermissions {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(permissionType.isRequired ? "Allow \(permissionType.title)" : "Enable \(permissionType.title)")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary)
                    .cornerRadius(12)
                    .disabled(isRequestingPermissions)
                    
                    if !permissionType.isRequired {
                        Button("Maybe Later") {
                            nextStep()
                        }
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                    }
                } else {
                    Button("Continue") {
                        nextStep()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary)
                    .cornerRadius(12)
                }
            } else {
                // Completion button
                Button("Get Started") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.primary)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentPermissionType() -> PermissionManager.PermissionType {
        if currentStep < permissionSteps.count {
            return permissionSteps[currentStep]
        } else {
            let optionalIndex = currentStep - permissionSteps.count
            return optionalSteps[optionalIndex]
        }
    }
    
    private func requestCurrentPermission() {
        let permissionType = getCurrentPermissionType()
        isRequestingPermissions = true
        
        Task {
            let granted = await requestPermission(permissionType)
            
            await MainActor.run {
                self.isRequestingPermissions = false
                if granted || !permissionType.isRequired {
                    self.nextStep()
                }
            }
        }
    }
    
    private func requestPermission(_ type: PermissionManager.PermissionType) async -> Bool {
        switch type {
        case .camera:
            return await permissionManager.requestCameraPermission()
        case .photoLibrary:
            return await permissionManager.requestPhotoLibraryPermission()
        case .notifications:
            return await permissionManager.requestNotificationPermission()
        case .healthKit:
            return await permissionManager.requestHealthKitPermission()
        case .location:
            return await permissionManager.requestLocationPermission()
        }
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }
    
    private func skipToEnd() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = permissionSteps.count + optionalSteps.count
        }
    }
    
    private func getBenefits(for permissionType: PermissionManager.PermissionType) -> [String] {
        switch permissionType {
        case .camera:
            return [
                "Quickly scan food barcodes for instant nutrition data",
                "Use LiDAR technology for accurate portion estimation",
                "Log meals faster with visual recognition"
            ]
        case .photoLibrary:
            return [
                "Save meal photos for visual food tracking",
                "Build a personal food diary with images",
                "Share progress with healthcare providers"
            ]
        case .notifications:
            return [
                "Never miss a meal or symptom log",
                "Get reminders at your preferred times",
                "Stay consistent with your health tracking"
            ]
        case .healthKit:
            return [
                "Sync data with Apple Health automatically",
                "Share comprehensive health data with doctors",
                "Combine nutrition data with other health metrics"
            ]
        case .location:
            return [
                "Get restaurant suggestions when dining out",
                "Track eating patterns by location",
                "Discover healthy options nearby"
            ]
        }
    }
}

// MARK: - Permission Status Extensions

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

// MARK: - Preview

#Preview {
    PermissionRequestView()
}

