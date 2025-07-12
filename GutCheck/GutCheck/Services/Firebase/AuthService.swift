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
    /*
    private var currentNonce: String?
    */
    
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
    /*
    func signInWithApple(_ authorization: ASAuthorization) async throws {
        isLoading = true
        errorMessage = nil
        
        let logPrefix = "🍎 [AuthService]"
        print("\(logPrefix) Starting Apple Sign In process")
        NSLog("\(logPrefix) Starting Apple Sign In process")
        
        defer { isLoading = false }
        
        do {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                print("\(logPrefix) Received Apple ID credential")
                NSLog("\(logPrefix) Received Apple ID credential")
                
                // Debug credential details
                let user = appleIDCredential.user
                print("\(logPrefix) User identifier: \(user)")
                NSLog("\(logPrefix) User identifier: \(user)")
                
                // Check if authorization code is present
                if let authCode = appleIDCredential.authorizationCode {
                    print("\(logPrefix) Auth code present, length: \(authCode.count)")
                    NSLog("\(logPrefix) Auth code present, length: \(authCode.count)")
                } else {
                    print("\(logPrefix) No auth code in credential")
                    NSLog("\(logPrefix) No auth code in credential")
                }
                
                guard let nonce = currentNonce else {
                    print("\(logPrefix) ERROR: No current nonce available")
                    NSLog("\(logPrefix) ERROR: No current nonce available")
                    
                    // Check if we have a stored nonce in UserDefaults
                    if let storedNonce = UserDefaults.standard.string(forKey: "lastAppleSignInNonce") {
                        print("\(logPrefix) Found stored nonce: \(storedNonce.prefix(10))...")
                        NSLog("\(logPrefix) Found stored nonce: \(storedNonce.prefix(10))...")
                    }
                    
                    throw AuthError.invalidNonce
                }
                
                print("\(logPrefix) Nonce verified, processing identity token")
                NSLog("\(logPrefix) Nonce verified, processing identity token")
                
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("\(logPrefix) ERROR: No identity token in credential")
                    NSLog("\(logPrefix) ERROR: No identity token in credential")
                    throw AuthError.noIDToken
                }
                
                print("\(logPrefix) Identity token present, length: \(appleIDToken.count) bytes")
                NSLog("\(logPrefix) Identity token present, length: \(appleIDToken.count) bytes")
                
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("\(logPrefix) ERROR: Could not convert identity token to string")
                    NSLog("\(logPrefix) ERROR: Could not convert identity token to string")
                    throw AuthError.invalidIDToken
                }
                
                print("\(logPrefix) Creating Firebase credential")
                NSLog("\(logPrefix) Creating Firebase credential")
                
                // Use the modern non-deprecated API
                print("🍎 [AuthService] Using providerID .apple for credential")
                NSLog("🍎 [AuthService] Using providerID .apple for credential")
                
                // Log detailed debug info about raw parameters
                print("🍎 [AuthService] idToken length: \(idTokenString.count)")
                print("🍎 [AuthService] rawNonce length: \(nonce.count)")
                NSLog("🍎 [AuthService] idToken length: \(idTokenString.count)")
                NSLog("🍎 [AuthService] rawNonce length: \(nonce.count)")
                
                do {
                    let credential = OAuthProvider.credential(
                        providerID: .apple,
                        idToken: idTokenString,
                        rawNonce: nonce
                    )
                    
                    print("🍎 [AuthService] Credential created successfully")
                    NSLog("🍎 [AuthService] Credential created successfully")
                    
                    print("🍎 [AuthService] Signing in with Firebase")
                    NSLog("🍎 [AuthService] Signing in with Firebase")
                    
                    let authResult = try await auth.signIn(with: credential)
                    print("🍎 [AuthService] Firebase auth returned a result")
                    NSLog("🍎 [AuthService] Firebase auth returned a result")
                    
                    self.user = authResult.user
                    isAuthenticated = true
                    
                    print("🍎 [AuthService] Successfully signed in with Firebase, UID: \(authResult.user.uid)")
                    NSLog("🍎 [AuthService] Successfully signed in with Firebase, UID: \(authResult.user.uid)")
                    
                    // Extract name from Apple ID credential
                    let firstName = appleIDCredential.fullName?.givenName ?? ""
                    let lastName = appleIDCredential.fullName?.familyName ?? ""
                    let email = authResult.user.email ?? appleIDCredential.email ?? ""
                    
                    print("🍎 [AuthService] User info - Email: \(email), First Name: \(firstName), Last Name: \(lastName)")
                    NSLog("🍎 [AuthService] User info - Email: \(email), First Name: \(firstName), Last Name: \(lastName)")
                    
                    try await createOrUpdateUserProfile(
                        userId: authResult.user.uid,
                        email: email,
                        firstName: firstName,
                        lastName: lastName,
                        signInMethod: .apple
                    )
                    
                    print("🍎 [AuthService] User profile created/updated successfully")
                    NSLog("🍎 [AuthService] User profile created/updated successfully")
                    
                    // Save successful login info to UserDefaults for debugging
                    UserDefaults.standard.set(authResult.user.uid, forKey: "lastSignedInUserID")
                    UserDefaults.standard.set(Date(), forKey: "lastSuccessfulSignIn")
                } catch {
                    print("🍎 [AuthService] ERROR in Firebase sign-in: \(error.localizedDescription)")
                    NSLog("🍎 [AuthService] ERROR in Firebase sign-in: \(error.localizedDescription)")
                    
                    // Try to get more detailed error information
                    if let authError = error as? AuthErrorCode {
                        print("🍎 [AuthService] Firebase auth error code: \(authError.code.rawValue)")
                        NSLog("🍎 [AuthService] Firebase auth error code: \(authError.code.rawValue)")
                    }
                    
                    throw error
                }
            }
        } catch {
            print("🍎 [AuthService] ERROR: Sign in failed: \(error.localizedDescription)")
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    */
    
    /*
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        let hashedNonce = sha256(nonce)
        
        // Use multiple logging methods to ensure visibility
        print("🍎 [AuthService] Generated nonce: \(nonce.prefix(10))..., hashed: \(hashedNonce.prefix(10))...")
        NSLog("🍎 [AuthService] Generated nonce: \(nonce.prefix(10))..., hashed: \(hashedNonce.prefix(10))...")
        debugPrint("🍎 [AuthService] Generated nonce: \(nonce.prefix(10))..., hashed: \(hashedNonce.prefix(10))...")
        
        // Store nonce in UserDefaults for debugging
        UserDefaults.standard.set(nonce, forKey: "lastAppleSignInNonce")
        UserDefaults.standard.set(Date(), forKey: "lastAppleSignInAttempt")
        
        return hashedNonce
    }
    */
    
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
