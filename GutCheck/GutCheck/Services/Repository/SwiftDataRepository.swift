//
//  SwiftDataRepository.swift
//  GutCheck
//
//  SwiftData-backed repositories.
//
//  Each repository owns one entity, translating between the `@Model` rows in
//  the store and the value-type domain models the rest of the app works with.
//  Views and view models keep their structs; nothing above this layer touches
//  SwiftData.
//
//  These are written out per entity rather than sharing a generic base class:
//  `#Predicate` has to be built against a concrete `@Model` type, so a generic
//  base could not express any of the filters below and every useful method
//  would end up overridden anyway.
//

import Foundation
import SwiftData

// MARK: - Shared plumbing

@MainActor
private enum Store {
    static var context: ModelContext { SwiftDataStack.shared.context }

    /// Runs a fetch, wrapping any SwiftData failure as a `RepositoryError`.
    static func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        do {
            return try context.fetch(descriptor)
        } catch {
            throw RepositoryError.storageError(error)
        }
    }

    /// Fetches the single row with this id, if present.
    static func first<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> T? {
        var limited = descriptor
        limited.fetchLimit = 1
        return try fetch(limited).first
    }

    static func save() throws {
        do {
            try SwiftDataStack.shared.save()
        } catch {
            throw RepositoryError.storageError(error)
        }
    }
}

// MARK: - Meals

@MainActor
final class MealRepository: MealRepositoryProtocol {
    static let shared = MealRepository()

    private init() {}

    func save(_ item: Meal) async throws {
        var meal = item
        if meal.createdBy.isEmpty {
            meal.createdBy = LocalUserService.currentProfileId
        }

        // Upsert rather than insert: saving an edited meal must update the row
        // in place. The unique index on `id` would otherwise reject the write.
        if let existing = try Store.first(Self.descriptor(id: meal.id)) {
            existing.apply(meal)
        } else {
            Store.context.insert(StoredMeal(meal))
        }
        try Store.save()
    }

    func fetch(id: String) async throws -> Meal? {
        try Store.first(Self.descriptor(id: id))?.domainModel
    }

    func delete(id: String) async throws {
        guard let existing = try Store.first(Self.descriptor(id: id)) else { return }
        Store.context.delete(existing)
        try Store.save()
    }

