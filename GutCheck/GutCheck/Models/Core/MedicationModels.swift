import Foundation
import FirebaseFirestore
import HealthKit

// MARK: - Core Medication Models

struct MedicationRecord: Identifiable, Codable, Hashable, FirestoreModel {

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
    
    // MARK: - DataClassifiable Conformance
    
    /// Whether this medication record requires local encrypted storage
    var requiresLocalStorage: Bool {
        return privacyLevel == .private || privacyLevel == .confidential
    }
    
    /// Whether this medication record can be synced to the cloud
    var allowsCloudSync: Bool {
        return privacyLevel == .public
    }
    
    init(
        id: String = UUID().uuidString,
        createdBy: String = "",
        name: String,
        dosage: MedicationDosage,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true,
        notes: String? = nil,
        source: MedicationSource = .manual,
        privacyLevel: DataPrivacyLevel = .private,
        healthKitUUID: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
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
    
    // MARK: - FirestoreModel Conformance
    
    static var collectionName: String { "medications" }
    
    init(from document: DocumentSnapshot) throws {
        guard let data = document.data() else {
            throw RepositoryError.invalidData("Document data is nil")
        }
        
        let id = document.documentID
        let createdBy = data["createdBy"] as? String ?? ""
        let name = data["name"] as? String ?? ""
        let dosageData = data["dosage"] as? [String: Any] ?? [:]
        let dosage = MedicationDosage(from: dosageData)
        let startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
        let endDate = (data["endDate"] as? Timestamp)?.dateValue()
        let isActive = data["isActive"] as? Bool ?? true
        let notes = data["notes"] as? String
        let sourceRaw = data["source"] as? String ?? "manual"
        let source = MedicationSource(rawValue: sourceRaw) ?? .manual
        let privacyRaw = data["privacyLevel"] as? String ?? "private"
        let privacyLevel = DataPrivacyLevel(rawValue: privacyRaw) ?? .private
        let healthKitUUIDString = data["healthKitUUID"] as? String
        let healthKitUUID = healthKitUUIDString.flatMap { UUID(uuidString: $0) }
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        
        self.init(
            id: id,
            createdBy: createdBy,
            name: name,
            dosage: dosage,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            notes: notes,
            source: source,
            privacyLevel: privacyLevel,
            healthKitUUID: healthKitUUID,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "createdBy": createdBy,
            "name": name,
            "dosage": dosage.toFirestore(),
            "startDate": Timestamp(date: startDate),
            "isActive": isActive,
            "source": source.rawValue,
            "privacyLevel": privacyLevel.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let endDate = endDate {
            data["endDate"] = Timestamp(date: endDate)
        }
        
        if let notes = notes {
            data["notes"] = notes
        }
        
        if let healthKitUUID = healthKitUUID {
            data["healthKitUUID"] = healthKitUUID.uuidString
        }
        
        return data
    }
}

struct MedicationDosage: Codable {
    let amount: Double
    let unit: String
    let frequency: MedicationFrequency
    let instructions: String?
    
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
    
    init(from data: [String: Any]) {
        self.amount = data["amount"] as? Double ?? 0.0
        self.unit = data["unit"] as? String ?? "mg"
        let frequencyRaw = data["frequency"] as? String ?? "asNeeded"
        self.frequency = MedicationFrequency(rawValue: frequencyRaw) ?? .asNeeded
        self.instructions = data["instructions"] as? String
    }
    
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "amount": amount,
            "unit": unit,
            "frequency": frequency.rawValue
        ]
        
        if let instructions = instructions {
            data["instructions"] = instructions
        }
        
        return data
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
struct MedicationDoseLog: Identifiable, Codable, FirestoreModel {
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

    // MARK: - DataClassifiable

    var requiresLocalStorage: Bool { privacyLevel != .public }
    var allowsCloudSync: Bool     { privacyLevel == .public }

    // MARK: - Init

    init(
        id: String = UUID().uuidString,
        createdBy: String = "",
        medicationId: String,
        medicationName: String,
        dosageAmount: Double,
        dosageUnit: String,
        dateTaken: Date = Date(),
        notes: String? = nil,
        privacyLevel: DataPrivacyLevel = .private,
        createdAt: Date = Date()
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

    // MARK: - FirestoreModel

    static var collectionName: String { "medicationDoses" }

    init(from document: DocumentSnapshot) throws {
        guard let data = document.data() else {
            throw RepositoryError.invalidData("Document data is nil")
        }
        self.id             = document.documentID
        self.createdBy      = data["createdBy"]      as? String ?? ""
        self.medicationId   = data["medicationId"]   as? String ?? ""
        self.medicationName = data["medicationName"] as? String ?? ""
        self.dosageAmount   = data["dosageAmount"]   as? Double ?? 0.0
        self.dosageUnit     = data["dosageUnit"]     as? String ?? "mg"
        self.dateTaken      = (data["dateTaken"]  as? Timestamp)?.dateValue() ?? Date()
        self.notes          = data["notes"]          as? String
        let privacyRaw      = data["privacyLevel"]   as? String ?? "private"
        self.privacyLevel   = DataPrivacyLevel(rawValue: privacyRaw) ?? .private
        self.createdAt      = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    }

    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "createdBy":      createdBy,
            "medicationId":   medicationId,
            "medicationName": medicationName,
            "dosageAmount":   dosageAmount,
            "dosageUnit":     dosageUnit,
            "dateTaken":      Timestamp(date: dateTaken),
            "privacyLevel":   privacyLevel.rawValue,
            "createdAt":      Timestamp(date: createdAt)
        ]
        if let notes = notes { data["notes"] = notes }
        return data
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
        createdAt: Date = Date()
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
        createdAt: Date = Date()
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

