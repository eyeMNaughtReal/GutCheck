//
//  ReauthenticationView.swift
//  GutCheck
//
//  View for re-authenticating users before sensitive operations
//  such as account deletion or data export.
//
//  Created by Mark Conley on 8/18/25.
//

import SwiftUI
import FirebaseAuth

struct ReauthenticationView: View {
    let operation: String
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var password = ""
    @State private var showPhoneAuth = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    Text("Verify Your Identity")
                        .font(.title2.bold())
                    
                    Text("For security reasons, please verify your identity before \(operation.lowercased()).")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Authentication Form
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.password)
                    }
                }
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: verifyIdentity) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.shield")
                            }
                            Text("Verify Identity")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                    
                    Button("Use Phone Verification") {
                        showPhoneAuth = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Security Verification")
            .navigationBarTitleDisplayMode(.inline)
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showPhoneAuth) {
                PhoneReauthenticationView(
                    operation: operation,
                    onSuccess: onSuccess,
                    onCancel: onCancel
                )
            }
        }
    }
    
    private func verifyIdentity() {
        Task {
            do {
                try await authService.reauthenticateWithEmail(email: email, password: password)
                await MainActor.run {
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Verification Failed"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Phone Re-authentication View

struct PhoneReauthenticationView: View {
    let operation: String
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    @StateObject private var authService = AuthService()
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var codeSent = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "phone.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Phone Verification")
                        .font(.title2.bold())
                    
                    Text("Verify your identity using your phone number.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Phone Form
                VStack(spacing: 16) {
                    if !codeSent {
                        // Phone Number Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.headline)
                            
                            TextField("Enter phone number", text: $phoneNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                        }
                        
                        Button(action: sendVerificationCode) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "paperplane")
                                }
                                Text("Send Code")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authService.isLoading || phoneNumber.isEmpty)
                    } else {
                        // Verification Code Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Verification Code")
                                .font(.headline)
                            
                            TextField("Enter 6-digit code", text: $verificationCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.oneTimeCode)
                                .keyboardType(.numberPad)
                        }
                        
                        Button(action: verifyCode) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.shield")
                                }
                                Text("Verify Code")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authService.isLoading || verificationCode.isEmpty)
                        
                        Button("Resend Code") {
                            sendVerificationCode()
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Cancel Button
                Button("Cancel") {
                    onCancel()
                }
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Phone Verification")
            .navigationBarTitleDisplayMode(.inline)
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func sendVerificationCode() {
        Task {
            do {
                try await authService.sendPhoneVerification(phoneNumber: phoneNumber)
                await MainActor.run {
                    codeSent = true
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Failed to Send Code"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func verifyCode() {
        Task {
            do {
                try await authService.reauthenticateWithPhone(
                    phoneNumber: phoneNumber,
                    verificationCode: verificationCode
                )
                await MainActor.run {
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Verification Failed"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    ReauthenticationView(
        operation: "deleting your account",
        onSuccess: { print("Success") },
        onCancel: { print("Cancelled") }
    )
}
