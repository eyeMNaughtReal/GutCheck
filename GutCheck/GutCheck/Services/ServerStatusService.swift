//
//  ServerStatusService.swift
//  GutCheck
//
//  Monitors Firebase connectivity and network reachability.
//  Publishes state for the offline banner and server status sheet.
//

import Foundation
import Network
import FirebaseFirestore

@MainActor
class ServerStatusService: ObservableObject {
    static let shared = ServerStatusService()

    // MARK: - Published State

    @Published private(set) var isFirebaseReachable: Bool = true
    @Published private(set) var isNetworkAvailable: Bool = true
    @Published private(set) var secondsUntilRecheck: Int = 0
    @Published private(set) var isRechecking: Bool = false
    @Published private(set) var pendingChangesCount: Int = 0

    /// Toggle from debug views to simulate offline mode
    @Published var isDebugOfflineMode: Bool = false

    /// Convenience: true when the app should show offline UI
    var isOffline: Bool {
        isDebugOfflineMode || !isFirebaseReachable || !isNetworkAvailable
    }

    // MARK: - Private

    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.gutcheck.serverStatus")
    private var countdownTimer: Timer?
    private var isMonitoring = false

    private let recheckInterval: Int = 30

    private init() {}

    // MARK: - Lifecycle

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Start network path monitor
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isNetworkAvailable = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: monitorQueue)

        // Initial Firebase probe after a short delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s delay
            await performFirebaseCheck()
            startCountdown()
        }
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        networkMonitor.cancel()
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    // MARK: - Firebase Probe

    private func performFirebaseCheck() async {
        isRechecking = true
        do {
            let testDoc = FirebaseManager.shared.testDocument("status_check")
            _ = try await testDoc.getDocument(source: .server)
            // If we get here, the server responded — Firebase is reachable
            // (even if the document doesn't exist, the server still responded)
            isFirebaseReachable = true
        } catch let error as NSError {
            // Firestore error domain: "FIRFirestoreErrorDomain"
            // Code 14 = unavailable (server unreachable)
            // Code 7 = permission denied (server reachable, auth issue — treat as online)
            // Code 5 = not found (server reachable — treat as online)
            let firestoreUnavailableCodes = [14, 4, 13] // unavailable, deadline exceeded, internal
            if firestoreUnavailableCodes.contains(error.code) {
                isFirebaseReachable = false
            } else {
                // Server responded with an error (permission denied, not found, etc.)
                // This means Firebase IS reachable
                isFirebaseReachable = true
            }
        }
        isRechecking = false

        // Refresh pending changes count
        await refreshPendingChangesCount()
    }

    /// Refresh the pending changes count (call after queuing new offline data)
    func refreshPendingChanges() async {
        await refreshPendingChangesCount()
    }

    private func refreshPendingChangesCount() async {
        do {
            let unsynced = try await CoreDataStorageService.shared.getUnsyncedData()
            pendingChangesCount = unsynced.meals.count + unsynced.symptoms.count + unsynced.settings.count
        } catch {
            pendingChangesCount = 0
        }
    }

    // MARK: - Countdown Timer

    private func startCountdown() {
        secondsUntilRecheck = recheckInterval
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isMonitoring else { return }
                if self.secondsUntilRecheck > 1 {
                    self.secondsUntilRecheck -= 1
                } else {
                    self.secondsUntilRecheck = 0
                    await self.performFirebaseCheck()
                    self.startCountdown()
                }
            }
        }
    }
}
