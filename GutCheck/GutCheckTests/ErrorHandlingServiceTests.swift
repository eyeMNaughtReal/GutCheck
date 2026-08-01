import Testing
import Foundation
@testable import GutCheck

struct ErrorHandlingServiceTests {
    let service = ErrorHandlingService.shared

    // MARK: - AppError handling

    @Test("Handles ProfileError with correct title and message")
    func handlesProfileError() {
        let error = ProfileError.profileUnavailable
        let (title, message) = service.handle(error)
        #expect(title == "Profile Error")
        #expect(message == "Your profile could not be opened")
    }

    @Test("Handles DataError with correct title and message")
    func handlesDataError() {
        let error = DataError.storeUnavailable
        let (title, message) = service.handle(error)
        #expect(title == "Data Error")
        #expect(message == "The local data store is unavailable")
    }

    @Test("All ProfileError cases have error codes", arguments: ProfileError.allCases)
    func profileErrorCodes(error: ProfileError) {
        #expect(error.errorCode.hasPrefix("PROFILE"))
        #expect(!error.errorCode.isEmpty)
    }

    @Test("All DataError cases have error codes", arguments: DataError.allCases)
    func dataErrorCodes(error: DataError) {
        #expect(error.errorCode.hasPrefix("DATA"))
        #expect(!error.errorCode.isEmpty)
    }

    @Test("All ProfileError cases have descriptions", arguments: ProfileError.allCases)
    func profileErrorDescriptions(error: ProfileError) {
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("All DataError cases have descriptions", arguments: DataError.allCases)
    func dataErrorDescriptions(error: DataError) {
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    // MARK: - Storage error handling

    @Test("Surfaces a missing record as a data error")
    func handlesRecordNotFound() {
        let (title, message) = service.handle(RepositoryError.recordNotFound("abc"))
        #expect(title == "Data Error")
        #expect(message.contains("abc"))
    }

    @Test("Surfaces a store failure as a data error")
    func handlesStorageError() {
        let underlying = NSError(
            domain: "NSCocoaErrorDomain",
            code: 134060,
            userInfo: [NSLocalizedDescriptionKey: "The operation couldn't be completed"]
        )
        let (title, message) = service.handle(RepositoryError.storageError(underlying))
        #expect(title == "Data Error")
        #expect(message.contains("The operation couldn't be completed"))
    }

    @Test("Reports a missing profile through the repository error path")
    func handlesNoActiveProfile() {
        let (title, message) = service.handle(RepositoryError.noActiveProfile)
        #expect(title == "Data Error")
        #expect(message == "No local profile is available")
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
extension ProfileError: CaseIterable {
    public static var allCases: [ProfileError] {
        [.profileUnavailable, .updateFailed, .deletionFailed]
    }
}

extension DataError: CaseIterable {
    public static var allCases: [DataError] {
        [.saveFailed, .loadFailed, .deleteFailed, .storeUnavailable, .migrationFailed]
    }
}
