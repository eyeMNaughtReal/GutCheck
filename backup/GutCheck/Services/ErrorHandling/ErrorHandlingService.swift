import Foundation

// MARK: - Base Error Protocol
protocol AppError: LocalizedError {
    var errorCode: String { get }
    var title: String { get }
}

// MARK: - Domain-Specific Errors
enum AuthenticationError: AppError {
    case invalidCredentials
    case accountExists
    case weakPassword
    case invalidPhoneNumber
    case verificationFailed
    case notAuthenticated
    
    var errorCode: String {
        switch self {
        case .invalidCredentials: return "AUTH001"
        case .accountExists: return "AUTH002"
        case .weakPassword: return "AUTH003"
        case .invalidPhoneNumber: return "AUTH004"
        case .verificationFailed: return "AUTH005"
        case .notAuthenticated: return "AUTH006"
        }
    }
    
    var title: String { "Authentication Error" }
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .accountExists:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .invalidPhoneNumber:
            return "Please enter a valid phone number"
        case .verificationFailed:
            return "Failed to verify phone number"
        case .notAuthenticated:
            return "Please sign in to continue"
        }
    }
}

enum DataError: AppError {
    case saveFailed
    case loadFailed
    case deleteFailed
    case networkError
    case syncFailed
    
    var errorCode: String {
        switch self {
        case .saveFailed: return "DATA001"
        case .loadFailed: return "DATA002"
        case .deleteFailed: return "DATA003"
        case .networkError: return "DATA004"
        case .syncFailed: return "DATA005"
        }
    }
    
    var title: String { "Data Error" }
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        case .deleteFailed:
            return "Failed to delete data"
        case .networkError:
            return "Network connection error"
        case .syncFailed:
            return "Failed to sync with server"
        }
    }
}

// MARK: - Error Handling Service
final class ErrorHandlingService {
    static let shared = ErrorHandlingService()
    private init() {}
    
    /// Handles an error and returns user-friendly error information
    func handle(_ error: Error) -> (title: String, message: String) {
        if let appError = error as? AppError {
            return (appError.title, appError.localizedDescription)
        }
        
        // Handle Firebase errors
        if let nsError = error as NSError? {
            switch nsError.domain {
            case "FIRAuthErrorDomain":
                return handleFirebaseAuthError(nsError)
            case "FIRFirestoreErrorDomain":
                return handleFirestoreError(nsError)
            default:
                break
            }
        }
        
        // Default error handling
        return ("Error", error.localizedDescription)
    }
    
    private func handleFirebaseAuthError(_ error: NSError) -> (String, String) {
        // Handle specific Firebase auth error codes
        let message: String
        switch error.code {
        case 17020:
            message = "No network connection"
        case 17026:
            message = "Password is too weak"
        case 17007:
            message = "Email already in use"
        default:
            message = error.localizedDescription
        }
        return ("Authentication Error", message)
    }
    
    private func handleFirestoreError(_ error: NSError) -> (String, String) {
        // Handle specific Firestore error codes
        let message: String
        switch error.code {
        case 7:
            message = "Permission denied"
        case 13:
            message = "Database connection failed"
        default:
            message = error.localizedDescription
        }
        return ("Database Error", message)
    }
}

// MARK: - Usage Example
// do {
//     try someRiskyOperation()
// } catch {
//     let (title, message) = ErrorHandlingService.shared.handle(error)
//     // Show alert with title and message
// }
