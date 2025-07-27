import Foundation

@MainActor
protocol AuthenticationProtocol: ObservableObject {
    var isAuthenticated: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get set }
    var isPhoneVerificationInProgress: Bool { get }
    var currentUser: User? { get }
    
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws
    func sendPasswordReset(email: String) async throws
    func verifyPhoneNumber(_ phoneNumber: String) async throws
    func signInWithPhone(verificationCode: String) async throws
    func signOut() throws
}
