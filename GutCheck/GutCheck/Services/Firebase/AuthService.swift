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
import AuthenticationServices

@MainActor
class AuthService: AuthenticationProtocol, HasLoadingState {
    @Published private(set) var authUser: FirebaseAuth.User?
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthStateResolved = false
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isAwaitingEmailVerification = false
    private var verificationId: String?
    @Published private(set) var isPhoneVerificationInProgress = false
    /// Temporarily holds the email for resending verification when the user is signed out
    private var pendingVerificationEmail: String?
    private var pendingVerificationPassword: String?
    private var currentNonce: String?
    
    let loadingState = LoadingStateManager()
    
    private let auth = Auth.auth()
    private lazy var firestore = Firestore.firestore()
    
    // Auth state listener handle
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Listen for auth state changes
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self = self else { return }
                self.authUser = user
                
                if let authUser = user {
                    await self.loadCurrentUser(userId: authUser.uid)
                    
                    // Check if this is an email user who hasn't verified yet
                    let isEmailUser = authUser.providerData.contains { $0.providerID == "password" }
                    if isEmailUser && !authUser.isEmailVerified {
                        self.isAuthenticated = false
                        self.isAwaitingEmailVerification = true
                    } else {
                        self.isAuthenticated = true
                        self.isAwaitingEmailVerification = false
                    }
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
                
                self.isAuthStateResolved = true
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
            
            // Block unverified email users
            if !result.user.isEmailVerified {
                pendingVerificationEmail = email
                pendingVerificationPassword = password
                isAwaitingEmailVerification = true
                isAuthenticated = false
                return
            }
            
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
            
            // Send verification email and hold at verification screen
            try await result.user.sendEmailVerification()
            pendingVerificationEmail = email
            pendingVerificationPassword = password
            isAwaitingEmailVerification = true
            isAuthenticated = false
            
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
    
    // MARK: - Email Verification
    
    func resendVerificationEmail() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // If we have a signed-in user, use them directly
        if let user = auth.currentUser {
            try await user.reload()
            if user.isEmailVerified {
                // Already verified — proceed to authenticated state
                isAwaitingEmailVerification = false
                isAuthenticated = true
                await loadCurrentUser(userId: user.uid)
                return
            }
            try await user.sendEmailVerification()
            return
        }
        
        // Otherwise, sign in temporarily to resend
        guard let email = pendingVerificationEmail,
              let password = pendingVerificationPassword else {
            throw AuthError.custom("No pending verification. Please sign in again.")
        }
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            try await result.user.sendEmailVerification()
            authUser = result.user
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    func checkEmailVerification() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // If we have a signed-in user, reload and check
        if let user = auth.currentUser {
            try await user.reload()
            if user.isEmailVerified {
                isAwaitingEmailVerification = false
                isAuthenticated = true
                pendingVerificationEmail = nil
                pendingVerificationPassword = nil
                await loadCurrentUser(userId: user.uid)
                return
            } else {
                throw AuthError.custom("Email not yet verified. Please check your inbox and tap the verification link.")
            }
        }
        
        // If no current user, try signing in with stored credentials
        guard let email = pendingVerificationEmail,
              let password = pendingVerificationPassword else {
            throw AuthError.custom("No pending verification. Please sign in again.")
        }
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            try await result.user.reload()
            
            if result.user.isEmailVerified {
                authUser = result.user
                isAwaitingEmailVerification = false
                isAuthenticated = true
                pendingVerificationEmail = nil
                pendingVerificationPassword = nil
                await loadCurrentUser(userId: result.user.uid)
            } else {
                authUser = result.user
                throw AuthError.custom("Email not yet verified. Please check your inbox and tap the verification link.")
            }
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            throw error
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    func cancelEmailVerification() throws {
        isAwaitingEmailVerification = false
        pendingVerificationEmail = nil
        pendingVerificationPassword = nil
        try signOut()
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
            try await currentFirebaseUser.reauthenticate(with: credential)
            
            // Step 2: Delete user data from Firestore
            try await deleteUserData(userId: currentFirebaseUser.uid)
            
            // Step 3: Delete the Firebase Auth account
            try await currentFirebaseUser.delete()
            
            // Step 4: Clear local state
            authUser = nil
            currentUser = nil
            isAuthenticated = false
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Delete the account after the user has already been re-authenticated.
    /// Call this after ReauthenticationView succeeds.
    func deleteAuthenticatedAccount() async throws {
        guard let currentFirebaseUser = authUser else {
            throw AuthError.noUser
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await deleteUserData(userId: currentFirebaseUser.uid)
            
            try await currentFirebaseUser.delete()
            
            authUser = nil
            currentUser = nil
            isAuthenticated = false
            
        } catch {
            errorMessage = error.localizedDescription
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
    
    // MARK: - Apple Sign In
    
    /// Prepares the Apple Sign-In request by generating and storing a nonce.
    /// Returns the SHA256-hashed nonce to include in the ASAuthorizationAppleIDRequest.
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }
    
    /// Signs in with Apple using the authorization result from ASAuthorizationController.
    func signInWithApple(_ authorization: ASAuthorization) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.custom("Invalid Apple credential type")
        }
        
        guard let identityToken = appleIDCredential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.custom("Unable to retrieve Apple identity token")
        }
        
        guard let nonce = currentNonce else {
            throw AuthError.custom("No nonce available. Please try signing in again.")
        }
        
        do {
            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: idTokenString,
                rawNonce: nonce
            )
            
            let result = try await auth.signIn(with: credential)
            authUser = result.user
            
            // Check if this is a new user (first sign-in) or returning user
            let userDoc = try await FirebaseManager.shared.userDocument(result.user.uid).getDocument()
            
            if !userDoc.exists {
                // New user: extract name from Apple credential (only provided on first sign-in)
                let firstName = appleIDCredential.fullName?.givenName ?? ""
                let lastName = appleIDCredential.fullName?.familyName ?? ""
                let email = appleIDCredential.email ?? result.user.email ?? ""
                
                let newUser = try await createUserProfile(
                    userId: result.user.uid,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    signInMethod: .apple
                )
                currentUser = newUser
            } else {
                await loadCurrentUser(userId: result.user.uid)
            }
            
            // Apple users are pre-verified — skip email verification
            isAuthenticated = true
            isAwaitingEmailVerification = false
            currentNonce = nil
            
        } catch {
            currentNonce = nil
            errorMessage = handleAuthError(error)
            throw error
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - User Profile Management
    
    private func loadCurrentUser(userId: String) async {
        do {
            let document = try await FirebaseManager.shared.userDocument(userId).getDocument()
            if let data = document.data() {
                let user = try parseUser(from: data, id: userId)
                currentUser = user
            }
        } catch {
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
        // Step 1: Clear local encrypted files first while we still know who the user is.
        try await LocalStorageService.shared.clearAllPrivateData()

        // Step 2: Collect every Firestore document reference that belongs to this user.
        var documentsToDelete: [DocumentReference] = []

        // Top-level user document
        documentsToDelete.append(FirebaseManager.shared.userDocument(userId))

        // Documents whose ID is the userId (single-document-per-user collections)
        let userKeyedCollections = ["reminderSettings", "userPreferences", "analytics"]
        for collection in userKeyedCollections {
            documentsToDelete.append(firestore.collection(collection).document(userId))
        }

        // Collections queried by the createdBy field
        let createdByQueries: [(Query, String)] = [
            (FirebaseManager.shared.queryMealsByUser(userId),     "meals"),
            (FirebaseManager.shared.querySymptomsByUser(userId),  "symptoms"),
            (firestore.collection("insights").whereField("createdBy", isEqualTo: userId),      "insights"),
            (firestore.collection("mealTemplates").whereField("createdBy", isEqualTo: userId), "mealTemplates")
        ]
        for (query, _) in createdByQueries {
            let snapshot = try await query.getDocuments()
            documentsToDelete.append(contentsOf: snapshot.documents.map { $0.reference })
        }

        // Subcollections nested under /users/{userId}
        let userSubcollections = ["mealHistory", "symptomHistory"]
        for subcollection in userSubcollections {
            let snapshot = try await firestore
                .collection("users")
                .document(userId)
                .collection(subcollection)
                .getDocuments()
            documentsToDelete.append(contentsOf: snapshot.documents.map { $0.reference })
        }

        // Step 3: Commit in batches of 500 (Firestore hard limit per batch).
        let batchSize = 500
        var index = 0
        while index < documentsToDelete.count {
            let batch = firestore.batch()
            let end = min(index + batchSize, documentsToDelete.count)
            for ref in documentsToDelete[index ..< end] {
                batch.deleteDocument(ref)
            }
            try await batch.commit()
            index += batchSize
        }

        #if DEBUG
        #endif
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
            return 
        }
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
