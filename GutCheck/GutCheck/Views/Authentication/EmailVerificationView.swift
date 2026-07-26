//
//  EmailVerificationView.swift
//  GutCheck
//
//  Created by Mark Conley on 3/6/26.
//

import SwiftUI

struct EmailVerificationView: View {
    var authService: AuthService
    @State private var showResendSuccess = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: "envelope.badge")
                .font(.system(size: 60))
                .foregroundStyle(ColorTheme.primary)
            
            // Title
            VStack(spacing: 12) {
                Text("Verify Your Email")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(ColorTheme.text)
                
                Text("We sent a verification link to your email address. Please check your inbox and tap the link to continue.")
                    .font(.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Buttons
            VStack(spacing: 16) {
                CustomButton(
                    title: "I've Verified My Email",
                    action: {
                        Task {
                            do {
                                try await authService.checkEmailVerification()
                            } catch {
                                // Error displayed via authService.errorMessage
                            }
                        }
                    }
                )
                .loading(authService.isLoading)
                
                CustomButton(
                    title: "Resend Verification Email",
                    action: {
                        Task {
                            do {
                                try await authService.resendVerificationEmail()
                                showResendSuccess = true
                            } catch {
                                // Error displayed via authService.errorMessage
                            }
                        }
                    },
                    style: .outline
                )
                .loading(authService.isLoading)
                
                Button {
                    try? authService.cancelEmailVerification()
                } label: {
                    Text("Back to Sign In")
                        .font(.footnote)
                        .foregroundStyle(ColorTheme.primary)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(ColorTheme.background)
        .alert("Success", isPresented: $showResendSuccess) {
            Button("OK") { }
        } message: {
            Text("Verification email sent. Please check your inbox.")
        }
        .alert("Error", isPresented: .constant(authService.errorMessage != nil)) {
            Button("OK") {
                authService.errorMessage = nil
            }
        } message: {
            if let errorMessage = authService.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    EmailVerificationView(authService: AuthService())
}
