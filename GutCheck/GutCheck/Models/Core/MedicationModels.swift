import Foundation
import HealthKit

// MARK: - Core Medication Models

struct MedicationRecord: Identifiable, Codable, Hashable, LocalRecord {

    // Identity-based equality and hashing — avoids requiring all nested
    // types to be Hashable.
    static func == (lhs: MedicationRecord, rhs: MedicationRecord) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var id: String
    var createdBy: String
    let name: String
    let dosage: MedicationDosage
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    let notes: String?
    let source: MedicationSource
    let privacyLevel: DataPrivacyLevel
    let healthKitUUID: UUID?
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        createdBy: String = "",
        name: String,
        dosage: MedicationDosage,
        startDate: Date = Date.now,
        endDate: Date? = nil,
        isActive: Bool = true,
        notes: String? = nil,
        source: MedicationSource = .manual,
        privacyLevel: DataPrivacyLevel = .private,
        healthKitUUID: UUID? = nil,
        createdAt: Date = Date.now,
        updatedAt: Date = Date.now
    ) {
        self.id = id
        self.createdBy = createdBy
        self.name = name
        self.dosage = dosage
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.notes = notes
        self.source = source
        self.privacyLevel = privacyLevel
        self.healthKitUUID = healthKitUUID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct MedicationDosage: Codable {
    let amount: Double
    let unit: String
    let frequency: MedicationFrequency
    let instructions: String?

    /// "20 mg" rather than "20.0 mg" — whole numbers drop the decimal.
    /// Use this everywhere a dose is displayed so formatting matches across screens.
    var formatted: String {
        let amountText = amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(amount))
            : amount.formatted(.number.precision(.fractionLength(1)))
        return "\(amountText) \(unit)"
    }

    init(
        amount: Double,
        unit: String,
        frequency: MedicationFrequency,
        instructions: String? = nil
    ) {
        self.amount = amount
        self.unit = unit
        self.frequency = frequency
        self.instructions = instructions
    }
}

enum MedicationFrequency: String, CaseIterable, Codable {
    case onceDaily = "onceDaily"
    case twiceDaily = "twiceDaily"
    case threeTimesDaily = "threeTimesDaily"
    case fourTimesDaily = "fourTimesDaily"
    case asNeeded = "asNeeded"
    case weekly = "weekly"
    case monthly = "monthly"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .onceDaily: return "Once Daily"
        case .twiceDaily: return "Twice Daily"
        case .threeTimesDaily: return "Three Times Daily"
        case .fourTimesDaily: return "Four Times Daily"
        case .asNeeded: return "As Needed"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .custom: return "Custom"
        }
    }
}

enum MedicationSource: String, CaseIterable, Codable {
    case manual = "manual"
    case healthKit = "healthKit"
    case pharmacy = "pharmacy"
    case doctor = "doctor"
    
    var displayName: String {
        switch self {
        case .manual: return "Manual Entry"
        case .healthKit: return "Health App"
        case .pharmacy: return "Pharmacy"
        case .doctor: return "Doctor"
        }
    }
}

// MARK: - Medication Dose Log

/// Records a single instance of a user taking a medication dose.
struct MedicationDoseLog: Identifiable, Codable, LocalRecord {
    var id: String
    var createdBy: String
    /// The `MedicationRecord.id` this dose belongs to.
    let medicationId: String
    /// Denormalized name so doses can be displayed without a secondary fetch.
    let medicationName: String
    let dosageAmount: Double
    let dosageUnit: String
    /// The actual date + time the dose was taken.
    let dateTaken: Date
    let notes: String?
    let privacyLevel: DataPrivacyLevel
    let createdAt: Date

    // MARK: - Init

    init(
        id: String = UUID().uuidString,
        createdBy: String = "",
        medicationId: String,
        medicationName: String,
        dosageAmount: Double,
        dosageUnit: String,
        dateTaken: Date = Date.now,
        notes: String? = nil,
        privacyLevel: DataPrivacyLevel = .private,
        createdAt: Date = Date.now
    ) {
        self.id             = id
        self.createdBy      = createdBy
        self.medicationId   = medicationId
        self.medicationName = medicationName
        self.dosageAmount   = dosageAmount
        self.dosageUnit     = dosageUnit
        self.dateTaken      = dateTaken
        self.notes          = notes
        self.privacyLevel   = privacyLevel
        self.createdAt      = createdAt
    }
}

// MARK: - Medication Interaction Models