    func fetchMealsForDate(_ date: Date, userId: String) async throws -> [Meal] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        // Half-open [start, end). A closed upper bound double-counts a record
        // landing exactly on midnight, putting it in both adjacent days.
        let descriptor = FetchDescriptor<StoredMeal>(
            predicate: #Predicate { meal in
                meal.createdBy == userId && meal.date >= startOfDay && meal.date < endOfDay
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    func fetchRecentMeals(userId: String, limit: Int = 20) async throws -> [Meal] {
        var descriptor = FetchDescriptor<StoredMeal>(
            predicate: #Predicate { $0.createdBy == userId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    func fetchMealsForDateRange(startDate: Date, endDate: Date, userId: String) async throws -> [Meal] {
        let descriptor = FetchDescriptor<StoredMeal>(
            predicate: #Predicate { meal in
                meal.createdBy == userId && meal.date >= startDate && meal.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    /// One page of meals, newest first.
    ///
    /// Offset paging replaced Firestore's cursor tokens. A local store has no
    /// concurrent writer to skew the window, so an offset is stable between
    /// calls in a way it would not have been against a shared backend.
    func fetchMealsPage(userId: String, offset: Int, limit: Int) async throws -> [Meal] {
        var descriptor = FetchDescriptor<StoredMeal>(
            predicate: #Predicate { $0.createdBy == userId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    /// Every meal on record, oldest first. Used by trigger analysis, which needs
    /// the full history rather than a window.
    func fetchAll(userId: String) async throws -> [Meal] {
        let descriptor = FetchDescriptor<StoredMeal>(
            predicate: #Predicate { $0.createdBy == userId },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    /// Removes every meal belonging to a profile. Used by account deletion.
    func deleteAll(userId: String) async throws {
        let descriptor = FetchDescriptor<StoredMeal>(
            predicate: #Predicate { $0.createdBy == userId }
        )
        for meal in try Store.fetch(descriptor) {
            Store.context.delete(meal)
        }
        try Store.save()
    }

    private static func descriptor(id: String) -> FetchDescriptor<StoredMeal> {
        FetchDescriptor<StoredMeal>(predicate: #Predicate { $0.id == id })
    }
}

// MARK: - Symptoms

@MainActor
final class SymptomRepository: SymptomRepositoryProtocol {
    static let shared = SymptomRepository()

    private init() {}

    func save(_ item: Symptom) async throws {
        var symptom = item
        if symptom.createdBy.isEmpty {
            symptom.createdBy = LocalUserService.currentProfileId
        }

        if let existing = try Store.first(Self.descriptor(id: symptom.id)) {
            existing.apply(symptom)
        } else {
            Store.context.insert(StoredSymptom(symptom))
        }
        try Store.save()
    }

    func fetch(id: String) async throws -> Symptom? {
        try Store.first(Self.descriptor(id: id))?.domainModel
    }

    func delete(id: String) async throws {
        guard let existing = try Store.first(Self.descriptor(id: id)) else { return }
        Store.context.delete(existing)
        try Store.save()
    }

    /// Convenience for callers that only have a date — resolves the profile itself.
    func getSymptoms(for date: Date) async throws -> [Symptom] {
        try await fetchSymptomsForDate(date, userId: LocalUserService.currentProfileId)
    }

    func fetchSymptomsForDate(_ date: Date, userId: String) async throws -> [Symptom] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let descriptor = FetchDescriptor<StoredSymptom>(
            predicate: #Predicate { symptom in
                symptom.createdBy == userId && symptom.date >= startOfDay && symptom.date < endOfDay
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    func fetchRecentSymptoms(userId: String, limit: Int = 20) async throws -> [Symptom] {
        var descriptor = FetchDescriptor<StoredSymptom>(
            predicate: #Predicate { $0.createdBy == userId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    func fetchSymptomsForDateRange(startDate: Date, endDate: Date, userId: String) async throws -> [Symptom] {
        let descriptor = FetchDescriptor<StoredSymptom>(
            predicate: #Predicate { symptom in
                symptom.createdBy == userId && symptom.date >= startDate && symptom.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    /// One page of symptoms, newest first. See `MealRepository.fetchMealsPage`
    /// for why this pages by offset.
    func fetchSymptomsPage(userId: String, offset: Int, limit: Int) async throws -> [Symptom] {
        var descriptor = FetchDescriptor<StoredSymptom>(
            predicate: #Predicate { $0.createdBy == userId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    /// Every symptom on record, oldest first.
    func fetchAll(userId: String) async throws -> [Symptom] {
        let descriptor = FetchDescriptor<StoredSymptom>(
            predicate: #Predicate { $0.createdBy == userId },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    func deleteAll(userId: String) async throws {
        let descriptor = FetchDescriptor<StoredSymptom>(
            predicate: #Predicate { $0.createdBy == userId }
        )
        for symptom in try Store.fetch(descriptor) {
            Store.context.delete(symptom)
        }
        try Store.save()
    }

    private static func descriptor(id: String) -> FetchDescriptor<StoredSymptom> {
        FetchDescriptor<StoredSymptom>(predicate: #Predicate { $0.id == id })
    }
}

// MARK: - Medications

@MainActor
final class MedicationRepository: MedicationRepositoryProtocol {
    static let shared = MedicationRepository()

    private init() {}

    func save(_ item: MedicationRecord) async throws {
        var record = item
        if record.createdBy.isEmpty {
            record.createdBy = LocalUserService.currentProfileId
        }

        if let existing = try Store.first(Self.descriptor(id: record.id)) {
            existing.apply(record)
        } else {
            Store.context.insert(StoredMedication(record))
        }
        try Store.save()
    }

    func fetch(id: String) async throws -> MedicationRecord? {
        try Store.first(Self.descriptor(id: id))?.domainModel
    }

    func delete(id: String) async throws {
        guard let existing = try Store.first(Self.descriptor(id: id)) else { return }
        Store.context.delete(existing)
        try Store.save()
    }

    func fetchActiveMedications(userId: String) async throws -> [MedicationRecord] {
        let descriptor = FetchDescriptor<StoredMedication>(
            predicate: #Predicate { $0.createdBy == userId && $0.isActive == true },
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    func fetchAllMedications(userId: String) async throws -> [MedicationRecord] {
        let descriptor = FetchDescriptor<StoredMedication>(
            predicate: #Predicate { $0.createdBy == userId },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    /// Looks up a medication imported from HealthKit by its HealthKit id, so a
    /// repeat sync updates the existing row instead of adding a duplicate.
    func fetchByHealthKitUUID(_ uuid: UUID, userId: String) async throws -> MedicationRecord? {
        let descriptor = FetchDescriptor<StoredMedication>(
            predicate: #Predicate { $0.createdBy == userId && $0.healthKitUUID == uuid }
        )
        return try Store.first(descriptor)?.domainModel
    }

    func deleteAll(userId: String) async throws {
        let descriptor = FetchDescriptor<StoredMedication>(
            predicate: #Predicate { $0.createdBy == userId }
        )
        for medication in try Store.fetch(descriptor) {
            Store.context.delete(medication)
        }
        try Store.save()
    }

    private static func descriptor(id: String) -> FetchDescriptor<StoredMedication> {
        FetchDescriptor<StoredMedication>(predicate: #Predicate { $0.id == id })
    }
}

// MARK: - Medication doses

@MainActor
final class MedicationDoseRepository: MedicationDoseRepositoryProtocol {
    static let shared = MedicationDoseRepository()

    private init() {}

    func save(_ item: MedicationDoseLog) async throws {
        var dose = item
        if dose.createdBy.isEmpty {
            dose.createdBy = LocalUserService.currentProfileId
        }

        if let existing = try Store.first(Self.descriptor(id: dose.id)) {
            existing.apply(dose)
        } else {
            Store.context.insert(StoredMedicationDose(dose))
        }
        try Store.save()
    }

    func fetch(id: String) async throws -> MedicationDoseLog? {
        try Store.first(Self.descriptor(id: id))?.domainModel
    }

    func delete(id: String) async throws {
        guard let existing = try Store.first(Self.descriptor(id: id)) else { return }
        Store.context.delete(existing)
        try Store.save()
    }

    func fetchDosesForDate(_ date: Date, userId: String) async throws -> [MedicationDoseLog] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date

        let descriptor = FetchDescriptor<StoredMedicationDose>(
            predicate: #Predicate { dose in
                dose.createdBy == userId && dose.dateTaken >= start && dose.dateTaken < end
            },
            sortBy: [SortDescriptor(\.dateTaken, order: .forward)]
        )
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    func fetchRecentDoses(userId: String, limit: Int = 50) async throws -> [MedicationDoseLog] {
        var descriptor = FetchDescriptor<StoredMedicationDose>(
            predicate: #Predicate { $0.createdBy == userId },
            sortBy: [SortDescriptor(\.dateTaken, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    /// Doses of one medication, most recent first. Used when a medication is
    /// opened so its history can be shown without loading every dose.
    func fetchDoses(medicationId: String, userId: String) async throws -> [MedicationDoseLog] {
        let descriptor = FetchDescriptor<StoredMedicationDose>(
            predicate: #Predicate { $0.createdBy == userId && $0.medicationId == medicationId },
            sortBy: [SortDescriptor(\.dateTaken, order: .reverse)]
        )
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    func deleteAll(userId: String) async throws {
        let descriptor = FetchDescriptor<StoredMedicationDose>(
            predicate: #Predicate { $0.createdBy == userId }
        )
        for dose in try Store.fetch(descriptor) {
            Store.context.delete(dose)
        }
        try Store.save()
    }

    private static func descriptor(id: String) -> FetchDescriptor<StoredMedicationDose> {
        FetchDescriptor<StoredMedicationDose>(predicate: #Predicate { $0.id == id })
    }
}

// MARK: - Reminder settings

@MainActor
final class ReminderSettingsRepository {
    static let shared = ReminderSettingsRepository()

    private init() {}

    /// There is one settings row per profile, keyed on `createdBy`.
    func fetch(forUser userId: String) async throws -> ReminderSettings {
        let descriptor = FetchDescriptor<StoredReminderSettings>(
            predicate: #Predicate { $0.createdBy == userId }
        )
        guard let stored = try Store.first(descriptor) else {
            throw RepositoryError.recordNotFound("No reminder settings found for profile")
        }
        return stored.domainModel
    }

    func save(_ settings: ReminderSettings) async throws {
        let userId = settings.createdBy
        let descriptor = FetchDescriptor<StoredReminderSettings>(
            predicate: #Predicate { $0.createdBy == userId }
        )
        if let existing = try Store.first(descriptor) {
            existing.apply(settings)
        } else {
            Store.context.insert(StoredReminderSettings(settings))
        }
        try Store.save()
    }

    func delete(_ settings: ReminderSettings) async throws {
        let userId = settings.createdBy
        let descriptor = FetchDescriptor<StoredReminderSettings>(
            predicate: #Predicate { $0.createdBy == userId }
        )
        guard let existing = try Store.first(descriptor) else { return }
        Store.context.delete(existing)
        try Store.save()
    }
}

// MARK: - Data deletion requests

@MainActor
final class DataDeletionRequestRepository {
    static let shared = DataDeletionRequestRepository()

    private init() {}

    func save(_ request: DataDeletionRequest) async throws {
        if let existing = try Store.first(Self.descriptor(id: request.id)) {
            existing.apply(request)
        } else {
            Store.context.insert(StoredDataDeletionRequest(request))
        }
        try Store.save()
    }

    func fetch(id: String) async throws -> DataDeletionRequest? {
        try Store.first(Self.descriptor(id: id))?.domainModel
    }

    /// Every request on this device, newest first.
    func fetchAll() async throws -> [DataDeletionRequest] {
        let descriptor = FetchDescriptor<StoredDataDeletionRequest>(
            sortBy: [SortDescriptor(\.requestDate, order: .reverse)]
        )
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    func fetchAll(userId: String) async throws -> [DataDeletionRequest] {
        let descriptor = FetchDescriptor<StoredDataDeletionRequest>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.requestDate, order: .reverse)]
        )
        return try Store.fetch(descriptor).map(\.domainModel)
    }

    private static func descriptor(id: String) -> FetchDescriptor<StoredDataDeletionRequest> {
        FetchDescriptor<StoredDataDeletionRequest>(predicate: #Predicate { $0.id == id })
    }
}

// MARK: - Repository Manager

@MainActor
final class RepositoryManager {
    static let shared = RepositoryManager()

    private init() {}

    lazy var mealRepository: any MealRepositoryProtocol = MealRepository.shared
    lazy var symptomRepository: any SymptomRepositoryProtocol = SymptomRepository.shared
    lazy var reminderSettingsRepository: ReminderSettingsRepository = ReminderSettingsRepository.shared
    lazy var medicationRepository: any MedicationRepositoryProtocol = MedicationRepository.shared
    lazy var medicationDoseRepository: any MedicationDoseRepositoryProtocol = MedicationDoseRepository.shared
}
