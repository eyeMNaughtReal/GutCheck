import Testing
import Foundation
@testable import GutCheck

struct MedicationModelsTests {

    // MARK: - MedicationFrequency

    @Test("MedicationFrequency has all expected cases")
    func frequencyAllCases() {
        #expect(MedicationFrequency.allCases.count == 8)
    }

    @Test("MedicationFrequency displayNames are non-empty", arguments: MedicationFrequency.allCases)
    func frequencyDisplayNames(frequency: MedicationFrequency) {
        #expect(!frequency.displayName.isEmpty)
    }

    @Test("MedicationFrequency Codable round-trip", arguments: MedicationFrequency.allCases)
    func frequencyCodable(frequency: MedicationFrequency) throws {
        let data = try JSONEncoder().encode(frequency)
        let decoded = try JSONDecoder().decode(MedicationFrequency.self, from: data)
        #expect(decoded == frequency)
    }

    // MARK: - MedicationSource

    @Test("MedicationSource has all expected cases")
    func sourceAllCases() {
        #expect(MedicationSource.allCases.count == 4)
    }

    @Test("MedicationSource displayNames are non-empty", arguments: MedicationSource.allCases)
    func sourceDisplayNames(source: MedicationSource) {
        #expect(!source.displayName.isEmpty)
    }

    // MARK: - InteractionType

    @Test("InteractionType has all expected cases")
    func interactionTypeAllCases() {
        #expect(InteractionType.allCases.count == 6)
    }

    @Test("InteractionType displayNames are non-empty", arguments: InteractionType.allCases)
    func interactionTypeDisplayNames(type: InteractionType) {
        #expect(!type.displayName.isEmpty)
    }

    // MARK: - InteractionSeverity

    @Test("InteractionSeverity has all expected cases")
    func severityAllCases() {
        #expect(InteractionSeverity.allCases.count == 4)
    }

    @Test("InteractionSeverity displayNames and colors are non-empty", arguments: InteractionSeverity.allCases)
    func severityProperties(severity: InteractionSeverity) {
        #expect(!severity.displayName.isEmpty)
        #expect(!severity.color.isEmpty)
    }

    // MARK: - SideEffect enums

    @Test("SideEffectSeverity displayNames are non-empty", arguments: SideEffectSeverity.allCases)
    func sideEffectSeverityDisplayNames(severity: SideEffectSeverity) {
        #expect(!severity.displayName.isEmpty)
    }

    @Test("SideEffectFrequency displayNames are non-empty", arguments: SideEffectFrequency.allCases)
    func sideEffectFrequencyDisplayNames(frequency: SideEffectFrequency) {
        #expect(!frequency.displayName.isEmpty)
    }

    @Test("SideEffectOnset displayNames are non-empty", arguments: SideEffectOnset.allCases)
    func sideEffectOnsetDisplayNames(onset: SideEffectOnset) {
        #expect(!onset.displayName.isEmpty)
    }

    @Test("SideEffectDuration displayNames are non-empty", arguments: SideEffectDuration.allCases)
    func sideEffectDurationDisplayNames(duration: SideEffectDuration) {
        #expect(!duration.displayName.isEmpty)
    }

    // MARK: - DataPrivacyLevel

    @Test("DataPrivacyLevel has 3 levels")
    func privacyLevelCount() {
        #expect(DataPrivacyLevel.allCases.count == 3)
    }

    @Test("DataPrivacyLevel displayNames are non-empty", arguments: DataPrivacyLevel.allCases)
    func privacyLevelDisplayNames(level: DataPrivacyLevel) {
        #expect(!level.displayName.isEmpty)
    }

    @Test("Public level does not require encryption")
    func publicNoEncryption() {
        #expect(!DataPrivacyLevel.public.requiresEncryption)
    }

    @Test("Private level requires encryption")
    func privateRequiresEncryption() {
        #expect(DataPrivacyLevel.private.requiresEncryption)
    }

    @Test("Confidential level requires encryption")
    func confidentialRequiresEncryption() {
        #expect(DataPrivacyLevel.confidential.requiresEncryption)
    }

    // MARK: - MedicationDosage

    @Test("MedicationDosage initializer preserves values")
    func dosageInit() {
        let dosage = MedicationDosage(
            amount: 500.0,
            unit: "mg",
            frequency: .twiceDaily,
            instructions: "Take with food"
        )
        #expect(dosage.amount == 500.0)
        #expect(dosage.unit == "mg")
        #expect(dosage.frequency == .twiceDaily)
        #expect(dosage.instructions == "Take with food")
    }

    @Test("MedicationDosage from dictionary")
    func dosageFromDictionary() {
        let dict: [String: Any] = [
            "amount": 250.0,
            "unit": "ml",
            "frequency": "onceDaily",
            "instructions": "Before bed"
        ]
        let dosage = MedicationDosage(from: dict)
        #expect(dosage.amount == 250.0)
        #expect(dosage.unit == "ml")
        #expect(dosage.frequency == .onceDaily)
        #expect(dosage.instructions == "Before bed")
    }

    @Test("MedicationDosage from empty dictionary uses defaults")
    func dosageFromEmptyDictionary() {
        let dosage = MedicationDosage(from: [:])
        #expect(dosage.amount == 0.0)
        #expect(dosage.unit == "mg")
        #expect(dosage.frequency == .asNeeded)
        #expect(dosage.instructions == nil)
    }

    @Test("MedicationDosage toFirestore round-trip")
    func dosageFirestoreRoundTrip() {
        let original = MedicationDosage(
            amount: 100.0,
            unit: "mcg",
            frequency: .weekly,
            instructions: "Take in morning"
        )
        let dict = original.toFirestore()
        let restored = MedicationDosage(from: dict)
        #expect(restored.amount == original.amount)
        #expect(restored.unit == original.unit)
        #expect(restored.frequency == original.frequency)
        #expect(restored.instructions == original.instructions)
    }

    // MARK: - MedicationRecord computed properties

    @Test("MedicationRecord with public privacy allows cloud sync")
    func publicAllowsSync() {
        let record = MedicationRecord(
            name: "Vitamin D",
            dosage: MedicationDosage(amount: 1000, unit: "IU", frequency: .onceDaily),
            privacyLevel: .public
        )
        #expect(record.allowsCloudSync)
        #expect(!record.requiresLocalStorage)
    }

    @Test("MedicationRecord with private privacy requires local storage")
    func privateRequiresLocal() {
        let record = MedicationRecord(
            name: "Medication X",
            dosage: MedicationDosage(amount: 50, unit: "mg", frequency: .twiceDaily),
            privacyLevel: .private
        )
        #expect(!record.allowsCloudSync)
        #expect(record.requiresLocalStorage)
    }
}
