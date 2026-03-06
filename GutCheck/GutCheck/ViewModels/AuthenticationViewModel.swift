//
//  AuthenticationViewModel.swift
//  GutCheck
//
//  Created by Mark Conley on 7/11/25.
//

import Foundation
import SwiftUI
import AuthenticationServices

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var phoneNumber = ""
    @Published var verificationCode = ""
    
    @Published var isShowingSignUp = false
    @Published var isShowingForgotPassword = false
    @Published var isShowingPhoneAuth = false
    @Published var showingSuccessAlert = false
    @Published var successMessage = ""
    
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    // MARK: - Computed Properties
    
    var isSignInValid: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail(email)
    }
    
    var isSignUpValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        isValidEmail(email)
    }
    
    var isForgotPasswordValid: Bool {
        !email.isEmpty && isValidEmail(email)
    }
    
    var isPhoneNumberValid: Bool {
        !phoneNumber.isEmpty && isValidPhoneNumber(phoneNumber)
    }
    
    var isVerificationCodeValid: Bool {
        verificationCode.count == 6
    }
    
    var passwordStrength: PasswordStrength {
        return getPasswordStrength(password)
    }
    
    // MARK: - Actions
    
    func signIn() async {
        guard isSignInValid else { return }
        
        do {
            try await authService.signIn(email: email, password: password)
            clearForm()
        } catch {
            // Error is handled by AuthService
        }
    }
    
    func signUp() async {
        guard isSignUpValid else { return }
        
        do {
            try await authService.signUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            clearForm()
        } catch {
            // Error is handled by AuthService
        }
    }
    
    func forgotPassword() async {
        guard isForgotPasswordValid else { return }
        
        do {
            try await authService.sendPasswordReset(email: email)
            successMessage = "Password reset email sent to \(email)"
            showingSuccessAlert = true
            isShowingForgotPassword = false
        } catch {
            // Error is handled by AuthService
        }
    }
    
    func signInWithApple(_ authorization: ASAuthorization) async {
        do {
            try await authService.signInWithApple(authorization)
            clearForm()
        } catch {
            // Error is handled by AuthService
        }
    }
    
    func sendPhoneVerification() async {
        guard isPhoneNumberValid else { return }
        
        do {
            try await authService.sendPhoneVerification(phoneNumber: formatPhoneNumber(phoneNumber))
            successMessage = "Verification code sent to \(phoneNumber)"
            showingSuccessAlert = true
        } catch {
            // Error is handled by AuthService
        }
    }
    
    func verifyPhoneCode() async {
        guard isVerificationCodeValid else { return }
        
        do {
            try await authService.verifyPhoneCode(verificationCode, firstName: firstName, lastName: lastName)
            clearForm()
        } catch {
            // Error is handled by AuthService
        }
    }
    
    func resendVerificationEmail() async {
        do {
            try await authService.resendVerificationEmail()
        } catch {
            // Error is handled by AuthService
        }
    }
    
    func checkEmailVerification() async {
        do {
            try await authService.checkEmailVerification()
        } catch {
            // Error is handled by AuthService
        }
    }
    
    func cancelEmailVerification() {
        do {
            try authService.cancelEmailVerification()
        } catch {
            // Error is handled by AuthService
        }
    }
    
    func toggleAuthMode() {
        isShowingSignUp.toggle()
        clearForm()
    }
    
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        firstName = ""
        lastName = ""
        phoneNumber = ""
        verificationCode = ""
    }
    
    // MARK: - Validation Helpers
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        // Accept 10 digits (US) or 11 digits starting with 1 (US with country code)
        return cleaned.count == 10 || (cleaned.count == 11 && cleaned.hasPrefix("1"))
    }
    
    private func formatPhoneNumber(_ phone: String) -> String {
        var digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        // Normalize to 10 digits without country code
        if digits.count == 11 && digits.hasPrefix("1") {
            digits = String(digits.dropFirst())
        }
        return "+1\(digits)"
    }
    
    private func getPasswordStrength(_ password: String) -> PasswordStrength {
        let length = password.count
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasDigits = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecialChars = password.rangeOfCharacter(from: .punctuationCharacters) != nil ||
                             password.rangeOfCharacter(from: .symbols) != nil
        
        var score = 0
        if length >= 8 { score += 1 }
        if hasLowercase { score += 1 }
        if hasUppercase { score += 1 }
        if hasDigits { score += 1 }
        if hasSpecialChars { score += 1 }
        
        switch score {
        case 0...1:
            return .weak
        case 2...3:
            return .medium
        case 4...5:
            return .strong
        default:
            return .weak
        }
    }
}

// MARK: - Password Strength

enum PasswordStrength {
    case weak
    case medium
    case strong
    
    var color: Color {
        switch self {
        case .weak:
            return ColorTheme.error
        case .medium:
            return ColorTheme.warning
        case .strong:
            return ColorTheme.success
        }
    }
    
    var text: String {
        switch self {
        case .weak:
            return "Weak"
        case .medium:
            return "Medium"
        case .strong:
            return "Strong"
        }
    }
    
    var progress: Double {
        switch self {
        case .weak:
            return 0.33
        case .medium:
            return 0.66
        case .strong:
            return 1.0
        }
    }
}
