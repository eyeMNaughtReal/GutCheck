import Testing
import Foundation
@testable import GutCheck

struct ErrorHandlingServiceTests {
    let service = ErrorHandlingService.shared

    // MARK: - AppError handling

    @Test("Handles AuthenticationError with correct title and message")
    func handlesAuthenticationError() {
        let error = AuthenticationError.invalidCredentials
        let (title, message) = service.handle(error)
        #expect(title == "Authentication Error")
        #expect(message == "Invalid email or password")
    }

    @Test("Handles DataError with correct title and message")
    func handlesDataError() {
        let error = DataError.networkError
        let (title, message) = service.handle(error)
        #expect(title == "Data Error")
        #expect(message == "Network connection error")
    }

    @Test("All AuthenticationError cases have error codes", arguments: AuthenticationError.allCases)
    func authenticationErrorCodes(error: AuthenticationError) {
        #expect(error.errorCode.hasPrefix("AUTH"))
        #expect(!error.errorCode.isEmpty)
    }

    @Test("All DataError cases have error codes", arguments: DataError.allCases)
    func dataErrorCodes(error: DataError) {
        #expect(error.errorCode.hasPrefix("DATA"))
        #expect(!error.errorCode.isEmpty)
    }

    @Test("All AuthenticationError cases have descriptions", arguments: AuthenticationError.allCases)
    func authenticationErrorDescriptions(error: AuthenticationError) {
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("All DataError cases have descriptions", arguments: DataError.allCases)
    func dataErrorDescriptions(error: DataError) {
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    // MARK: - Firebase error handling

    @Test("Handles Firebase auth no-network error")
    func handlesFirebaseAuthNoNetwork() {
        let error = NSError(domain: "FIRAuthErrorDomain", code: 17020)
        let (title, message) = service.handle(error)
        #expect(title == "Authentication Error")
        #expect(message == "No network connection")
    }

    @Test("Handles Firebase auth weak password error")
    func handlesFirebaseAuthWeakPassword() {
        let error = NSError(domain: "FIRAuthErrorDomain", code: 17026)
        let (title, message) = service.handle(error)
        #expect(title == "Authentication Error")
        #expect(message == "Password is too weak")
    }

    @Test("Handles Firebase auth email in use error")
    func handlesFirebaseAuthEmailInUse() {
        let error = NSError(domain: "FIRAuthErrorDomain", code: 17007)
        let (title, message) = service.handle(error)
        #expect(title == "Authentication Error")
        #expect(message == "Email already in use")
    }

    @Test("Handles Firestore permission denied error")
    func handlesFirestorePermissionDenied() {
        let error = NSError(domain: "FIRFirestoreErrorDomain", code: 7)
        let (title, message) = service.handle(error)
        #expect(title == "Database Error")
        #expect(message == "Permission denied")
    }

    @Test("Handles Firestore connection failed error")
    func handlesFirestoreConnectionFailed() {
        let error = NSError(domain: "FIRFirestoreErrorDomain", code: 13)
        let (title, message) = service.handle(error)
        #expect(title == "Database Error")
        #expect(message == "Database connection failed")
    }

    // MARK: - Default error handling

    @Test("Handles unknown error with generic title")
    func handlesUnknownError() {
        let error = NSError(domain: "UnknownDomain", code: 999, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
        let (title, message) = service.handle(error)
        #expect(title == "Error")
        #expect(message == "Something went wrong")
    }
}

// Make error enums CaseIterable for parameterized tests
extension AuthenticationError: CaseIterable {
    public static var allCases: [AuthenticationError] {
        [.invalidCredentials, .accountExists, .weakPassword, .invalidPhoneNumber, .verificationFailed, .notAuthenticated]
    }
}

extension DataError: CaseIterable {
    public static var allCases: [DataError] {
        [.saveFailed, .loadFailed, .deleteFailed, .networkError, .syncFailed]
    }
}
