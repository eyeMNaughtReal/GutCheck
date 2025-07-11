//
//  AuthService.swift
//  GutCheck
//
//  Created by Mark Conley on 7/11/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

@MainActor
class AuthService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var verificationId: String?
    @Published var isPhoneVerificationInProgress = false
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    
    // Apple Sign In
    private var currentNonce: String?
    
    // Auth state listener handle
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Listen for auth state changes
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    deinit {
        // Clean up auth state listener
        if let handle = authStateListenerHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            user = result.user
            isAuthenticated = true
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            user = result.user
            isAuthenticated = true
            
            // Create user profile in Firestore
            try await createUserProfile(userId: result.user.uid, email: email, firstName: firstName, lastName: lastName)
            
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try auth.signOut()
            user = nil
            isAuthenticated = false
            errorMessage = nil
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    func deleteAccount() async throws {
        guard let currentUser = user else {
            throw AuthError.noUser
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Delete user data from Firestore first
            try await deleteUserData(userId: currentUser.uid)
            
            // Delete the auth account
            try await currentUser.delete()
            
            user = nil
            isAuthenticated = false
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple(_ authorization: ASAuthorization) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    throw AuthError.invalidNonce
                }
                
                guard let appleIDToken = appleIDCredential.identityToken else {
                    throw AuthError.noIDToken
                }
                
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    throw AuthError.invalidIDToken
                }
                
                let credential = OAuthProvider.credential(
                    providerID: .apple,
                    idToken: idTokenString,
                    rawNonce: nonce
                )
                
                let authResult = try await auth.signIn(with: credential)
                self.user = authResult.user
                isAuthenticated = true
                
                // Extract name from Apple ID credential
                let firstName = appleIDCredential.fullName?.givenName ?? ""
                let lastName = appleIDCredential.fullName?.familyName ?? ""
                
                try await createOrUpdateUserProfile(
                    userId: authResult.user.uid,
                    email: authResult.user.email ?? appleIDCredential.email ?? "",
                    firstName: firstName,
                    lastName: lastName,
                    signInMethod: .apple
                )
            }
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }
    
    // MARK: - Phone Sign In
    
    func sendPhoneVerification(phoneNumber: String) async throws {
        isLoading = true
        isPhoneVerificationInProgress = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            self.verificationId = verificationID
        } catch {
            isPhoneVerificationInProgress = false
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    func verifyPhoneCode(_ verificationCode: String, firstName: String, lastName: String) async throws {
        guard let verificationId = verificationId else {
            throw AuthError.noVerificationID
        }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
            isPhoneVerificationInProgress = false
        }
        
        do {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationId,
                verificationCode: verificationCode
            )
            
            let authResult = try await auth.signIn(with: credential)
            self.user = authResult.user
            isAuthenticated = true
            
            try await createOrUpdateUserProfile(
                userId: authResult.user.uid,
                email: "",
                firstName: firstName,
                lastName: lastName,
                signInMethod: .phone
            )
            
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func createOrUpdateUserProfile(userId: String, email: String, firstName: String, lastName: String, signInMethod: SignInMethod) async throws {
        let userData: [String: Any] = [
            "id": userId,
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "signInMethod": signInMethod.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await firestore.collection("users").document(userId).setData(userData, merge: true)
    }
    
    private func createUserProfile(userId: String, email: String, firstName: String, lastName: String) async throws {
        try await createOrUpdateUserProfile(
            userId: userId,
            email: email,
            firstName: firstName,
            lastName: lastName,
            signInMethod: .email
        )
    }
    
    private func deleteUserData(userId: String) async throws {
        let batch = firestore.batch()
        
        // Delete user document
        let userRef = firestore.collection("users").document(userId)
        batch.deleteDocument(userRef)
        
        // Delete user's meals
        let mealsQuery = firestore.collection("meals").whereField("userId", isEqualTo: userId)
        let mealsSnapshot = try await mealsQuery.getDocuments()
        for document in mealsSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        // Delete user's bowel movements
        let bowelQuery = firestore.collection("bowelMovements").whereField("userId", isEqualTo: userId)
        let bowelSnapshot = try await bowelQuery.getDocuments()
        for document in bowelSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        try await batch.commit()
    }
    
    private func handleAuthError(_ error: Error) -> String {
        if let authError = error as NSError? {
            switch authError.code {
            case AuthErrorCode.invalidEmail.rawValue:
                return "Invalid email address"
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                return "Email already in use"
            case AuthErrorCode.weakPassword.rawValue:
                return "Password is too weak"
            case AuthErrorCode.wrongPassword.rawValue:
                return "Incorrect password"
            case AuthErrorCode.userNotFound.rawValue:
                return "No account found with this email"
            case AuthErrorCode.userDisabled.rawValue:
                return "This account has been disabled"
            case AuthErrorCode.tooManyRequests.rawValue:
                return "Too many failed attempts. Please try again later"
            case AuthErrorCode.networkError.rawValue:
                return "Network error. Please check your connection"
            case AuthErrorCode.invalidPhoneNumber.rawValue:
                return "Invalid phone number format"
            case AuthErrorCode.invalidVerificationCode.rawValue:
                return "Invalid verification code"
            case AuthErrorCode.sessionExpired.rawValue:
                return "Verification session expired. Please try again"
            default:
                return "Authentication failed: \(error.localizedDescription)"
            }
        }
        return error.localizedDescription
    }
    
    // MARK: - Utility Methods for Apple Sign In
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with error \(errorCode).")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Utility Methods
    
    @MainActor
    private func getRootViewController() async -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}

// MARK: - Custom Errors

enum AuthError: LocalizedError {
    case noUser
    case noViewController
    case noIDToken
    case invalidIDToken
    case invalidNonce
    case noVerificationID
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No user is currently signed in"
        case .noViewController:
            return "Unable to present sign-in interface"
        case .noIDToken:
            return "Unable to retrieve ID token"
        case .invalidIDToken:
            return "Invalid ID token received"
        case .invalidNonce:
            return "Invalid nonce for Apple Sign In"
        case .noVerificationID:
            return "No verification ID available for phone authentication"
        case .custom(let message):
            return message
        }
    }
}

// MARK: - Sign In Methods

enum SignInMethod: String, CaseIterable {
    case email = "email"
    case apple = "apple"
    case phone = "phone"
    
    var displayName: String {
        switch self {
        case .email:
            return "Email"
        case .apple:
            return "Apple"
        case .phone:
            return "Phone"
        }
    }
    
    var icon: String {
        switch self {
        case .email:
            return "envelope.fill"
        case .apple:
            return "applelogo"
        case .phone:
            return "phone.fill"
        }
    }
}
