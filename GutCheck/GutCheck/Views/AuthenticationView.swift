//
//  AuthenticationView.swift
//  GutCheck
//
//  Created by Mark Conley on 7/11/25.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel: AuthenticationViewModel
    @ObservedObject private var authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
        self._viewModel = StateObject(wrappedValue: AuthenticationViewModel(authService: authService))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    headerSection
                    
                    // Form
                    if viewModel.isShowingSignUp {
                        signUpForm
                    } else {
                        signInForm
                    }
                    
                    // Toggle Auth Mode
                    authToggleSection
                }
                .padding(.horizontal, 24)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(ColorTheme.background)
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
        .sheet(isPresented: $viewModel.isShowingForgotPassword) {
            forgotPasswordSheet
        }
        .sheet(isPresented: $viewModel.isShowingPhoneAuth) {
            PhoneAuthView(authService: authService)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon/Logo placeholder
            Circle()
                .fill(ColorTheme.primary)
                .frame(width: 80, height: 80)
                .overlay(
                    Text("🍽️")
                        .font(.system(size: 40))
                )
            
            VStack(spacing: 8) {
                Text("GutCheck")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.text)
                
                Text(viewModel.isShowingSignUp ? "Create your account" : "Welcome back")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
            }
        }
        .padding(.top, 40)
    }
    
    // MARK: - Sign In Form
    
    private var signInForm: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                CustomTextField(
                    title: "Email",
                    text: $viewModel.email,
                    keyboardType: .emailAddress
                )
                
                CustomTextField(
                    title: "Password",
                    text: $viewModel.password,
                    isSecure: true
                )
            }
            
            // Forgot Password
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    viewModel.isShowingForgotPassword = true
                }
                .font(.footnote)
                .foregroundColor(ColorTheme.primary)
            }
            
            // Sign In Button
            CustomButton(
                title: "Sign In",
                action: {
                    Task { await viewModel.signIn() }
                }
            )
            .loading(authService.isLoading)
            .disabled(!viewModel.isSignInValid)
        }
    }
    
    // MARK: - Sign Up Form
    
    private var signUpForm: some View {
        VStack(spacing: 20) {
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
                    title: "Email",
                    text: $viewModel.email,
                    keyboardType: .emailAddress
                )
                
                CustomTextField(
                    title: "Password",
                    text: $viewModel.password,
                    isSecure: true
                )
                
                // Password Strength Indicator
                if !viewModel.password.isEmpty {
                    passwordStrengthIndicator
                }
                
                CustomTextField(
                    title: "Confirm Password",
                    text: $viewModel.confirmPassword,
                    isSecure: true
                )
                
                // Password Match Indicator
                if !viewModel.confirmPassword.isEmpty {
                    passwordMatchIndicator
                }
            }
            
            // Sign Up Button
            CustomButton(
                title: "Create Account",
                action: {
                    Task { await viewModel.signUp() }
                }
            )
            .loading(authService.isLoading)
            .disabled(!viewModel.isSignUpValid)
        }
    }
    
    // MARK: - Password Strength Indicator
    
    private var passwordStrengthIndicator: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Password Strength:")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
                
                Text(viewModel.passwordStrength.text)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.passwordStrength.color)
                
                Spacer()
            }
            
            ProgressView(value: viewModel.passwordStrength.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: viewModel.passwordStrength.color))
                .scaleEffect(x: 1, y: 0.5)
        }
    }
    
    // MARK: - Password Match Indicator
    
    private var passwordMatchIndicator: some View {
        HStack {
            Image(systemName: viewModel.password == viewModel.confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(viewModel.password == viewModel.confirmPassword ? ColorTheme.success : ColorTheme.error)
            
            Text(viewModel.password == viewModel.confirmPassword ? "Passwords match" : "Passwords don't match")
                .font(.caption)
                .foregroundColor(viewModel.password == viewModel.confirmPassword ? ColorTheme.success : ColorTheme.error)
            
            Spacer()
        }
    }
    
    // MARK: - Auth Toggle Section
    
    private var authToggleSection: some View {
        VStack(spacing: 20) {
            // Social Sign-In Options
            socialSignInSection
            
            // Divider
            HStack {
                Rectangle()
                    .fill(ColorTheme.secondaryText.opacity(0.3))
                    .frame(height: 1)
                
                Text("or")
                    .font(.footnote)
                    .foregroundColor(ColorTheme.secondaryText)
                
                Rectangle()
                    .fill(ColorTheme.secondaryText.opacity(0.3))
                    .frame(height: 1)
            }
            
            Button(action: viewModel.toggleAuthMode) {
                Text(viewModel.isShowingSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.footnote)
                    .foregroundColor(ColorTheme.primary)
            }
        }
    }
    
    // MARK: - Social Sign-In Section
    
    private var socialSignInSection: some View {
        VStack(spacing: 12) {
            // Apple Sign-In uses the official Apple button
            AppleSignInButtonView(
                onRequest: { request in
                    // Set up the request
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        Task { 
                            await viewModel.signInWithApple(authorization)
                        }
                    case .failure(let error):
                        // Propagate error to view model
                        viewModel.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                        viewModel.showingErrorAlert = true
                    }
                }
            )
            .frame(height: 50)
            
            SocialSignInButton(
                provider: .phone,
                action: {
                    viewModel.isShowingPhoneAuth = true
                },
                isLoading: authService.isLoading
            )
        }
    }
    
    // MARK: - Forgot Password Sheet
    
    private var forgotPasswordSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.text)
                    
                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                CustomTextField(
                    title: "Email",
                    text: $viewModel.email,
                    keyboardType: .emailAddress
                )
                
                CustomButton(
                    title: "Send Reset Link",
                    action: {
                        Task { await viewModel.forgotPassword() }
                    }
                )
                .loading(authService.isLoading)
                .disabled(!viewModel.isForgotPasswordValid)
                
                Spacer()
            }
            .padding(24)
            .background(ColorTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.isShowingForgotPassword = false
                    }
                    .foregroundColor(ColorTheme.primary)
                }
            }
        }
    }
}

#Preview {
    AuthenticationView(authService: AuthService())
}
