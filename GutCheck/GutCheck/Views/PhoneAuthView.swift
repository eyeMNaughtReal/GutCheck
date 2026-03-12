//
//  PhoneAuthView.swift
//  GutCheck
//
//  Created by Mark Conley on 7/11/25.
//

import SwiftUI

struct PhoneAuthView: View {
    @StateObject private var viewModel: AuthenticationViewModel
    @ObservedObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    init(authService: AuthService) {
        self.authService = authService
        self._viewModel = StateObject(wrappedValue: AuthenticationViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if !authService.isPhoneVerificationInProgress {
                    phoneNumberSection
                } else {
                    verificationCodeSection
                }
                
                Spacer()
            }
            .padding(24)
            .background(ColorTheme.background)
            .navigationTitle("Phone Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ColorTheme.primary)
                }
            }
        }
        .alert("Success", isPresented: $viewModel.showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.successMessage)
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
    
    // MARK: - Phone Number Section
    
    private var phoneNumberSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Enter Phone Number")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(ColorTheme.text)
                
                Text("We'll send you a verification code to confirm your phone number.")
                    .font(.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                CustomTextField(
                    title: "Phone Number",
                    text: $viewModel.phoneNumber,
                    keyboardType: .phonePad
                )
                .onChange(of: viewModel.phoneNumber) { _, newValue in
                    // Format phone number as user types, avoiding re-entrant updates
                    let formatted = formatPhoneDisplay(newValue)
                    if formatted != newValue {
                        viewModel.phoneNumber = formatted
                    }
                }
                
                Text("Format: +1 (555) 123-4567")
                    .font(.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }
            
            CustomButton(
                title: "Send Verification Code",
                action: {
                    Task { await viewModel.sendPhoneVerification() }
                }
            )
            .loading(authService.isLoading)
            .disabled(!viewModel.isPhoneNumberValid)
        }
    }
    
    // MARK: - Verification Code Section
    
    private var verificationCodeSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Enter Verification Code")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(ColorTheme.text)
                
                Text("We sent a 6-digit code to \(viewModel.phoneNumber)")
                    .font(.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CustomTextField(
                        title: "First Name",
                        text: $viewModel.firstName
                    )
                    
                    CustomTextField(
                        title: "Last Name",
                        text: $viewModel.lastName
                    )
                }
                
                CustomTextField(
                    title: "Verification Code",
                    text: $viewModel.verificationCode,
                    keyboardType: .numberPad
                )
                .onChange(of: viewModel.verificationCode) { _, newValue in
                    // Limit to 6 digits
                    if newValue.count > 6 {
                        viewModel.verificationCode = String(newValue.prefix(6))
                    }
                }
            }
            
            VStack(spacing: 12) {
                CustomButton(
                    title: "Verify & Sign In",
                    action: {
                        Task { await viewModel.verifyPhoneCode() }
                    }
                )
                .loading(authService.isLoading)
                .disabled(!viewModel.isVerificationCodeValid || viewModel.firstName.isEmpty || viewModel.lastName.isEmpty)
                
                Button("Resend Code") {
                    Task { await viewModel.sendPhoneVerification() }
                }
                .font(.footnote)
                .foregroundStyle(ColorTheme.primary)
                .disabled(authService.isLoading)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatPhoneDisplay(_ phone: String) -> String {
        // Strip the +1 prefix we add, so we only work with the local digits
        var raw = phone
        if raw.hasPrefix("+1 ") {
            raw = String(raw.dropFirst(3))
        } else if raw.hasPrefix("+1") {
            raw = String(raw.dropFirst(2))
        }
        
        // Extract only digits
        let digits = String(raw.unicodeScalars.filter(CharacterSet.decimalDigits.contains).prefix(10))
        
        if digits.isEmpty {
            return ""
        }
        
        // Build formatted string: +1 (XXX) XXX-XXXX
        var result = "+1 ("
        for (i, d) in digits.enumerated() {
            if i == 3 { result += ") " }
            if i == 6 { result += "-" }
            result.append(d)
        }
        
        return result
    }
}

#Preview {
    PhoneAuthView(authService: AuthService())
}
