//
//  AuthService.swift
//  GutCheck
//
//  Created by Mark Conley on 7/9/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

@MainActor
class AuthService: AuthenticationProtocol, HasLoadingState {
    @Published private(set) var authUser: FirebaseAuth.User?
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    private var verificationId: String?
    @Published private(set) var isPhoneVerificationInProgress = false
    
    let loadingState = LoadingStateManager()
    
    private let auth = Auth.auth()
    private lazy var firestore = Firestore.firestore()
    
    // Auth state listener handle
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Listen for auth state changes
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.authUser = user
                self?.isAuthenticated = user != nil
                
                if let authUser = user {
                    await self?.loadCurrentUser(userId: authUser.uid)
                } else {
                    self?.currentUser = nil
                }
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
            authUser = result.user
            isAuthenticated = true
            await loadCurrentUser(userId: result.user.uid)
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String, privacyPolicyAccepted: Bool = true) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            authUser = result.user
            isAuthenticated = true
            
            // Create user profile in Firestore
            let newUser = try await createUserProfile(
                userId: result.user.uid,
                email: email,
                firstName: firstName,
                lastName: lastName,
                signInMethod: .email,
                privacyPolicyAccepted: privacyPolicyAccepted
            )
            currentUser = newUser
            
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try auth.signOut()
            self.authUser = nil
            self.currentUser = nil
            self.isAuthenticated = false
            self.errorMessage = nil
        } catch {
            self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
            throw error
        }
    }
    
    func sendPasswordReset(email: String) async throws {
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
    
    func verifyPhoneNumber(_ phoneNumber: String) async throws {
        isLoading = true
        errorMessage = nil
        isPhoneVerificationInProgress = true
        
        defer { isLoading = false }
        
        do {
            let verificationID = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            verificationId = verificationID
        } catch {
            isPhoneVerificationInProgress = false
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    func signInWithPhone(verificationCode: String) async throws {
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
            
            let result = try await auth.signIn(with: credential)
            authUser = result.user
            await loadCurrentUser(userId: result.user.uid)
            isAuthenticated = true
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    // MARK: - Re-authentication Methods
    
    /// Re-authenticates the current user with the provided credential
    func reauthenticateUser(with credential: AuthCredential) async throws {
        guard let currentFirebaseUser = authUser else {
            throw AuthError.noUser
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await currentFirebaseUser.reauthenticate(with: credential)
            print("🔐 AuthService: User re-authenticated successfully")
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    /// Re-authenticates user with email and password
    func reauthenticateWithEmail(email: String, password: String) async throws {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await reauthenticateUser(with: credential)
    }
    
    /// Re-authenticates user with phone verification
    func reauthenticateWithPhone(phoneNumber: String, verificationCode: String) async throws {
        guard let verificationId = verificationId else {
            throw AuthError.noVerificationID
        }
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationId,
            verificationCode: verificationCode
        )
        try await reauthenticateUser(with: credential)
    }
    
    // MARK: - Enhanced Account Deletion
    
    /// Deletes the user account after re-authentication
    func deleteAccount(credential: AuthCredential) async throws {
        guard let currentFirebaseUser = authUser else {
            throw AuthError.noUser
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Step 1: Re-authenticate before deletion
            print("🔐 AuthService: Re-authenticating user before account deletion")
            try await currentFirebaseUser.reauthenticate(with: credential)
            
            // Step 2: Delete user data from Firestore
            print("🗑️ AuthService: Deleting user data from Firestore")
            try await deleteUserData(userId: currentFirebaseUser.uid)
            
            // Step 3: Delete the Firebase Auth account
            print("🗑️ AuthService: Deleting Firebase Auth account")
            try await currentFirebaseUser.delete()
            
            // Step 4: Clear local state
            authUser = nil
            currentUser = nil
            isAuthenticated = false
            
            print("✅ AuthService: Account deleted successfully")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ AuthService: Failed to delete account: \(error)")
            throw error
        }
    }
    
    /// Convenience method for deleting account with email/password
    func deleteAccountWithEmail(email: String, password: String) async throws {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await deleteAccount(credential: credential)
    }
    
    /// Convenience method for deleting account with phone verification
    func deleteAccountWithPhone(phoneNumber: String, verificationCode: String) async throws {
        guard let verificationId = verificationId else {
            throw AuthError.noVerificationID
        }
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationId,
            verificationCode: verificationCode
        )
        try await deleteAccount(credential: credential)
    }
    
    // MARK: - Phone Sign In
    
    func sendPhoneVerification(phoneNumber: String) async throws {
        isLoading = true
        isPhoneVerificationInProgress = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            verificationId = verificationID
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
            authUser = authResult.user
            isAuthenticated = true
            
            let newUser = try await createUserProfile(
                userId: authResult.user.uid,
                email: "",
                firstName: firstName,
                lastName: lastName,
                signInMethod: .phone
            )
            currentUser = newUser
            
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    // MARK: - User Profile Management
    
    private func loadCurrentUser(userId: String) async {
        do {
            print("👤 AuthService: Loading user data for \(userId)")
            let document = try await FirebaseManager.shared.userDocument(userId).getDocument()
            if let data = document.data() {
                let user = try parseUser(from: data, id: userId)
                print("👤 AuthService: Loaded user - profileImageURL: \(user.profileImageURL ?? "nil")")
                currentUser = user
            }
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
    
    @discardableResult
    func createUserProfile(userId: String, email: String, firstName: String, lastName: String, signInMethod: SignInMethod, privacyPolicyAccepted: Bool = true) async throws -> User {
        let userData: [String: Any] = [
            "id": userId,
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "signInMethod": signInMethod.rawValue,
            "privacyPolicyAccepted": privacyPolicyAccepted,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await FirebaseManager.shared.userDocument(userId).setData(userData, merge: true)
        
        // Return a User object
        return User(
            id: userId,
            email: email,
            firstName: firstName,
            lastName: lastName,
            signInMethod: signInMethod,
            privacyPolicyAccepted: privacyPolicyAccepted
        )
    }
    
    func updateUserProfile(_ updatedUser: User) async throws {
        guard let currentFirebaseUser = authUser else {
            throw AuthError.noUser
        }
        
        try await FirebaseManager.shared.userDocument(currentFirebaseUser.uid).updateData(updatedUser.toFirestoreData())
        currentUser = updatedUser
    }
    
    private func parseUser(from data: [String: Any], id: String) throws -> User {
        guard let email = data["email"] as? String,
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let signInMethodString = data["signInMethod"] as? String,
              let signInMethod = SignInMethod(rawValue: signInMethodString),
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp else {
            throw NSError(domain: "UserParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse user data"])
        }
        
        // Parse privacy policy fields with defaults
        let privacyPolicyAccepted = data["privacyPolicyAccepted"] as? Bool ?? false
        let privacyPolicyVersion = data["privacyPolicyVersion"] as? String ?? "1.0"
        let privacyPolicyAcceptedDate = (data["privacyPolicyAcceptedDate"] as? Timestamp)?.dateValue()
        
        var user = User(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            signInMethod: signInMethod,
            createdAt: createdAtTimestamp,
            updatedAt: updatedAtTimestamp,
            privacyPolicyAccepted: privacyPolicyAccepted,
            privacyPolicyAcceptedDate: privacyPolicyAcceptedDate,
            privacyPolicyVersion: privacyPolicyVersion
        )
        
        // Parse optional health data
        if let dateOfBirthTimestamp = data["dateOfBirth"] as? Timestamp {
            user.dateOfBirth = dateOfBirthTimestamp.dateValue()
        }
        
        if let weight = data["weight"] as? Double {
            user.weight = weight
        }
        
        if let height = data["height"] as? Double {
            user.height = height
        }
        
        if let biologicalSexRawValue = data["biologicalSexRawValue"] as? Int {
            user.biologicalSexRawValue = biologicalSexRawValue
        }
        
        return user
    }
    
    private func deleteUserData(userId: String) async throws {
        let batch = firestore.batch()
        
        // Delete user document
        let userRef = FirebaseManager.shared.userDocument(userId)
        batch.deleteDocument(userRef)
        
        // Delete user's meals
        let mealsQuery = FirebaseManager.shared.queryMealsByUser(userId)
        let mealsSnapshot = try await mealsQuery.getDocuments()
        for document in mealsSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        // Delete user's symptoms
        let symptomsQuery = FirebaseManager.shared.querySymptomsByUser(userId)
        let symptomsSnapshot = try await symptomsQuery.getDocuments()
        for document in symptomsSnapshot.documents {
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
    
    /// Refresh the current user data from Firestore
    func refreshCurrentUser() async {
        guard let userId = authUser?.uid else { 
            print("🔄 AuthService: No authUser.uid available for refresh")
            return 
        }
        print("🔄 AuthService: Refreshing current user data...")
        await loadCurrentUser(userId: userId)
    }
}

// MARK: - Custom Errors
enum AuthError: LocalizedError {
    case noUser
    case noVerificationID
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No user is currently signed in"
        case .noVerificationID:
            return "No verification ID available for phone authentication"
        case .custom(let message):
            return message
        }
    }
}
