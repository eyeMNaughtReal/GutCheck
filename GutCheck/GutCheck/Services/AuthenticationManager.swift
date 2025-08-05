import Foundation
import FirebaseAuth

class AuthenticationManager {
    static let shared = AuthenticationManager()
    
    private init() {}
    
    // MARK: - User ID Access
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    func requireCurrentUserId() throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthenticationError.notAuthenticated
        }
        return userId
    }
    
    // MARK: - Firebase User Access
    
    var currentFirebaseUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }
    
    func requireCurrentFirebaseUser() throws -> FirebaseAuth.User {
        guard let user = Auth.auth().currentUser else {
            throw AuthenticationError.notAuthenticated
        }
        return user
    }
    
    // MARK: - Authentication State
    
    var isAuthenticated: Bool {
        Auth.auth().currentUser != nil
    }
}