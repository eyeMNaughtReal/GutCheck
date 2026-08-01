import Foundation

// MARK: - Base Error Protocol
protocol AppError: LocalizedError {
    var errorCode: String { get }
    var title: String { get }
}

// MARK: - Domain-Specific Errors

/// Failures involving the device-local profile.
///
/// This replaced an `AuthenticationError` covering sign-in, passwords and phone
/// verification. None of those exist any more — there is no account to sign in
/// to — so what remains is the much narrower set of ways the local profile
/// itself can fail.
enum ProfileError: AppError {
    case profileUnavailable
    case updateFailed
    case deletionFailed

    var errorCode: String {
        switch self {
        case .profileUnavailable: return "PROFILE001"
        case .updateFailed: return "PROFILE002"
        case .deletionFailed: return "PROFILE003"
        }
    }

    var title: String { "Profile Error" }

    var errorDescription: String? {
        switch self {
        case .profileUnavailable:
            return "Your profile could not be opened"
        case .updateFailed:
            return "Failed to save your profile changes"
        case .deletionFailed:
            return "Failed to delete your data"
        }
    }
}

enum DataError: AppError {
    case saveFailed
    case loadFailed
    case deleteFailed
    case storeUnavailable
    case migrationFailed

    var errorCode: String {
        switch self {
        case .saveFailed: return "DATA001"
        case .loadFailed: return "DATA002"
        case .deleteFailed: return "DATA003"
        case .storeUnavailable: return "DATA004"
        case .migrationFailed: return "DATA005"
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
        case .storeUnavailable:
            return "The local data store is unavailable"
        case .migrationFailed:
            return "Failed to move your existing data into the new store"
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

        // Storage failures surface as RepositoryError from the SwiftData layer.
        if let repositoryError = error as? RepositoryError {
            return ("Data Error", repositoryError.localizedDescription)
        }

        // Default error handling
        return ("Error", error.localizedDescription)
    }
}

// MARK: - Usage Example
// do {
//     try someRiskyOperation()
// } catch {
//     let (title, message) = ErrorHandlingService.shared.handle(error)
//     // Show alert with title and message
// }
