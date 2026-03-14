import Testing
import Foundation
@testable import GutCheck

struct SymptomModelTests {

    // MARK: - SymptomType enum

    @Test("SymptomType has all expected cases")
    func symptomTypeAllCases() {
        let cases = SymptomType.allCases
        #expect(cases.count == 6)
        #expect(cases.contains(.bowelMovement))
        #expect(cases.contains(.pain))
        #expect(cases.contains(.bloating))
        #expect(cases.contains(.nausea))
        #expect(cases.contains(.urgency))
        #expect(cases.contains(.other))
    }

    @Test("SymptomType raw values match display strings", arguments: SymptomType.allCases)
    func symptomTypeRawValues(type: SymptomType) {
        #expect(!type.rawValue.isEmpty)
    }

    // MARK: - StoolType enum

    @Test("StoolType has 7 cases for Bristol scale")
    func stoolTypeCount() {
        #expect(StoolType.allCases.count == 7)
    }

    @Test("StoolType raw values are 1-7")
    func stoolTypeRawValues() {
        #expect(StoolType.type1.rawValue == 1)
        #expect(StoolType.type7.rawValue == 7)
    }

    // MARK: - PainLevel enum

    @Test("PainLevel has 4 levels")
    func painLevelCount() {
        #expect(PainLevel.allCases.count == 4)
    }

    @Test("PainLevel raw values are ordered 0-3")
    func painLevelOrdered() {
        #expect(PainLevel.none.rawValue == 0)
        #expect(PainLevel.mild.rawValue == 1)
        #expect(PainLevel.moderate.rawValue == 2)
        #expect(PainLevel.severe.rawValue == 3)
    }

    // MARK: - UrgencyLevel enum

    @Test("UrgencyLevel has 4 levels")
    func urgencyLevelCount() {
        #expect(UrgencyLevel.allCases.count == 4)
    }

    @Test("UrgencyLevel raw values are ordered 0-3")
    func urgencyLevelOrdered() {
        #expect(UrgencyLevel.none.rawValue == 0)
        #expect(UrgencyLevel.mild.rawValue == 1)
        #expect(UrgencyLevel.moderate.rawValue == 2)
        #expect(UrgencyLevel.urgent.rawValue == 3)
    }

    // MARK: - Symptom computed properties

    @Test("Symptom with notes is private")
    func symptomWithNotesIsPrivate() {
        let symptom = Symptom(
            date: Date(),
            stoolType: .type4,
            painLevel: .none,
            urgencyLevel: .none,
            notes: "Some personal notes"
        )
        #expect(symptom.privacyLevel == .private)
        #expect(symptom.requiresLocalStorage)
        #expect(!symptom.allowsCloudSync)
    }

    @Test("Symptom with severe pain is private")
    func severePainIsPrivate() {
        let symptom = Symptom(
            date: Date(),
            stoolType: .type4,
            painLevel: .severe,
            urgencyLevel: .none
        )
        #expect(symptom.privacyLevel == .private)
    }

    @Test("Symptom with urgent urgency is private")
    func urgentIsPrivate() {
        let symptom = Symptom(
            date: Date(),
            stoolType: .type4,
            painLevel: .none,
            urgencyLevel: .urgent
        )
        #expect(symptom.privacyLevel == .private)
    }

    @Test("Symptom with personal tag is private")
    func personalTagIsPrivate() {
        let symptom = Symptom(
            date: Date(),
            stoolType: .type4,
            painLevel: .none,
            urgencyLevel: .none,
            tags: ["personal"]
        )
        #expect(symptom.privacyLevel == .private)
    }

    @Test("Basic symptom without notes or severity is public")
    func basicSymptomIsPublic() {
        let symptom = Symptom(
            date: Date(),
            stoolType: .type4,
            painLevel: .none,
            urgencyLevel: .none
        )
        #expect(symptom.privacyLevel == .public)
        #expect(!symptom.requiresLocalStorage)
        #expect(symptom.allowsCloudSync)
    }

    // MARK: - Symptom Codable

    @Test("SymptomType Codable round-trip")
    func symptomTypeCodable() throws {
        let original = SymptomType.bowelMovement
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SymptomType.self, from: data)
        #expect(decoded == original)
    }

    @Test("PainLevel Codable round-trip")
    func painLevelCodable() throws {
        let original = PainLevel.moderate
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PainLevel.self, from: data)
        #expect(decoded == original)
    }
}
