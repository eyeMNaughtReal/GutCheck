//
//  OnboardingPermissionsStep.swift
//  GutCheck
//
//  Permission request step for onboarding flow
//

import SwiftUI

struct OnboardingPermissionsStep: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @Binding var currentStep: Int
    
    @State private var isRequestingPermissions = false
    @State private var showingPermissionRequest = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 64))
                    .foregroundStyle(ColorTheme.primary)
                
                Text("Privacy & Permissions")
                    .font(.largeTitle.bold())
                    .foregroundStyle(ColorTheme.primaryText)
                
                Text("GutCheck respects your privacy and only requests permissions for features you choose to use.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ColorTheme.secondaryText)
            }
            
            Spacer()
            
            // Permission overview
            VStack(spacing: 16) {
                Text("We may ask for access to:")
                    .font(.headline)
                    .foregroundStyle(ColorTheme.primaryText)
                
                permissionOverviewList
            }
            
            Spacer()
            
            // Privacy commitment
            privacyCommitmentView
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button("Set Up Permissions") {
                    showingPermissionRequest = true
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.primary)
                .cornerRadius(12)
                
                Button("Skip for Now") {
                    currentStep += 1
                }
                .font(.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(ColorTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showingPermissionRequest) {
            PermissionRequestView()
        }
    }
    
    private var permissionOverviewList: some View {
        VStack(spacing: 12) {
            ForEach([
                ("camera", "Camera", "For barcode scanning and portion estimation"),
                ("bell", "Notifications", "For helpful reminders (optional)"),
                ("heart.text.square", "Health Data", "To sync with Apple Health (optional)"),
                ("photo", "Photo Library", "To save meal photos (optional)")
            ], id: \.0) { icon, title, description in
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(ColorTheme.primary)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundStyle(ColorTheme.primaryText)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }
    
    private var privacyCommitmentView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(ColorTheme.success)
                
                Text("Your privacy is protected")
                    .font(.headline)
                    .foregroundStyle(ColorTheme.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                privacyPoint("Data stays on your device", "Your health data is stored locally and encrypted")
                privacyPoint("No data selling", "We never sell or share your personal information")
                privacyPoint("You control sharing", "Choose what to sync with Apple Health")
                privacyPoint("Easy to revoke", "Change permissions anytime in Settings")
            }
        }
        .padding(16)
        .background(ColorTheme.success.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func privacyPoint(_ title: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(ColorTheme.success)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(ColorTheme.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingPermissionsStep(currentStep: .constant(0))
}

