import SwiftUI
import HealthKit

@MainActor
final class HealthKitViewModel: ObservableObject {
    @Published var healthData: UserHealthData?
    @Published var isAuthorized = false
    @Published var showPermissionError = false
    @AppStorage("lastHealthKitSyncTimestamp") private var lastSyncTimestamp: Double = 0

    // MARK: - Write authorization statuses (keyed by identifier rawValue for Codable-free storage)
    @Published var mealWriteStatuses:    [HKQuantityTypeIdentifier:  HKAuthorizationStatus] = [:]
    @Published var symptomWriteStatuses: [HKCategoryTypeIdentifier:  HKAuthorizationStatus] = [:]

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
    
    // Inject settings and auth service for unit preferences and profile updates
    private var settingsViewModel: SettingsViewModel
    private var authService: AuthService
    
    init() {
        self.settingsViewModel = SettingsViewModel()
        self.authService = AuthService()
    }
    
    init(settingsViewModel: SettingsViewModel, authService: AuthService) {
        self.settingsViewModel = settingsViewModel
        self.authService = authService
    }
    
    // Allow updating dependencies after initialization (for environment objects)
    func updateDependencies(settingsViewModel: SettingsViewModel, authService: AuthService) {
        self.settingsViewModel = settingsViewModel
        self.authService = authService
    }

    func requestHealthKitAccess() async {
        let granted = await HealthKitAsyncWrapper.shared.requestAuthorizationWithLogging()

        if granted {
            await fetchHealthData()
            isAuthorized = true
            HealthKitSyncManager.shared.markAuthorized()
        } else {
            showPermissionError = true
        }
        // Always refresh write statuses after any authorization attempt
        refreshWriteStatuses()
    }

    func fetchHealthData() async {
        healthData = await HealthKitAsyncWrapper.shared.fetchUserHealthDataWithLogging()
        if healthData != nil {
            lastSyncTimestamp = Date().timeIntervalSince1970
        }
    }

    // MARK: - Write Authorization Status

    /// Reads the current authorization status for every write type from HealthKit.
    /// Call this on appear and after any authorization request.
    func refreshWriteStatuses() {
        let manager = HealthKitManager.shared

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
              let currentUser = authService.currentUser else {
            print("HealthKit: No health data or user available for profile update")
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
            try await authService.updateUserProfile(updatedUserData)
            print("HealthKit: Successfully updated user profile with health data")
        } catch {
            print("HealthKit: Failed to update user profile: \(error.localizedDescription)")
        }
    }

    // Formatting helpers...
    func formattedAge() -> String {
        guard let dob = healthData?.dateOfBirth else { return "-" }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
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
