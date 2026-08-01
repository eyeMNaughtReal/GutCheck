//
//  Symptom.swift
//  GutCheck
//

import Foundation

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

struct Symptom: Identifiable, Codable, Hashable, Equatable, LocalRecord {
    var id: String = UUID().uuidString
    var date: Date
    var stoolType: StoolType
    var painLevel: PainLevel
    var urgencyLevel: UrgencyLevel
    var notes: String?
    var tags: [String] = []
    /// The local profile that logged this record.
    var createdBy: String = ""

    /// When the record was written, as distinct from `date` (when the symptom
    /// occurred).
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    // MARK: - Privacy Classification

    /// How sensitive this symptom is. Everything is stored on-device, so this
    /// no longer decides *where* the record goes — it marks which entries carry
    /// free-text or high-severity detail, which the healthcare export uses to
    /// decide what may leave the device.
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
}

// MARK: - Timestamped Record

/// Records that carry a write timestamp, so copies sharing an id can be
/// collapsed by keeping the most recent one.
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
    /// The store's unique index on `id` keeps duplicates out of SwiftData, but
    /// results merged from more than one source — a query plus an import, say —
    /// can still repeat an id. Resolving on `updatedAt` means a newer edit
    /// always wins, rather than whichever copy happened to be appended first.
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
