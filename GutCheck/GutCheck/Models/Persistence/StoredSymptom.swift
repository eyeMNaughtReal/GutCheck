//
//  StoredSymptom.swift
//  GutCheck
//
//  SwiftData entity backing the `Symptom` domain struct.
//

import Foundation
import SwiftData

@Model
final class StoredSymptom {
    @Attribute(.unique) var id: String

    var date: Date

    /// Stored as `Int` raw values so `#Predicate` can compare them directly.
    var stoolTypeRawValue: Int
    var painLevelRawValue: Int
    var urgencyLevelRawValue: Int

    var notes: String?
    var tags: [String]
    var createdBy: String

    /// When the record was written, as distinct from `date` (when the symptom
    /// occurred).
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        date: Date,
        stoolTypeRawValue: Int,
        painLevelRawValue: Int,
        urgencyLevelRawValue: Int,
        notes: String?,
        tags: [String],
        createdBy: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.date = date
        self.stoolTypeRawValue = stoolTypeRawValue
        self.painLevelRawValue = painLevelRawValue
        self.urgencyLevelRawValue = urgencyLevelRawValue
        self.notes = notes
        self.tags = tags
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Domain mapping

extension StoredSymptom {
    convenience init(_ symptom: Symptom) {
        self.init(
            id: symptom.id,
            date: symptom.date,
            stoolTypeRawValue: symptom.stoolType.rawValue,
            painLevelRawValue: symptom.painLevel.rawValue,
            urgencyLevelRawValue: symptom.urgencyLevel.rawValue,
            notes: symptom.notes,
            tags: symptom.tags,
            createdBy: symptom.createdBy,
            createdAt: symptom.createdAt,
            updatedAt: symptom.updatedAt
        )
    }

    /// Applies an edited symptom onto the existing row, preserving `createdAt`.
    func apply(_ symptom: Symptom) {
        date = symptom.date
        stoolTypeRawValue = symptom.stoolType.rawValue
        painLevelRawValue = symptom.painLevel.rawValue
        urgencyLevelRawValue = symptom.urgencyLevel.rawValue
        notes = symptom.notes
        tags = symptom.tags
        createdBy = symptom.createdBy
        updatedAt = Date.now
    }

    var domainModel: Symptom {
        var symptom = Symptom(
            id: id,
            date: date,
            stoolType: StoolType(rawValue: stoolTypeRawValue) ?? .type4,
            painLevel: PainLevel(rawValue: painLevelRawValue) ?? .none,
            urgencyLevel: UrgencyLevel(rawValue: urgencyLevelRawValue) ?? .none,
            notes: notes,
            tags: tags,
            createdBy: createdBy
        )
        symptom.createdAt = createdAt
        symptom.updatedAt = updatedAt
        return symptom
    }
}
