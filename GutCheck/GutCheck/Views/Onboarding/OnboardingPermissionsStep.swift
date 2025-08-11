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
                    .foregroundColor(ColorTheme.primary)
                
                Text("Privacy & Permissions")
                    .font(.largeTitle.bold())
                    .foregroundColor(ColorTheme.primaryText)
                
                Text("GutCheck respects your privacy and only requests permissions for features you choose to use.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
            
            // Permission overview
            VStack(spacing: 16) {
                Text("We may ask for access to:")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.primary)
                .cornerRadius(12)
                
                Button("Skip for Now") {
                    currentStep += 1
                }
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
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
                        .foregroundColor(ColorTheme.primary)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
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
                    .foregroundColor(ColorTheme.success)
                
                Text("Your privacy is protected")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
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
                .foregroundColor(ColorTheme.success)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingPermissionsStep(currentStep: .constant(0))
}

