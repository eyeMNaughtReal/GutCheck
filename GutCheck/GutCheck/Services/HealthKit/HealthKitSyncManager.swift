//
//  HealthKitSyncManager.swift
//  GutCheck
//
//  Manages automatic HealthKit data sync on app launch.
//  Skips the fetch if data was pulled within the last 15 minutes,
//  and skips the update if none of the tracked metrics have changed.
//

import Foundation
import HealthKit
import CryptoKit

@MainActor
@Observable class HealthKitSyncManager {
    static let shared = HealthKitSyncManager()

    var latestHealthData: UserHealthData?

    private let syncInterval: TimeInterval = 15 * 60 // 15 minutes
    private let authorizedKey   = "healthKitEverAuthorized"
    private let lastSyncKey     = "lastHealthKitSyncTimestamp"

    /// Digest of the last-seen metrics, used purely for change detection.
    ///
    /// This previously stored blood pressure, blood glucose, heart rate, weight
    /// and height as plain values in UserDefaults — an unencrypted plist in the
    /// app container — which CodeQL flagged as cleartext storage of sensitive
    /// information (alerts #5-#8). Nothing ever read those values back; they only
    /// answered "has anything changed since last sync?". A one-way digest answers
    /// that identically while persisting no health data at all.
    private let snapshotDigestKey = "hkSnap_digest"

    /// Pre-fix keys, removed on first run so existing installs don't keep
    /// cleartext health values sitting on disk.
    private static let legacySnapshotKeys = [
        "hkSnap_weight", "hkSnap_height", "hkSnap_systolic",
        "hkSnap_diastolic", "hkSnap_glucose", "hkSnap_heartRate"
    ]

    private init() {
        purgeLegacySnapshotIfNeeded()
    }

    /// Clears any plaintext health values written by earlier builds.
    private func purgeLegacySnapshotIfNeeded() {
        let defaults = UserDefaults.standard
        for key in Self.legacySnapshotKeys where defaults.object(forKey: key) != nil {
            defaults.removeObject(forKey: key)
        }
    }

    // Call this after the user successfully grants HealthKit authorization.
    func markAuthorized() {
        UserDefaults.standard.set(true, forKey: authorizedKey)
    }

    // Runs on every app-foreground event; skips quickly if not needed.
    func syncIfNeeded() async {
        guard UserDefaults.standard.bool(forKey: authorizedKey) else { return }
        guard UserDefaults.standard.bool(forKey: "healthKitSyncEnabled") else {
            return
        }
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let now = Date.now.timeIntervalSince1970
        let lastSync = UserDefaults.standard.double(forKey: lastSyncKey)

        guard now - lastSync >= syncInterval else {
            return
        }

        guard let data = await HealthKitAsyncWrapper.shared.fetchUserHealthData() else {
            return
        }

        // Always update the timestamp so we don't hammer HealthKit on failures
        UserDefaults.standard.set(now, forKey: lastSyncKey)

        guard hasChanges(data) else {
            return
        }

        saveSnapshot(data)
        latestHealthData = data
    }

    // MARK: - Change Detection

    /// SHA-256 over the tracked metrics. One-way, so nothing about the user's
    /// health can be recovered from what's persisted. `nil` is encoded distinctly
    /// from `0` so "not recorded" and "recorded as zero" don't collide.
    private func snapshotDigest(for data: UserHealthData) -> String {
        let fields: [Double?] = [
            data.weight,
            data.height,
            data.bloodPressureSystolic,
            data.bloodPressureDiastolic,
            data.bloodGlucose,
            data.heartRate
        ]
        let encoded: String = fields
            .map { value -> String in value.map { "\($0)" } ?? "nil" }
            .joined(separator: "|")
        return SHA256.hash(data: Data(encoded.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func hasChanges(_ data: UserHealthData) -> Bool {
        snapshotDigest(for: data) != UserDefaults.standard.string(forKey: snapshotDigestKey)
    }

    private func saveSnapshot(_ data: UserHealthData) {
        UserDefaults.standard.set(snapshotDigest(for: data), forKey: snapshotDigestKey)
    }
}
