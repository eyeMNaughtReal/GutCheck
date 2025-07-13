//
//  AuthService.swift
//  GutCheck
//
//  Complete AuthService with all methods properly implemented
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

@MainActor
class AuthService: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var verificationId: String?
    @Published var isPhoneVerificationInProgress = false
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    
    // Auth state listener handle
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Listen for auth state changes
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = user != nil
                
                if let user = user {
                    await self?.loadCurrentUser(userId: user.uid)
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
            user = result.user
            isAuthenticated = true
            await loadCurrentUser(userId: result.user.uid)
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
            let newUser = try await createUserProfile(
                userId: result.user.uid,
                email: email,
                firstName: firstName,
                lastName: lastName,
                signInMethod: .email
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
            user = nil
            currentUser = nil
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
            self.currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = handleAuthError(error)
            throw error
        }
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
            let document = try await firestore.collection("users").document(userId).getDocument()
            if let data = document.data() {
                currentUser = try parseUser(from: data, id: userId)
            }
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
    
    @discardableResult
    func createUserProfile(userId: String, email: String, firstName: String, lastName: String, signInMethod: SignInMethod) async throws -> User {
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
        
        // Return a User object
        return User(
            id: userId,
            email: email,
            firstName: firstName,
            lastName: lastName,
            signInMethod: signInMethod
        )
    }
    
    func updateUserProfile(_ updatedUser: User) async throws {
        guard let currentFirebaseUser = user else {
            throw AuthError.noUser
        }
        
        try await firestore.collection("users").document(currentFirebaseUser.uid).updateData(updatedUser.toFirestoreData())
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
        
        var user = User(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            signInMethod: signInMethod,
            createdAt: createdAtTimestamp,
            updatedAt: updatedAtTimestamp
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
        let userRef = firestore.collection("users").document(userId)
        batch.deleteDocument(userRef)
        
        // Delete user's meals
        let mealsQuery = firestore.collection("meals").whereField("userId", isEqualTo: userId)
        let mealsSnapshot = try await mealsQuery.getDocuments()
        for document in mealsSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        // Delete user's symptoms
        let symptomsQuery = firestore.collection("symptoms").whereField("userId", isEqualTo: userId)
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
