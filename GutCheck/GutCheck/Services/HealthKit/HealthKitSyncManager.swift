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

@MainActor
class HealthKitSyncManager: ObservableObject {
    static let shared = HealthKitSyncManager()

    @Published var latestHealthData: UserHealthData?

    private let syncInterval: TimeInterval = 15 * 60 // 15 minutes
    private let authorizedKey   = "healthKitEverAuthorized"
    private let lastSyncKey     = "lastHealthKitSyncTimestamp"

    // UserDefaults keys for stored snapshot (change detection)
    private enum SnapshotKey {
        static let weight    = "hkSnap_weight"
        static let height    = "hkSnap_height"
        static let systolic  = "hkSnap_systolic"
        static let diastolic = "hkSnap_diastolic"
        static let glucose   = "hkSnap_glucose"
        static let heartRate = "hkSnap_heartRate"
    }

    private init() {}

    // Call this after the user successfully grants HealthKit authorization.
    func markAuthorized() {
        UserDefaults.standard.set(true, forKey: authorizedKey)
    }

    // Runs on every app-foreground event; skips quickly if not needed.
    func syncIfNeeded() async {
        guard UserDefaults.standard.bool(forKey: authorizedKey) else { return }
        guard UserDefaults.standard.bool(forKey: "healthKitSyncEnabled") else {
            print("ℹ️ HealthKitSyncManager: Skipping — sync disabled by user preference")
            return
        }
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let now = Date().timeIntervalSince1970
        let lastSync = UserDefaults.standard.double(forKey: lastSyncKey)

        guard now - lastSync >= syncInterval else {
            print("ℹ️ HealthKitSyncManager: Skipping — synced \(Int((now - lastSync) / 60)) min ago")
            return
        }

        guard let data = await HealthKitAsyncWrapper.shared.fetchUserHealthData() else {
            print("⚠️ HealthKitSyncManager: No data returned from HealthKit")
            return
        }

        // Always update the timestamp so we don't hammer HealthKit on failures
        UserDefaults.standard.set(now, forKey: lastSyncKey)

        guard hasChanges(data) else {
            print("ℹ️ HealthKitSyncManager: No changes detected in HealthKit data")
            return
        }

        saveSnapshot(data)
        latestHealthData = data
        print("✅ HealthKitSyncManager: Health data updated — changes detected")
    }

    // MARK: - Change Detection

    private func hasChanges(_ data: UserHealthData) -> Bool {
        let d = UserDefaults.standard
        return (data.weight ?? 0)                != d.double(forKey: SnapshotKey.weight)
            || (data.height ?? 0)                != d.double(forKey: SnapshotKey.height)
            || (data.bloodPressureSystolic ?? 0)  != d.double(forKey: SnapshotKey.systolic)
            || (data.bloodPressureDiastolic ?? 0) != d.double(forKey: SnapshotKey.diastolic)
            || (data.bloodGlucose ?? 0)           != d.double(forKey: SnapshotKey.glucose)
            || (data.heartRate ?? 0)              != d.double(forKey: SnapshotKey.heartRate)
    }

    private func saveSnapshot(_ data: UserHealthData) {
        let d = UserDefaults.standard
        d.set(data.weight ?? 0,                forKey: SnapshotKey.weight)
        d.set(data.height ?? 0,                forKey: SnapshotKey.height)
        d.set(data.bloodPressureSystolic ?? 0,  forKey: SnapshotKey.systolic)
        d.set(data.bloodPressureDiastolic ?? 0, forKey: SnapshotKey.diastolic)
        d.set(data.bloodGlucose ?? 0,           forKey: SnapshotKey.glucose)
        d.set(data.heartRate ?? 0,              forKey: SnapshotKey.heartRate)
    }
}