struct MedicationInteraction: Identifiable, Codable {
    let id: String
    let medicationId: String
    let foodItemId: String?
    let interactionType: InteractionType
    let severity: InteractionSeverity
    let description: String
    let recommendations: [String]
    let source: String
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        medicationId: String,
        foodItemId: String? = nil,
        interactionType: InteractionType,
        severity: InteractionSeverity,
        description: String,
        recommendations: [String],
        source: String = "AI Analysis",
        createdAt: Date = Date.now
    ) {
        self.id = id
        self.medicationId = medicationId
        self.foodItemId = foodItemId
        self.interactionType = interactionType
        self.severity = severity
        self.description = description
        self.recommendations = recommendations
        self.source = source
        self.createdAt = createdAt
    }
}

enum InteractionType: String, CaseIterable, Codable {
    case absorption = "absorption"
    case metabolism = "metabolism"
    case excretion = "excretion"
    case effectiveness = "effectiveness"
    case sideEffects = "sideEffects"
    case toxicity = "toxicity"
    
    var displayName: String {
        switch self {
        case .absorption: return "Absorption"
        case .metabolism: return "Metabolism"
        case .excretion: return "Excretion"
        case .effectiveness: return "Effectiveness"
        case .sideEffects: return "Side Effects"
        case .toxicity: return "Toxicity"
        }
    }
}

enum InteractionSeverity: String, CaseIterable, Codable {
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        case .critical: return "Critical"
        }
    }
    
    var color: String {
        switch self {
        case .mild: return "green"
        case .moderate: return "yellow"
        case .severe: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - Side Effect Models

struct SideEffect: Identifiable, Codable {
    let id: String
    let medicationId: String
    let name: String
    let description: String
    let severity: SideEffectSeverity
    let frequency: SideEffectFrequency
    let onset: SideEffectOnset
    let duration: SideEffectDuration
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        medicationId: String,
        name: String,
        description: String,
        severity: SideEffectSeverity,
        frequency: SideEffectFrequency,
        onset: SideEffectOnset,
        duration: SideEffectDuration,
        createdAt: Date = Date.now
    ) {
        self.id = id
        self.medicationId = medicationId
        self.name = name
        self.description = description
        self.severity = severity
        self.frequency = frequency
        self.onset = onset
        self.duration = duration
        self.createdAt = createdAt
    }
}

enum SideEffectSeverity: String, CaseIterable, Codable {
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"
    
    var displayName: String {
        switch self {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }
}

enum SideEffectFrequency: String, CaseIterable, Codable {
    case rare = "rare"
    case uncommon = "uncommon"
    case common = "common"
    case veryCommon = "veryCommon"
    
    var displayName: String {
        switch self {
        case .rare: return "Rare (<1%)"
        case .uncommon: return "Uncommon (1-10%)"
        case .common: return "Common (10-30%)"
        case .veryCommon: return "Very Common (>30%)"
        }
    }
}

enum SideEffectOnset: String, CaseIterable, Codable {
    case immediate = "immediate"
    case rapid = "rapid"
    case delayed = "delayed"
    
    var displayName: String {
        switch self {
        case .immediate: return "Immediate (<1 hour)"
        case .rapid: return "Rapid (1-24 hours)"
        case .delayed: return "Delayed (>24 hours)"
        }
    }
}

enum SideEffectDuration: String, CaseIterable, Codable {
    case short = "short"
    case medium = "medium"
    case long = "long"
    case permanent = "permanent"
    
    var displayName: String {
        switch self {
        case .short: return "Short (<1 day)"
        case .medium: return "Medium (1-7 days)"
        case .long: return "Long (1-4 weeks)"
        case .permanent: return "Permanent"
        }
    }
}

// MARK: - Data Privacy

/// Records that carry a sensitivity classification.
///
/// This used to decide which backend a record was written to. Everything now
/// lives in one on-device SwiftData store, so the classification is purely
/// descriptive: it marks which entries hold free-text or high-severity detail
/// so features that move data off the device — the healthcare export above all
/// — can treat them differently from bare structural data.
protocol DataClassifiable {
    var privacyLevel: DataPrivacyLevel { get }
}

enum DataPrivacyLevel: String, CaseIterable, Codable {
    case `public` = "public"
    case `private` = "private"
    case confidential = "confidential"
    
    var displayName: String {
        switch self {
        case .public: return "Public"
        case .private: return "Private"
        case .confidential: return "Confidential"
        }
    }
    
    var requiresEncryption: Bool {
        switch self {
        case .public: return false
        case .private: return true
        case .confidential: return true
        }
    }
}

extension Meal: DataClassifiable {}
extension Symptom: DataClassifiable {}
extension MedicationRecord: DataClassifiable {}
extension MedicationDoseLog: DataClassifiable {}
extension ReminderSettings: DataClassifiable {}

