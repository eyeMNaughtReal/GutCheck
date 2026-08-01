//
//  LegacyStoreMigrator.swift
//  GutCheck
//
//  One-time import of pre-SwiftData data.
//
//  Before this release the app kept records in two places: `Codable` blobs
//  encrypted on disk (anything classified private) and a Core Data store used
//  as an offline queue for anything bound for Firestore. Both are read once
//  here, written into SwiftData, and then left alone.
//
//  Nothing is deleted by the import. If it goes wrong the user's original data
//  is still where it was, and clearing the completion flag re-runs it.
//

import Foundation
import CoreData
import SwiftData

@MainActor
final class LegacyStoreMigrator {
    static let shared = LegacyStoreMigrator()

    private init() {}

    /// Set once the import has finished. Versioned so a later migration can be
    /// added without re-running this one.
    private static let completionKey = "legacyStoreMigration.v1.completed"

    private static let legacyStoreName = "GutCheck.sqlite"

    var hasCompleted: Bool {
        UserDefaults.standard.bool(forKey: Self.completionKey)
    }

    struct Result {
        var meals = 0
        var symptoms = 0
        var medications = 0
        var medicationDoses = 0
        var importedProfile = false
        var importedReminderSettings = false

        var isEmpty: Bool {
            meals == 0 && symptoms == 0 && medications == 0
                && medicationDoses == 0 && !importedProfile && !importedReminderSettings
        }
    }

    /// Ids already present in the store, so an import never inserts a duplicate
    /// and a re-run after a partial failure resumes rather than doubling up.
    private struct ExistingIDs {
        var meals: Set<String> = []
        var symptoms: Set<String> = []
        var medications: Set<String> = []
        var medicationDoses: Set<String> = []
    }

    /// Runs the import if it has not run before. Safe to call on every launch.
    @discardableResult
    func migrateIfNeeded() async -> Result {
        guard !hasCompleted else { return Result() }

        var result = Result()
        var existing = loadExistingIDs()

        // Encrypted files first. They hold complete `Codable` copies, whereas
        // the Core Data rows below dropped tags and most food-item detail — so
        // when the same id exists in both, the file version is the one to keep.
        await importEncryptedFiles(into: &result, existing: &existing)
        await importCoreDataStore(into: &result, existing: &existing)

        do {
            try SwiftDataStack.shared.save()
            UserDefaults.standard.set(true, forKey: Self.completionKey)
        } catch {
            // Leave the flag unset so the next launch tries again rather than
            // silently stranding the user's history in the old store.
            return Result()
        }

        return result
    }

    private func loadExistingIDs() -> ExistingIDs {
        let context = SwiftDataStack.shared.context
        var ids = ExistingIDs()
        ids.meals = Set((try? context.fetch(FetchDescriptor<StoredMeal>()))?.map(\.id) ?? [])
        ids.symptoms = Set((try? context.fetch(FetchDescriptor<StoredSymptom>()))?.map(\.id) ?? [])
        ids.medications = Set((try? context.fetch(FetchDescriptor<StoredMedication>()))?.map(\.id) ?? [])
        ids.medicationDoses = Set((try? context.fetch(FetchDescriptor<StoredMedicationDose>()))?.map(\.id) ?? [])
        return ids
    }

    // MARK: - Encrypted file import

    private func importEncryptedFiles(into result: inout Result, existing: inout ExistingIDs) async {
        let storage = LocalStorageService.shared
        let profileId = LocalUserService.currentProfileId
        let context = SwiftDataStack.shared.context

        // Every imported record is re-owned by the local profile.
        //
        // `createdBy` used to hold a Firebase UID. The local profile's id is a
        // freshly generated UUID, and every repository query filters on it — so
        // carrying the old UID across would import the user's whole history
        // into a store where nothing could ever find it. There is exactly one
        // person on this device, so re-owning is unambiguous.
        for var meal in await decodeAll(Meal.self, typeName: "Meal", from: storage) {
            guard existing.meals.insert(meal.id).inserted else { continue }
            meal.createdBy = profileId
            context.insert(StoredMeal(meal))
            result.meals += 1
        }

        for var symptom in await decodeAll(Symptom.self, typeName: "Symptom", from: storage) {
            guard existing.symptoms.insert(symptom.id).inserted else { continue }
            symptom.createdBy = profileId
            context.insert(StoredSymptom(symptom))
            result.symptoms += 1
        }

        for var record in await decodeAll(MedicationRecord.self, typeName: "MedicationRecord", from: storage) {
            guard existing.medications.insert(record.id).inserted else { continue }
            record.createdBy = profileId
            context.insert(StoredMedication(record))
            result.medications += 1
        }

        for var dose in await decodeAll(MedicationDoseLog.self, typeName: "MedicationDoseLog", from: storage) {
            guard existing.medicationDoses.insert(dose.id).inserted else { continue }
            dose.createdBy = profileId
            context.insert(StoredMedicationDose(dose))
            result.medicationDoses += 1
        }
    }

