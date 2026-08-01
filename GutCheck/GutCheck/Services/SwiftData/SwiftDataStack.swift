//
//  SwiftDataStack.swift
//  GutCheck
//
//  Owns the app's single SwiftData ModelContainer.
//
//  This replaces the previous Core Data stack and the Firestore hybrid that sat
//  on top of it. Everything the app records now lives in one on-device store —
//  there is no cloud tier, so there is no sync layer, no offline queue and no
//  privacy-based routing between two backends.
//

import Foundation
import SwiftData

@MainActor
@Observable final class SwiftDataStack {
    static let shared = SwiftDataStack()

    /// Every persisted entity in the app. Anything added here must also be added
    /// to `LegacyStoreMigrator` if old Core Data rows need to carry over.
    nonisolated static var schema: Schema {
        Schema([
            StoredMeal.self,
            StoredSymptom.self,
            StoredMedication.self,
            StoredMedicationDose.self,
            StoredReminderSettings.self,
            StoredUserProfile.self,
            StoredDataDeletionRequest.self
        ])
    }

    /// Directory holding the store file. Kept out of the Documents directory so
    /// it is not exposed via file sharing, and excluded from iCloud backup is
    /// *not* applied — the user's health history should survive a device restore.
    nonisolated static var storeDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("GutCheck", isDirectory: true)
    }

    nonisolated static var storeURL: URL {
        storeDirectory.appendingPathComponent("GutCheck.store")
    }

    @ObservationIgnored let container: ModelContainer

    /// The main-actor context. Every repository in the app is `@MainActor`, so a
    /// single context keeps object identity consistent and avoids cross-context
    /// merge handling for what is a modestly sized personal dataset.
    var context: ModelContext { container.mainContext }

    private init() {
        Self.createStoreDirectoryIfNeeded()

        let configuration = ModelConfiguration(
            schema: Self.schema,
            url: Self.storeURL
        )

        do {
            container = try ModelContainer(for: Self.schema, configurations: configuration)
        } catch {
            // A container that cannot open means the app has nowhere to record
            // anything. Continuing would silently discard every entry the user
            // makes, so fail loudly here rather than corrupting their history.
            fatalError("SwiftData store failed to load: \(error.localizedDescription)")
        }

        Self.applyFileProtection()
    }

    /// Test/preview seam: an in-memory container with the same schema.
    nonisolated static func inMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    // MARK: - Saving

    /// Saves pending changes. SwiftData autosaves, but writes that must be
    /// durable before the next step (deletions, migrations) call this directly.
    func save() throws {
        guard context.hasChanges else { return }
        try context.save()
    }

    // MARK: - Store file protection

    nonisolated private static func createStoreDirectoryIfNeeded() {
        let directory = storeDirectory
        guard !FileManager.default.fileExists(atPath: directory.path) else { return }
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUnlessOpen]
        )
    }

    /// Applies Data Protection to the store and its journal files.
    ///
    /// The store holds PII and health data — date of birth, weight, height,
    /// meals and symptoms. Without this it inherits iOS's default,
    /// `completeUntilFirstUserAuthentication`, which leaves the file readable
    /// from the first unlock after boot until power off.
    ///
    /// `.completeUnlessOpen` rather than `.complete` is deliberate, carried over
    /// from the Core Data stack this replaces: `.complete` makes the file
    /// unreadable whenever the device is locked, which breaks the
    /// BGProcessingTask insight refresh, since background tasks typically run
    /// while locked. `.completeUnlessOpen` protects the file at rest but lets a
    /// handle opened before locking keep working.
    nonisolated private static func applyFileProtection() {
        let attributes: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.completeUnlessOpen
        ]

        // SQLite keeps its write-ahead log and shared-memory file alongside the
        // store. Protecting only the store would leave recent writes readable.
        let paths = [
            storeURL,
            storeURL.appendingPathExtension("wal"),
            storeURL.appendingPathExtension("shm")
        ]

        for url in paths where FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
        }
    }
}
