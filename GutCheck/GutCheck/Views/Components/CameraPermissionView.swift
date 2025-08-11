//
//  CameraPermissionView.swift
//  GutCheck
//
//  Reusable camera permission request component
//

import SwiftUI

struct CameraPermissionView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var isRequesting = false
    
    let title: String
    let message: String
    let onPermissionGranted: () -> Void
    
    init(
        title: String = "Camera Access Needed",
        message: String = "GutCheck needs camera access to scan barcodes and estimate portion sizes.",
        onPermissionGranted: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.onPermissionGranted = onPermissionGranted
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon and title
            VStack(spacing: 16) {
                Image(systemName: "camera.metering.none")
                    .font(.system(size: 72))
                    .foregroundColor(ColorTheme.secondaryText)
                
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.secondaryText)
                    .lineLimit(nil)
            }
            
            // Permission status
            permissionStatusCard
            
            // Action buttons
            actionButtons
        }
        .padding(24)
        .background(ColorTheme.cardBackground)
        .cornerRadius(16)
        .onAppear {
            permissionManager.updateAllPermissionStates()
        }
        .onChange(of: permissionManager.cameraStatus) { _, status in
            if status.isGranted {
                onPermissionGranted()
            }
        }
    }
    
    private var permissionStatusCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: permissionManager.cameraStatus.statusIcon)
                    .foregroundColor(permissionManager.cameraStatus.statusColor)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Camera Permission")
                        .font(.subheadline.bold())
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text(permissionManager.cameraStatus.statusText)
                        .font(.caption)
                        .foregroundColor(permissionManager.cameraStatus.statusColor)
                }
                
                Spacer()
            }
            
            if permissionManager.cameraStatus == .denied || permissionManager.cameraStatus == .restricted {
                VStack(alignment: .leading, spacing: 8) {
                    Text("To enable camera access:")
                        .font(.caption.bold())
                        .foregroundColor(ColorTheme.primaryText)
                    
                    HStack(spacing: 8) {
                        Text("1.")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.secondaryText)
                        Text("Open Settings app")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    
                    HStack(spacing: 8) {
                        Text("2.")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.secondaryText)
                        Text("Find 'GutCheck' in the app list")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    
                    HStack(spacing: 8) {
                        Text("3.")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.secondaryText)
                        Text("Enable 'Camera' permission")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(permissionManager.cameraStatus.statusColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if permissionManager.cameraStatus.needsRequest {
                Button(action: {
                    requestCameraPermission()
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Allow Camera Access")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.primary)
                .cornerRadius(12)
                .disabled(isRequesting)
            } else if permissionManager.cameraStatus.canOpenSettings {
                Button("Open Settings") {
                    permissionManager.openAppSettings()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.primary)
                .cornerRadius(12)
            } else if permissionManager.cameraStatus.isGranted {
                Button("Continue") {
                    onPermissionGranted()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.success)
                .cornerRadius(12)
            }
            
            // Additional info button
            Button("Why do we need camera access?") {
                // Could show an info sheet or modal
            }
            .font(.caption)
            .foregroundColor(ColorTheme.primary)
        }
    }
    
    private func requestCameraPermission() {
        isRequesting = true
        
        Task {
            let granted = await permissionManager.requestCameraPermission()
            
            await MainActor.run {
                self.isRequesting = false
                if granted {
                    self.onPermissionGranted()
                }
            }
        }
    }
}

// MARK: - Specialized Camera Permission Views

struct BarcodeCameraPermissionView: View {
    let onPermissionGranted: () -> Void
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        CameraPermissionView(
            title: "Enable Barcode Scanning",
            message: "Allow camera access to scan food barcodes and get instant nutrition information for accurate meal logging."
        ) {
            // Use the centralized permission system
            Task {
                let granted = await permissionManager.requestCameraPermission()
                if granted {
                    await MainActor.run {
                        onPermissionGranted()
                    }
                }
            }
        }
    }
}

struct LiDARCameraPermissionView: View {
    let onPermissionGranted: () -> Void
    
    var body: some View {
        CameraPermissionView(
            title: "Enable Portion Estimation",
            message: "Allow camera access to use advanced LiDAR technology for accurate portion size estimation and better nutrition tracking.",
            onPermissionGranted: onPermissionGranted
        )
    }
}

struct SmartScanCameraPermissionView: View {
    let onPermissionGranted: () -> Void
    
    var body: some View {
        CameraPermissionView(
            title: "Enable Smart Scanning",
            message: "Allow camera access to use both barcode scanning and LiDAR portion estimation for comprehensive meal logging.",
            onPermissionGranted: onPermissionGranted
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        CameraPermissionView {
            print("Permission granted!")
        }
        
        BarcodeCameraPermissionView {
            print("Barcode permission granted!")
        }
    }
    .padding()
    .background(ColorTheme.background)
}