    /// Reads every encrypted file written for `typeName` and decodes it.
    ///
    /// A file that fails to decrypt or decode is skipped rather than aborting
    /// the import — one unreadable record should not cost the user the rest of
    /// their history.
    private func decodeAll<T: Codable>(
        _ type: T.Type,
        typeName: String,
        from storage: LocalStorageService
    ) async -> [T] {
        guard let fileNames = try? await storage.listPrivateDataFiles(for: typeName) else {
            return []
        }

        var items: [T] = []
        for fileName in fileNames {
            let id = fileName
                .replacingOccurrences(of: "\(typeName)_", with: "")
                .replacingOccurrences(of: ".encrypted", with: "")
            if let item = try? await storage.retrievePrivateData(type: typeName, id: id, as: type) {
                items.append(item)
            }
        }
        return items
    }

    // MARK: - Core Data import

    private func importCoreDataStore(into result: inout Result, existing: inout ExistingIDs) async {
        guard let container = openLegacyContainer() else { return }
        let legacyContext = container.viewContext
        let context = SwiftDataStack.shared.context
        let profileId = LocalUserService.currentProfileId

        // Meals
        let mealRequest = NSFetchRequest<LocalMeal>(entityName: "LocalMeal")
        for legacy in (try? legacyContext.fetch(mealRequest)) ?? [] {
            guard let meal = Self.meal(from: legacy, profileId: profileId),
                  existing.meals.insert(meal.id).inserted else { continue }
            context.insert(StoredMeal(meal))
            result.meals += 1
        }

        // Symptoms
        let symptomRequest = NSFetchRequest<LocalSymptom>(entityName: "LocalSymptom")
        for legacy in (try? legacyContext.fetch(symptomRequest)) ?? [] {
            guard let symptom = Self.symptom(from: legacy, profileId: profileId),
                  existing.symptoms.insert(symptom.id).inserted else { continue }
            context.insert(StoredSymptom(symptom))
            result.symptoms += 1
        }

        // Profile — merged into the profile that already exists rather than
        // inserted, since `LocalUserService` created one at launch and every
        // imported record already points at its id.
        let userRequest = NSFetchRequest<LocalUser>(entityName: "LocalUser")
        if let legacy = (try? legacyContext.fetch(userRequest))?.first,
           let current = LocalUserService.shared.currentUser {
            var profile = User(
                id: current.id,
                email: legacy.email ?? current.email,
                firstName: legacy.firstName ?? current.firstName,
                lastName: legacy.lastName ?? current.lastName,
                createdAt: legacy.createdAt ?? current.createdAt,
                updatedAt: Date.now,
                privacyPolicyAccepted: legacy.privacyPolicyAccepted,
                privacyPolicyAcceptedDate: legacy.privacyPolicyAcceptedDate,
                privacyPolicyVersion: legacy.privacyPolicyVersion ?? current.privacyPolicyVersion
            )
            profile.profileImageURL = legacy.profileImageURL ?? current.profileImageURL
            profile.dateOfBirth = legacy.dateOfBirth
            // Core Data stored these as non-optional scalars defaulting to 0,
            // so zero means "never set" rather than a real measurement.
            profile.weight = legacy.weight > 0 ? legacy.weight : nil
            profile.height = legacy.height > 0 ? legacy.height : nil
            profile.biologicalSexRawValue = legacy.biologicalSexRawValue > 0
                ? Int(legacy.biologicalSexRawValue)
                : nil

            if (try? await LocalUserService.shared.updateUserProfile(profile)) != nil {
                result.importedProfile = true
            }
        }

        // Reminder settings — the legacy schema had a single meal reminder
        // column pair, which the old code used to hold breakfast.
        let settingsRequest = NSFetchRequest<LocalReminderSettings>(entityName: "LocalReminderSettings")
        if let legacy = (try? legacyContext.fetch(settingsRequest))?.first {
            let settings = ReminderSettings(
                id: legacy.id ?? UUID().uuidString,
                createdBy: profileId,
                breakfastReminderEnabled: legacy.mealReminderEnabled,
                breakfastReminderTime: legacy.mealReminderTime ?? ReminderSettings.defaultTime(hour: 7),
                symptomReminderEnabled: legacy.symptomReminderEnabled,
                symptomReminderTime: legacy.symptomReminderTime ?? Date.now,
                remindMeLaterInterval: Int(legacy.remindMeLaterInterval),
                weeklyInsightEnabled: legacy.weeklyInsightEnabled,
                weeklyInsightTime: legacy.weeklyInsightTime ?? Date.now
            )
            if (try? await ReminderSettingsRepository.shared.save(settings)) != nil {
                result.importedReminderSettings = true
            }
        }
    }

