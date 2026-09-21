import SwiftUI
import HealthKit

@MainActor
@Observable final class HealthKitViewModel {
    var healthData: UserHealthData?
    var isAuthorized = false
    var showPermissionError = false
    @ObservationIgnored @AppStorage("lastHealthKitSyncTimestamp") private var lastSyncTimestamp: Double = 0

    // MARK: - Write authorization statuses (keyed by identifier rawValue for Codable-free storage)
    var mealWriteStatuses:    [HKQuantityTypeIdentifier:  HKAuthorizationStatus] = [:]
    var symptomWriteStatuses: [HKCategoryTypeIdentifier:  HKAuthorizationStatus] = [:]

    /// True if any write type is not yet authorized (not determined or denied).
    var hasWriteIssues: Bool {
        let mealOK    = mealWriteStatuses.values.allSatisfy { $0 == .sharingAuthorized }
        let symptomOK = symptomWriteStatuses.values.allSatisfy { $0 == .sharingAuthorized }
        return !mealOK || !symptomOK
    }

    /// True if any write type is explicitly denied (user must go to Health app to fix).
    var hasDeniedWrites: Bool {
        mealWriteStatuses.values.contains { $0 == .sharingDenied } ||
        symptomWriteStatuses.values.contains { $0 == .sharingDenied }
    }

    /// True if any write type has never been requested (.notDetermined).
    var hasUndeterminedWrites: Bool {
        mealWriteStatuses.values.contains { $0 == .notDetermined } ||
        symptomWriteStatuses.values.contains { $0 == .notDetermined }
    }

    // MARK: - Connection State

    /// How the Apple Health connection should be described to a person.
    ///
    /// Note what is deliberately absent: a "read access granted" case. HealthKit
    /// never discloses read authorization — `authorizationStatus(for:)` reports
    /// sharing only, so that an app cannot infer that data is missing from a
    /// refusal to read it. Any state here is therefore evidence, not proof, and
    /// the wording is chosen to avoid claiming more than is known.
    enum ConnectionState: Equatable {
        /// The permission sheet has never been answered.
        case notSetUp
        /// Permissions were answered and data came back.
        case connected
        /// Permissions were answered but nothing could be read. Either access
        /// was refused or the Health app holds none of these metrics — the two
        /// are indistinguishable, so the copy must not accuse.
        case connectedNoData
        /// Answered, but some writes GutCheck needs are denied.
        case needsAttention
        /// No HealthKit on this hardware.
        case unavailable

        var label: String {
            switch self {
            case .notSetUp: "Not Set Up"
            case .connected: "Connected"
            case .connectedNoData: "No Data Yet"
            case .needsAttention: "Needs Attention"
            case .unavailable: "Unavailable"
            }
        }
    }

    /// Reflects authorization, not sync history.
    ///
    /// The settings row previously derived its caption from
    /// `lastHealthKitSyncTimestamp`, which meant granting access and never
    /// running a sync left it reading "Not Connected" indefinitely.
    var connectionState: ConnectionState = .notSetUp

