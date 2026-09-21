import Testing
import HealthKit
@testable import GutCheck

/// Guards the Apple Health connection indicator.
///
/// Both of its previous forms were wrong, in opposite directions: the settings
/// row read "Not Connected" whenever no sync had run even if access was
/// granted, while the sheet read "Connected" whenever a `UserHealthData`
/// instance existed — which was always, because the fetch returned a struct of
/// all-nil fields rather than nil. These pin both.
@MainActor
struct HealthKitConnectionStateTests {

    // MARK: - hasAnyData

    @Test("An empty health payload reports no data")
    func emptyPayloadHasNoData() {
        // The whole bug in one assertion. `fetchUserHealthData` used to return
        // this value rather than nil, so `healthData != nil` was true even when
        // every permission had been denied.
        #expect(UserHealthData().hasAnyData == false)
    }

    @Test("A payload with a single value reports data")
    func singleValueHasData() {
        #expect(UserHealthData(weight: 70).hasAnyData == true)
    }

    @Test("Any one field is enough")
    func anyFieldCounts() {
        #expect(UserHealthData(heartRate: 61).hasAnyData == true)
        #expect(UserHealthData(bloodGlucose: 95).hasAnyData == true)
        #expect(UserHealthData(dateOfBirth: .now).hasAnyData == true)
    }

    // MARK: - Connection state

    @Test("Never having answered the permission sheet reads as not set up")
    func shouldRequestMeansNotSetUp() async {
        let mock = MockHealthKitManager()
        mock.authorizationRequestStatusToReturn = .shouldRequest

        let viewModel = HealthKitViewModel(healthKitManager: mock)
        await viewModel.refreshConnectionState()

        #expect(viewModel.connectionState == .notSetUp)
    }

    @Test("Answered permissions plus readable data reads as connected")
    func answeredWithDataIsConnected() async {
        let mock = MockHealthKitManager()
        mock.authorizationRequestStatusToReturn = .unnecessary
        mock.userHealthDataToReturn = UserHealthData(weight: 70)

        let viewModel = HealthKitViewModel(healthKitManager: mock)
        await viewModel.refreshConnectionState()

        #expect(viewModel.connectionState == .connected)
    }

    @Test("Answered permissions with nothing readable does not claim connected")
    func answeredWithoutDataIsNotConnected() async {
        // The regression that mattered on device: permissions answered, but
        // nothing came back. Claiming "Connected" here told someone their
        // Health data was flowing when it was not.
        let mock = MockHealthKitManager()
        mock.authorizationRequestStatusToReturn = .unnecessary
        mock.userHealthDataToReturn = nil

        let viewModel = HealthKitViewModel(healthKitManager: mock)
        await viewModel.refreshConnectionState()

        #expect(viewModel.connectionState == .connectedNoData)
        #expect(viewModel.connectionState != .connected)
    }

    @Test("An all-nil payload is treated as nothing readable")
    func allNilPayloadIsNotConnected() async {
        // Belt and braces. Even if some future fetch hands back an empty
        // struct instead of nil, the state must not read as connected.
        let mock = MockHealthKitManager()
        mock.authorizationRequestStatusToReturn = .unnecessary
        mock.userHealthDataToReturn = UserHealthData()

        let viewModel = HealthKitViewModel(healthKitManager: mock)
        await viewModel.refreshConnectionState()

        #expect(viewModel.connectionState == .connectedNoData)
    }

    // MARK: - Labels

    @Test("Every state has a label, and none of them says Not Connected")
    func labelsAreSet() {
        let states: [HealthKitViewModel.ConnectionState] = [
            .notSetUp, .connected, .connectedNoData, .needsAttention, .unavailable
        ]

        for state in states {
            #expect(!state.label.isEmpty)
            // "Not Connected" was the old caption shown to people who *were*
            // connected. The vocabulary deliberately no longer contains it.
            #expect(state.label != "Not Connected")
        }
    }
}