    /// Opens the old Core Data store read-only, or returns nil when there isn't
    /// one — a fresh install has nothing to import.
    private func openLegacyContainer() -> NSPersistentContainer? {
        let storeURL = NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent(Self.legacyStoreName)

        guard FileManager.default.fileExists(atPath: storeURL.path) else { return nil }

        let container = NSPersistentContainer(name: "GutCheck")
        let description = NSPersistentStoreDescription(url: storeURL)
        description.type = NSSQLiteStoreType
        description.isReadOnly = true
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        return loadError == nil ? container : nil
    }

    // MARK: - Legacy row conversion

    /// `profileId` replaces the legacy `createdBy` outright — see the note in
    /// `importEncryptedFiles`.
    private static func meal(from legacy: LocalMeal, profileId: String) -> Meal? {
        guard let id = legacy.id,
              let name = legacy.name,
              let date = legacy.date else { return nil }

        let legacyItems = legacy.foodItems?.allObjects as? [LocalFoodItem] ?? []
        let foodItems = legacyItems.compactMap { item -> FoodItem? in
            guard let itemId = item.id, let itemName = item.name else { return nil }
            return FoodItem(
                id: itemId,
                name: itemName,
                quantity: String(item.quantity),
                // Empty string meant "not recorded" on the write side.
                estimatedWeightInGrams: item.servingSize.flatMap { Double($0) },
                nutrition: NutritionInfo(
                    calories: Int(item.calories),
                    protein: item.protein,
                    carbs: item.carbohydrates,
                    fat: item.fat,
                    fiber: item.fiber,
                    sugar: item.sugar,
                    sodium: item.sodium
                )
            )
        }

        var meal = Meal(
            id: id,
            name: name,
            date: date,
            type: legacy.type.flatMap { MealType(rawValue: $0) } ?? .lunch,
            source: legacy.source.flatMap { MealSource(rawValue: $0) } ?? .manual,
            foodItems: foodItems,
            notes: legacy.notes,
            createdBy: profileId
        )
        meal.createdAt = legacy.createdAt ?? date
        meal.updatedAt = legacy.lastModified ?? meal.createdAt
        return meal
    }

    private static func symptom(from legacy: LocalSymptom, profileId: String) -> Symptom? {
        guard let id = legacy.id,
              let date = legacy.date,
              let stoolTypeString = legacy.stoolType,
              let stoolTypeRaw = Int(stoolTypeString),
              let stoolType = StoolType(rawValue: stoolTypeRaw) else { return nil }

        var symptom = Symptom(
            id: id,
            date: date,
            stoolType: stoolType,
            painLevel: PainLevel(rawValue: Int(legacy.painLevel)) ?? .none,
            urgencyLevel: UrgencyLevel(rawValue: Int(legacy.urgencyLevel)) ?? .none,
            notes: legacy.notes,
            createdBy: profileId
        )
        symptom.createdAt = legacy.createdAt ?? date
        symptom.updatedAt = legacy.lastModified ?? symptom.createdAt
        return symptom
    }
}
