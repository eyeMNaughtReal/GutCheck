//
//  StoredMedication.swift
//  GutCheck
//
//  SwiftData entities backing `MedicationRecord` and `MedicationDoseLog`.
//

import Foundation
import SwiftData

@Model
final class StoredMedication {
    @Attribute(.unique) var id: String

    var createdBy: String
    var name: String
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var notes: String?
    var sourceRawValue: String
    var privacyLevelRawValue: String
    var healthKitUUID: UUID?
    var createdAt: Date
    var updatedAt: Date

    /// JSON-encoded `MedicationDosage`.
    var dosageData: Data

    init(
        id: String,
        createdBy: String,
        name: String,
        startDate: Date,
        endDate: Date?,
        isActive: Bool,
        notes: String?,
        sourceRawValue: String,
        privacyLevelRawValue: String,
        healthKitUUID: UUID?,
        createdAt: Date,
        updatedAt: Date,
        dosageData: Data
    ) {
        self.id = id
        self.createdBy = createdBy
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.notes = notes
        self.sourceRawValue = sourceRawValue
        self.privacyLevelRawValue = privacyLevelRawValue
        self.healthKitUUID = healthKitUUID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.dosageData = dosageData
    }
}

// MARK: - Domain mapping

extension StoredMedication {
    convenience init(_ record: MedicationRecord) {
        self.init(
            id: record.id,
            createdBy: record.createdBy,
            name: record.name,
            startDate: record.startDate,
            endDate: record.endDate,
            isActive: record.isActive,
            notes: record.notes,
            sourceRawValue: record.source.rawValue,
            privacyLevelRawValue: record.privacyLevel.rawValue,
            healthKitUUID: record.healthKitUUID,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            dosageData: PersistenceCoding.encode(record.dosage)
        )
    }

    /// Applies an edited record onto the existing row, preserving `createdAt`.
    func apply(_ record: MedicationRecord) {
        createdBy = record.createdBy
        name = record.name
        startDate = record.startDate
        endDate = record.endDate
        isActive = record.isActive
        notes = record.notes
        sourceRawValue = record.source.rawValue
        privacyLevelRawValue = record.privacyLevel.rawValue
        healthKitUUID = record.healthKitUUID
        updatedAt = Date.now
        dosageData = PersistenceCoding.encode(record.dosage)
    }

    var domainModel: MedicationRecord {
        MedicationRecord(
            id: id,
            createdBy: createdBy,
            name: name,
            dosage: PersistenceCoding.decode(MedicationDosage.self, from: dosageData)
                ?? MedicationDosage(amount: 0, unit: "mg", frequency: .asNeeded),
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            notes: notes,
            source: MedicationSource(rawValue: sourceRawValue) ?? .manual,
            privacyLevel: DataPrivacyLevel(rawValue: privacyLevelRawValue) ?? .private,
            healthKitUUID: healthKitUUID,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Dose log

@Model
final class StoredMedicationDose {
    @Attribute(.unique) var id: String

    var createdBy: String
    /// The `StoredMedication.id` this dose belongs to.
    var medicationId: String
    /// Denormalized so doses can be listed without a second fetch.
    var medicationName: String
    var dosageAmount: Double
    var dosageUnit: String
    var dateTaken: Date
    var notes: String?
    var privacyLevelRawValue: String
    var createdAt: Date

    init(
        id: String,
        createdBy: String,
        medicationId: String,
        medicationName: String,
        dosageAmount: Double,
        dosageUnit: String,
        dateTaken: Date,
        notes: String?,
        privacyLevelRawValue: String,
        createdAt: Date
    ) {
        self.id = id
        self.createdBy = createdBy
        self.medicationId = medicationId
        self.medicationName = medicationName
        self.dosageAmount = dosageAmount
        self.dosageUnit = dosageUnit
        self.dateTaken = dateTaken
        self.notes = notes
        self.privacyLevelRawValue = privacyLevelRawValue
        self.createdAt = createdAt
    }
}

extension StoredMedicationDose {
    convenience init(_ dose: MedicationDoseLog) {
        self.init(
            id: dose.id,
            createdBy: dose.createdBy,
            medicationId: dose.medicationId,
            medicationName: dose.medicationName,
            dosageAmount: dose.dosageAmount,
            dosageUnit: dose.dosageUnit,
            dateTaken: dose.dateTaken,
            notes: dose.notes,
            privacyLevelRawValue: dose.privacyLevel.rawValue,
            createdAt: dose.createdAt
        )
    }

    func apply(_ dose: MedicationDoseLog) {
        createdBy = dose.createdBy
        medicationId = dose.medicationId
        medicationName = dose.medicationName
        dosageAmount = dose.dosageAmount
        dosageUnit = dose.dosageUnit
        dateTaken = dose.dateTaken
        notes = dose.notes
        privacyLevelRawValue = dose.privacyLevel.rawValue
    }

    var domainModel: MedicationDoseLog {
        MedicationDoseLog(
            id: id,
            createdBy: createdBy,
            medicationId: medicationId,
            medicationName: medicationName,
            dosageAmount: dosageAmount,
            dosageUnit: dosageUnit,
            dateTaken: dateTaken,
            notes: notes,
            privacyLevel: DataPrivacyLevel(rawValue: privacyLevelRawValue) ?? .private,
            createdAt: createdAt
        )
    }
}
