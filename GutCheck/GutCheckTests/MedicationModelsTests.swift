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

    // Dosage is persisted as a JSON blob inside StoredMedication, so the
    // Codable round-trip is what the storage layer actually depends on. It
    // replaced a dictionary round-trip that existed only for Firestore.
    @Test("MedicationDosage Codable round-trip preserves every field")
    func dosageCodableRoundTrip() throws {
        let original = MedicationDosage(
            amount: 100.0,
            unit: "mcg",
            frequency: .weekly,
            instructions: "Take in morning"
        )

        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(MedicationDosage.self, from: data)

        #expect(restored.amount == original.amount)
        #expect(restored.unit == original.unit)
        #expect(restored.frequency == original.frequency)
        #expect(restored.instructions == original.instructions)
    }

    @Test("MedicationDosage round-trips a nil instruction")
    func dosageCodableRoundTripWithoutInstructions() throws {
        let original = MedicationDosage(amount: 5, unit: "mg", frequency: .asNeeded)

        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(MedicationDosage.self, from: data)

        #expect(restored.instructions == nil)
        #expect(restored.frequency == .asNeeded)
    }

    // MARK: - MedicationRecord privacy classification

    @Test("MedicationRecord keeps the privacy level it was created with")
    func privacyLevelIsPreserved() {
        let publicRecord = MedicationRecord(
            name: "Vitamin D",
            dosage: MedicationDosage(amount: 1000, unit: "IU", frequency: .onceDaily),
            privacyLevel: .public
        )
        #expect(publicRecord.privacyLevel == .public)

        let privateRecord = MedicationRecord(
            name: "Medication X",
            dosage: MedicationDosage(amount: 50, unit: "mg", frequency: .twiceDaily),
            privacyLevel: .private
        )
        #expect(privateRecord.privacyLevel == .private)
        #expect(privateRecord.privacyLevel.requiresEncryption)
    }

    @Test("MedicationRecord defaults to private")
    func defaultsToPrivate() {
        let record = MedicationRecord(
            name: "Medication Y",
            dosage: MedicationDosage(amount: 10, unit: "mg", frequency: .onceDaily)
        )
        #expect(record.privacyLevel == .private)
    }
}
