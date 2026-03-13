import Foundation
import FirebaseAuth

@MainActor
@Observable class PreviewAuthService: AuthenticationProtocol {
    private(set) var isAuthStateResolved: Bool = true
    private(set) var isAuthenticated: Bool = true
    private(set) var isLoading: Bool = false
    var errorMessage: String?
    private(set) var isPhoneVerificationInProgress: Bool = false
    private(set) var isAwaitingEmailVerification: Bool = false
    private(set) var currentUser: User? = User(
        id: "preview",
        email: "preview@example.com",
        firstName: "Preview",
        lastName: "User",
        signInMethod: .email,
        createdAt: Date.now,
        updatedAt: Date.now
    )
    
    // MARK: - Protocol Methods (Preview Implementation)
    
    func signIn(email: String, password: String) async throws {
        // Preview implementation - no-op
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String, privacyPolicyAccepted: Bool) async throws {
        // Preview implementation - no-op
    }
    
    func sendPasswordReset(email: String) async throws {
        // Preview implementation - no-op
    }
    
    func verifyPhoneNumber(_ phoneNumber: String) async throws {
        // Preview implementation - no-op
    }
    
    func signInWithPhone(verificationCode: String) async throws {
        // Preview implementation - no-op
    }
    
    func signOut() throws {
        // Preview implementation - no-op
    }
}
