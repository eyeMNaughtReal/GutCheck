//
//  Symptom.swift
//  GutCheck
//
//  Updated to include FirestoreModel conformance
//

import Foundation
import FirebaseFirestore

// MARK: - Symptom Types
enum SymptomType: String, Codable, CaseIterable {
    case bowelMovement = "Bowel Movement"
    case pain = "Pain"
    case bloating = "Bloating"
    case nausea = "Nausea"
    case urgency = "Urgency"
    case other = "Other"
}

// MARK: - Related Enums
enum StoolType: Int, Codable, CaseIterable {
    case type1 = 1, type2, type3, type4, type5, type6, type7
}

enum PainLevel: Int, Codable, CaseIterable {
    case none = 0, mild = 1, moderate = 2, severe = 3
}

enum UrgencyLevel: Int, Codable, CaseIterable {
    case none = 0, mild = 1, moderate = 2, urgent = 3
}

// MARK: - Display Text
// Single source of truth for how symptom values are described in the UI.
// A bare "Type 7" is meaningless to a user; always pair it with `summary`.

extension StoolType {
    /// Short clinical summary, e.g. "Diarrhea".
    var summary: String {
        switch self {
        case .type1: return "Severe constipation"
        case .type2: return "Mild constipation"
        case .type3: return "Borderline normal"
        case .type4: return "Ideal"
        case .type5: return "Borderline normal"
        case .type6: return "Mild diarrhea"
        case .type7: return "Diarrhea"
        }
    }

    /// Physical consistency, e.g. "Watery liquid".
    var consistency: String {
        switch self {
        case .type1: return "Hard lumps"
        case .type2: return "Lumpy & sausage-like"
        case .type3: return "Sausage with cracks"
        case .type4: return "Smooth sausage"
        case .type5: return "Soft blobs"
        case .type6: return "Mushy consistency"
        case .type7: return "Watery liquid"
        }
    }
}

// `displayName` for PainLevel/UrgencyLevel already lives in
// Views/Bowel/PaginatedSymptomHistoryView.swift — not redeclared here.

struct Symptom: Identifiable, Codable, Hashable, Equatable, FirestoreModel {
    var id: String = UUID().uuidString
    var date: Date
    var stoolType: StoolType
    var painLevel: PainLevel
    var urgencyLevel: UrgencyLevel
    var notes: String?
    var tags: [String] = []
    var createdBy: String = ""  // Firebase UID - required for FirestoreModel

    /// When the record was written, as distinct from `date` (when the symptom
    /// occurred). Deduplication orders on `updatedAt` to keep the newer copy.
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    
    // MARK: - Privacy Classification
    
    /// Determines the privacy level of this symptom data
    /// This affects where and how the data is stored
    var privacyLevel: DataPrivacyLevel {
        // Detailed personal notes are private
        if let notes = notes, !notes.isEmpty {
            return .private
        }
        
        // High severity symptoms are private
        if painLevel == .severe || urgencyLevel == .urgent {
            return .private
        }
        
        // Personal tags make symptoms private
        if tags.contains("personal") || tags.contains("private") {
            return .private
        }
        
        // Basic symptom structure is non-private
        return .public
    }
    
    /// Whether this symptom requires local encrypted storage
    var requiresLocalStorage: Bool {
        return privacyLevel == .private || privacyLevel == .confidential
    }
    
    /// Whether this symptom can be synced to the cloud
    var allowsCloudSync: Bool {
        return privacyLevel == .public
    }
    
    // MARK: - Initializers
    init(id: String = UUID().uuidString, 
         date: Date, 
         stoolType: StoolType, 
         painLevel: PainLevel, 
         urgencyLevel: UrgencyLevel, 
         notes: String? = nil, 
         tags: [String] = [], 
         createdBy: String = "") {
        self.id = id
        self.date = date
        self.stoolType = stoolType
        self.painLevel = painLevel
        self.urgencyLevel = urgencyLevel
        self.notes = notes
        self.tags = tags
        self.createdBy = createdBy
    }
    
    // MARK: - FirestoreModel Implementation
    init(from document: DocumentSnapshot) throws {
        let data = document.data()
        guard let data = data else {
            throw RepositoryError.invalidData("Document data is nil")
        }
        
        self.id = document.documentID
        
        guard let timestamp = data["date"] as? Timestamp else {
            throw RepositoryError.invalidData("Missing or invalid date field")
        }
        self.date = timestamp.dateValue()
        
        guard let stoolTypeRaw = data["stoolType"] as? Int,
              let stoolType = StoolType(rawValue: stoolTypeRaw) else {
            throw RepositoryError.invalidData("Missing or invalid stoolType field")
        }
        self.stoolType = stoolType
        
        guard let painLevelRaw = data["painLevel"] as? Int,
              let painLevel = PainLevel(rawValue: painLevelRaw) else {
            throw RepositoryError.invalidData("Missing or invalid painLevel field")
        }
        self.painLevel = painLevel
        
        guard let urgencyLevelRaw = data["urgencyLevel"] as? Int,
              let urgencyLevel = UrgencyLevel(rawValue: urgencyLevelRaw) else {
            throw RepositoryError.invalidData("Missing or invalid urgencyLevel field")
        }
        self.urgencyLevel = urgencyLevel
        
        self.notes = data["notes"] as? String
        self.tags = data["tags"] as? [String] ?? []
        
        guard let createdBy = data["createdBy"] as? String else {
            throw RepositoryError.invalidData("Missing or invalid createdBy field")
        }
        self.createdBy = createdBy

        // `createdAt` was already being written but never read back, so
        // deduplication had no way to tell two copies of the same record apart.
        // Records predating these fields fall back to `date` for a usable ordering.
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? self.date
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? self.createdAt
    }

    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "date": Timestamp(date: date),
            "stoolType": stoolType.rawValue,
            "painLevel": painLevel.rawValue,
            "urgencyLevel": urgencyLevel.rawValue,
            "tags": tags,
            "createdBy": createdBy,
            // `date` is when the symptom occurred; these track when the record
            // was written, which is what conflict resolution needs.
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: Date.now)
        ]
        
        if let notes = notes {
            data["notes"] = notes
        }
        
        return data
    }
}
// MARK: - Timestamped Record

/// Records that carry a write timestamp, so duplicates arriving from local
/// storage and Firestore can be collapsed by keeping the most recent copy.
protocol TimestampedRecord: Identifiable {
    var id: String { get }
    var updatedAt: Date { get }
}

extension Symptom: TimestampedRecord {}
extension Meal: TimestampedRecord {}

extension Array where Element: TimestampedRecord {
    /// Collapses records sharing an id, keeping whichever was written most
    /// recently. Ordering of the result is left to the caller.
    ///
    /// The same record routinely arrives from both local storage and Firestore.
    /// Resolving on `updatedAt` means a newer edit always wins, rather than
    /// whichever copy happened to be appended first.
    func deduplicatedKeepingNewest() -> [Element] {
        var newestById: [String: Element] = [:]
        for record in self {
            if let existing = newestById[record.id], existing.updatedAt >= record.updatedAt {
                continue
            }
            newestById[record.id] = record
        }
        return Array(newestById.values)
    }
}
