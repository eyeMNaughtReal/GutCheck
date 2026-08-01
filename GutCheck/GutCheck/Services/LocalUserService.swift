//
//  LocalUserService.swift
//  GutCheck
//
//  Owns the single device-local profile that replaced Firebase Auth.
//
//  GutCheck has no accounts and no server. There is nothing to sign in to, so
//  there is no sign-in: the app creates one profile the first time it launches
//  and every record it stores is attributed to that profile's id. The profile
//  exists to give records a stable owner and to hold the details the healthcare
//  export and HealthKit integration need (name, date of birth, weight, height).
//

import Foundation
import SwiftData

@MainActor
@Observable final class LocalUserService {
    static let shared = LocalUserService()

    /// The active profile. Non-nil after `init` — the app always has exactly one.
    private(set) var currentUser: User?

    /// True once the profile has been read from (or written to) the store.
    /// Views that used to wait on Firebase restoring a session gate on this.
    private(set) var isProfileLoaded = false

    /// Set when a profile write fails, so screens can surface it. Settable
    /// because a few screens clear it when dismissing their error alert.
    var errorMessage: String?

    private(set) var isLoading = false

    private init() {
        loadOrCreateProfile()
    }

    // MARK: - Profile identity

    /// The id every record's `createdBy` points at.
    ///
    /// Deliberately `nonisolated` and backed by `UserDefaults` rather than by
    /// `currentUser`. Repositories, background insight generation and several
    /// SwiftUI helpers all need the owning id on paths that are not on the main
    /// actor, and forcing an actor hop for a value that never changes during a
    /// launch would push `await` into a dozen call sites for nothing.
    ///
    /// It is minted here on first read rather than only when the profile row is
    /// created, so the id is the same value whichever happens first. Relying on
    /// launch ordering instead would mean a repository that somehow wrote before
    /// the service loaded — a preview, a background task — stamped its records
    /// with an owner no query would later match.
    nonisolated static var currentProfileId: String {
        profileIdLock.lock()
        defer { profileIdLock.unlock() }

        if let existing = UserDefaults.standard.string(forKey: profileIdKey), !existing.isEmpty {
            return existing
        }

        let minted = UUID().uuidString
        UserDefaults.standard.set(minted, forKey: profileIdKey)
        return minted
    }

    /// Instance accessor, for call sites that already hold the service.
    var currentProfileId: String { Self.currentProfileId }

    nonisolated private static let profileIdKey = "localProfile.id"

    /// Guards the read-mint-write above. `UserDefaults` is itself thread-safe,
    /// but that sequence is not atomic, and two first-readers racing would mint
    /// two different ids.
    nonisolated private static let profileIdLock = NSLock()

    /// Adopts the id of a profile row found in the store.
    ///
    /// An upgraded install already has a row; its id wins over anything minted
    /// above so existing records keep resolving to their owner.
    nonisolated private static func adoptProfileId(_ id: String) {
        profileIdLock.lock()
        defer { profileIdLock.unlock() }
        UserDefaults.standard.set(id, forKey: profileIdKey)
    }

    // MARK: - Loading

    private func loadOrCreateProfile() {
        defer { isProfileLoaded = true }

        do {
            let descriptor = FetchDescriptor<StoredUserProfile>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let profiles = try SwiftDataStack.shared.context.fetch(descriptor)

            if let existing = profiles.first {
                currentUser = existing.domainModel
                Self.adoptProfileId(existing.id)
                return
            }

            currentUser = try createProfile()
        } catch {
            errorMessage = "Could not open your profile: \(error.localizedDescription)"
        }
    }

    /// Creates the initial empty profile. Name and health details are filled in
    /// later from the profile setup screen; nothing here blocks first use.
    @discardableResult
    private func createProfile() throws -> User {
        // Reuse whatever id `currentProfileId` already settled on, so a record
        // written before this point still points at this profile.
        let user = User(
            id: Self.currentProfileId,
            email: "",
            firstName: "",
            lastName: "",
            privacyPolicyAccepted: false
        )
        SwiftDataStack.shared.context.insert(StoredUserProfile(user))
        try SwiftDataStack.shared.save()
        return user
    }

    func refreshCurrentUser() async {
        loadOrCreateProfile()
    }

    // MARK: - Updating

    func updateUserProfile(_ updatedUser: User) async throws {
        isLoading = true
        defer { isLoading = false }

        let id = updatedUser.id
        let descriptor = FetchDescriptor<StoredUserProfile>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            guard let stored = try SwiftDataStack.shared.context.fetch(descriptor).first else {
                throw RepositoryError.recordNotFound(id)
            }
            stored.apply(updatedUser)
            try SwiftDataStack.shared.save()
            currentUser = stored.domainModel
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Records the user's acceptance of the current privacy policy version.
    func acceptPrivacyPolicy(version: String) async throws {
        guard var user = currentUser else { return }
        user.privacyPolicyAccepted = true
        user.privacyPolicyAcceptedDate = Date.now
        user.privacyPolicyVersion = version
        try await updateUserProfile(user)
    }

    // MARK: - Deletion

    /// Erases everything this install holds and starts a fresh empty profile.
    ///
    /// With no server there is nothing to revoke and nothing to request — the
    /// delete happens here and is complete when this returns.
    func deleteAllLocalData() async throws {
        isLoading = true
        defer { isLoading = false }

        let profileId = currentProfileId

        do {
            try await MealRepository.shared.deleteAll(userId: profileId)
            try await SymptomRepository.shared.deleteAll(userId: profileId)
            try await MedicationRepository.shared.deleteAll(userId: profileId)
            try await MedicationDoseRepository.shared.deleteAll(userId: profileId)

            if let settings = try? await ReminderSettingsRepository.shared.fetch(forUser: profileId) {
                try await ReminderSettingsRepository.shared.delete(settings)
            }

            // Encrypted loose files written by earlier versions, plus any
            // cached profile image, live outside the store.
            try await LocalStorageService.shared.clearAllPrivateData()

            let descriptor = FetchDescriptor<StoredUserProfile>(
                predicate: #Predicate { $0.id == profileId }
            )
            for profile in try SwiftDataStack.shared.context.fetch(descriptor) {
                SwiftDataStack.shared.context.delete(profile)
            }
            try SwiftDataStack.shared.save()

            // Replaced rather than left absent, so the app still has an owner
            // for the next record the user logs. It keeps the same id — every
            // record that referenced it is gone, so there is nothing to
            // disambiguate from, and reusing it avoids a second source of truth.
            currentUser = try createProfile()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