    /// Recomputes `connectionState`. Cheap, and safe to call on appear.
    func refreshConnectionState() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            connectionState = .unavailable
            return
        }

        let requestStatus = await healthKitManager.authorizationRequestStatus()

        // `.shouldRequest` is the only honest signal that nobody has answered
        // the sheet yet. Treat `.unknown` as answered rather than showing "Not
        // Set Up" to someone who has already granted access.
        guard requestStatus != .shouldRequest else {
            connectionState = .notSetUp
            return
        }

        refreshWriteStatuses()

        // Distinguishing "connected" from "connected but nothing readable"
        // needs an actual read. Goes straight to the manager rather than
        // through `fetchHealthData()`, which calls back into this method.
        if healthData == nil {
            healthData = await healthKitManager.fetchUserHealthData()
        }

        if hasDeniedWrites {
            connectionState = .needsAttention
        } else if healthData?.hasAnyData == true {
            connectionState = .connected
        } else {
            connectionState = .connectedNoData
        }
    }


    // Inject settings and auth service for unit preferences and profile updates
    private var settingsViewModel: SettingsViewModel
    private var userService: LocalUserService
    private let healthKitManager: any HealthKitManagerProtocol
    
    init(healthKitManager: any HealthKitManagerProtocol = HealthKitManager.shared) {
        self.settingsViewModel = SettingsViewModel()
        self.userService = LocalUserService.shared
        self.healthKitManager = healthKitManager
    }
    
    init(settingsViewModel: SettingsViewModel, userService: LocalUserService, healthKitManager: any HealthKitManagerProtocol = HealthKitManager.shared) {
        self.settingsViewModel = settingsViewModel
        self.userService = userService
        self.healthKitManager = healthKitManager
    }
    
    // Allow updating dependencies after initialization (for environment objects)
    func updateDependencies(settingsViewModel: SettingsViewModel, userService: LocalUserService) {
        self.settingsViewModel = settingsViewModel
        self.userService = userService
    }

    func requestHealthKitAccess() async {
        do {
            try await healthKitManager.requestAuthorization()
            await fetchHealthData()
            isAuthorized = true
            HealthKitSyncManager.shared.markAuthorized()
        } catch {
            showPermissionError = true
        }
        // Always refresh write statuses after any authorization attempt
        refreshWriteStatuses()
        await refreshConnectionState()
    }

    func fetchHealthData() async {
        healthData = await healthKitManager.fetchUserHealthData()

        // `fetchUserHealthData` now returns nil when nothing could be read, so
        // this timestamp finally means "we actually got data" rather than "a
        // fetch was attempted".
        if healthData != nil {
            lastSyncTimestamp = Date.now.timeIntervalSince1970
        }

        await refreshConnectionState()
    }

    // MARK: - Write Authorization Status

    /// Reads the current authorization status for every write type from HealthKit.
    /// Call this on appear and after any authorization request.
    func refreshWriteStatuses() {
        let manager = healthKitManager

        let mealTypes: [HKQuantityTypeIdentifier] = [
            .dietaryEnergyConsumed,
            .dietaryCarbohydrates,
            .dietaryProtein,
            .dietaryFatTotal,
            .dietaryFiber,
            .dietarySugar,
            .dietarySodium
        ]
        for id in mealTypes {
            mealWriteStatuses[id] = manager.writeAuthorizationStatus(for: id)
        }

        let symptomTypes: [HKCategoryTypeIdentifier] = [
            .abdominalCramps,
            .diarrhea,
            .constipation,
            .bloating,
            .nausea
        ]
        for id in symptomTypes {
            symptomWriteStatuses[id] = manager.writeAuthorizationStatus(for: id)
        }
    }
    
    // Update user profile with health data
    func updateUserProfileWithHealthData() async {
        guard let healthData = healthData,
              let currentUser = userService.currentUser else {
            return
        }
        
        do {
            // Create updated user data
            var updatedUserData = currentUser
            updatedUserData.dateOfBirth = healthData.dateOfBirth
            updatedUserData.biologicalSex = healthData.biologicalSex
            updatedUserData.weight = healthData.weight
            updatedUserData.height = healthData.height
            
            // Update the user profile
            try await userService.updateUserProfile(updatedUserData)
        } catch {
        }
    }

    // Formatting helpers...
    func formattedAge() -> String {
        guard let dob = healthData?.dateOfBirth else { return "-" }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date.now)
        if let years = ageComponents.year {
            return String(years)
        }
        return "-"
    }

    func formattedHeight() -> String {
        guard let height = healthData?.height else { return "-" }
        let formatter = LengthFormatter()
        formatter.unitStyle = .medium
        
        switch settingsViewModel.unitOfMeasure {
        case .metric:
            return formatter.string(fromValue: height, unit: .meter)
        case .imperial:
            // Convert meters to feet
            let feet = height * 3.28084
            return formatter.string(fromValue: feet, unit: .foot)
        }
    }

    func formattedWeight() -> String {
        guard let weight = healthData?.weight else { return "-" }
        let formatter = MassFormatter()
        formatter.unitStyle = .medium
        
        switch settingsViewModel.unitOfMeasure {
        case .metric:
            return formatter.string(fromValue: weight, unit: .kilogram)
        case .imperial:
            // Convert kg to pounds
            let pounds = weight * 2.20462
            return formatter.string(fromValue: pounds, unit: .pound)
        }
    }
    
    func formattedBiologicalSex() -> String {
        guard let biologicalSex = healthData?.biologicalSex else { return "-" }
        switch biologicalSex {
        case .notSet:
            return "Not Set"
        case .female:
            return "Female"
        case .male:
            return "Male"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
}
