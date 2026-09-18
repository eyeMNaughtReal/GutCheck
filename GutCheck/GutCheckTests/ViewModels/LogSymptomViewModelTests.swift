import Testing
import Foundation
@testable import GutCheck

@MainActor
struct LogSymptomViewModelTests {

    // MARK: - Pain Level Mapping
    //
    // The picker in LogSymptomView exposes five levels; PainLevel has four
    // cases. These pin the mapping, which previously bucketed the picker index
    // on a 0-10 scale and so recorded "Severe" as mild.

    @Test(
        "Pain picker index maps onto the matching PainLevel",
        arguments: [
            (0, PainLevel.none),
            (1, PainLevel.mild),
            (2, PainLevel.moderate),
            (3, PainLevel.severe)
        ]
    )
    func painLevelForPickerIndex(index: Int, expected: PainLevel) {
        #expect(LogSymptomViewModel.painLevel(forPickerIndex: index) == expected)
    }

    @Test("Extreme collapses to severe, the strongest case PainLevel has")
    func extremePainMapsToSevere() {
        #expect(LogSymptomViewModel.painLevel(forPickerIndex: 4) == .severe)
    }

    @Test("Selecting Severe is recorded as severe, not mild")
    func severeIsNotDowngraded() {
        // The specific regression: index 3 is labelled "Severe" in the picker
        // and used to fall in the 1...3 → .mild bucket.
        #expect(LogSymptomViewModel.painLevel(forPickerIndex: 3) != .mild)
        #expect(LogSymptomViewModel.painLevel(forPickerIndex: 3) == .severe)
    }

    @Test("Every picker index produces a level the dashboard can act on")
    func pickerCoversModerateAndAbove() {
        // The dashboard's high-pain alert triggers at .moderate or worse, so at
        // least one reachable index must clear that bar.
        let reachable = (0...4).map { LogSymptomViewModel.painLevel(forPickerIndex: $0) }
        #expect(reachable.contains { $0 >= .moderate })
        #expect(reachable.contains(.severe))
    }
}
