//
//  FirebaseRepository.swift
//  GutCheck
//
//  Generic Firebase Repository Pattern Implementation
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// Import for privacy-aware data routing
@_exported import struct Foundation.Data

// MARK: - Repository Protocol

protocol FirebaseRepository {
    associatedtype Model: FirestoreModel
    
    var collectionName: String { get }
    var firestore: Firestore { get }
    
    func save(_ item: Model) async throws
    func fetch(id: String) async throws -> Model?
    func fetchAll(for userId: String) async throws -> [Model]
    func fetchAll(for userId: String, limit: Int) async throws -> [Model]
    func delete(id: String) async throws
    func query(_ queryBuilder: (Query) -> Query) async throws -> [Model]
}

// MARK: - Firestore Model Protocol

protocol FirestoreModel: Codable, Identifiable, DataClassifiable {
    var id: String { get set }
    var createdBy: String { get set }
    
    init(from document: DocumentSnapshot) throws
    func toFirestoreData() -> [String: Any]
}

// MARK: - Repository Errors

enum RepositoryError: LocalizedError {
    case noAuthenticatedUser
    case documentNotFound(String)
    case invalidData(String)
    case firebaseError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noAuthenticatedUser:
            return "No authenticated user found"
        case .documentNotFound(let id):
            return "Document with ID \(id) not found"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .firebaseError(let error):
            return "Firebase error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Base Repository Implementation

class BaseFirebaseRepository<T: FirestoreModel & DataClassifiable>: FirebaseRepository {
    typealias Model = T
    
    let collectionName: String
    lazy var firestore = Firestore.firestore()

    init(collectionName: String) {
        self.collectionName = collectionName
    }
    
    // MARK: - CRUD Operations
    
    func save(_ item: Model) async throws {
        guard let userId = AuthenticationManager.shared.currentUserId else {
            throw RepositoryError.noAuthenticatedUser
        }
        
        // Since T is constrained to DataClassifiable, we can directly access privacy level
        print("🔒 BaseFirebaseRepository: Privacy classification detected: \(item.privacyLevel)")
        print("🔒 BaseFirebaseRepository: Item type: \(String(describing: type(of: item)))")
        print("🔒 BaseFirebaseRepository: Item ID: \(item.id)")
        
        switch item.privacyLevel {
        case .private, .confidential:
            // Save sensitive data to local encrypted storage
            print("🔒 BaseFirebaseRepository: Routing private data to local encrypted storage")
            try await UnifiedDataService.shared.save(item)
            print("🔒 BaseFirebaseRepository: Successfully saved to local storage")
            return
            
        case .public:
            // Save non-sensitive data to Firestore
            print("☁️ BaseFirebaseRepository: Routing public data to Firestore")
            try await saveToFirestore(item, userId: userId)
            print("☁️ BaseFirebaseRepository: Successfully saved to Firestore")
            return
        }
    }
    
    /// Save item to Firestore (used for public data and fallback)
    private func saveToFirestore(_ item: Model, userId: String) async throws {
        var mutableItem = item
        mutableItem.createdBy = userId

        let data = mutableItem.toFirestoreData()

        do {
            print("🔥 Saving to Firestore - Collection: \(collectionName), Document ID: \(item.id)")

            // Use setData with the specific document ID to preserve the item's ID
            // Add retry logic for connection issues
            try await retryWithBackoff {
                try await self.firestore.collection(self.collectionName).document(item.id).setData(data, merge: true)
            }
            print("✅ Successfully saved to Firestore with ID: \(item.id)")
        } catch {
            print("❌ Firestore save error: \(error)")

            // Check if it's a network-related Firestore error
            if let firestoreError = error as NSError?, firestoreError.domain == "FIRFirestoreErrorDomain" {
                let networkErrorCodes = [14, 4, 13] // UNAVAILABLE, DEADLINE_EXCEEDED, INTERNAL

                if networkErrorCodes.contains(firestoreError.code) {
                    // Network error — queue in Core Data for later sync
                    print("📦 Queuing to Core Data for later sync")
                    try await queueForOfflineSync(mutableItem)
                    return
                }

                // Non-network Firestore errors
                switch firestoreError.code {
                case 7: // PERMISSION_DENIED
                    throw RepositoryError.firebaseError(NSError(domain: "RepositoryError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Permission denied. Please check Firestore security rules."]))
                default:
                    throw RepositoryError.firebaseError(error)
                }
            }

            throw RepositoryError.firebaseError(error)
        }
    }

    /// Queue an item in Core Data when Firestore is unavailable
    private func queueForOfflineSync(_ item: Model) async throws {
        if let meal = item as? Meal {
            try await CoreDataStorageService.shared.saveMeal(meal)
        } else if let symptom = item as? Symptom {
            try await CoreDataStorageService.shared.saveSymptom(symptom)
        }
        await ServerStatusService.shared.refreshPendingChanges()
        print("📦 Item queued for sync (pending changes updated)")
    }
    
    // Retry logic for transient network issues
    private func retryWithBackoff<ReturnType>(maxRetries: Int = 3, operation: @escaping () async throws -> ReturnType) async throws -> ReturnType {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on authentication or permission errors
                if let nsError = error as NSError?, nsError.domain == "FIRFirestoreErrorDomain" {
                    switch nsError.code {
                    case 7, 16: // PERMISSION_DENIED, UNAUTHENTICATED
                        throw error
                    default:
                        break
                    }
                }
                
                if attempt < maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt)) // Exponential backoff
                    print("🔄 Retry attempt \(attempt + 1) after \(delay) seconds")
                    try await Task.sleep(for: .seconds(delay))
                }
            }
        }
        
        throw lastError ?? RepositoryError.firebaseError(NSError(domain: "RepositoryError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Operation failed after \(maxRetries) retries"]))
    }
    
    func fetch(id: String) async throws -> Model? {
        // First, try to fetch from local encrypted storage (for private data)
        if let localItem = try await UnifiedDataService.shared.fetch(Model.self, id: id) {
            print("🔒 Retrieved from local storage: \(id)")
            return localItem
        }
        
        // If not found locally, try Firestore (for public data)
        do {
            let document = try await firestore.collection(collectionName).document(id).getDocument()
            
            guard document.exists else {
                print("❌ Item not found in any storage: \(id)")
                return nil
            }
            
            let item = try Model(from: document)
            print("☁️ Retrieved from Firestore: \(id)")
            return item
        } catch {
            if error is RepositoryError {
                throw error
            } else {
                throw RepositoryError.firebaseError(error)
            }
        }
    }
    
    func fetchAll(for userId: String) async throws -> [Model] {
        return try await fetchAll(for: userId, limit: 1000) // Default reasonable limit
    }
    
    func fetchAll(for userId: String, limit: Int) async throws -> [Model] {
        do {
            let snapshot = try await firestore.collection(collectionName)
                .whereField("createdBy", isEqualTo: userId)
                .limit(to: limit)
                .getDocuments()
            
            return try snapshot.documents.compactMap { document in
                try Model(from: document)
            }
        } catch {
            throw RepositoryError.firebaseError(error)
        }
    }
    
    func delete(id: String) async throws {
        // Delete from local encrypted storage (for private data)
        try await UnifiedDataService.shared.delete(Model.self, id: id)
        
        // Also try to delete from Firestore (for public data)
        do {
            try await firestore.collection(collectionName).document(id).delete()
            print("✅ Deleted from both storage locations: \(id)")
        } catch {
            // If Firestore deletion fails, it might not exist there (which is fine)
            print("⚠️ Firestore deletion failed (item may not exist there): \(id)")
        }
    }
    
    func query(_ queryBuilder: (Query) -> Query) async throws -> [Model] {
        var allResults: [Model] = []
        
        // First, try to fetch from local encrypted storage (for private data)
        // Note: Local storage querying is simplified for now
        do {
            let localResults = try await UnifiedDataService.shared.query(Model.self, queryBuilder: { _ in
                // For now, we'll fetch all local items of this type
                // In a more sophisticated implementation, we'd implement proper local querying
                return firestore.collection(collectionName) // Placeholder
            })
            allResults.append(contentsOf: localResults)
            print("🔒 Retrieved \(localResults.count) items from local storage")
        } catch {
            print("⚠️ Local storage query failed: \(error)")
        }
        
        // Then fetch from Firestore (for public data)
        do {
            let baseQuery = firestore.collection(collectionName)
            let customQuery = queryBuilder(baseQuery)
            let snapshot = try await customQuery.getDocuments()
            
            let firestoreResults = try snapshot.documents.compactMap { document in
                try Model(from: document)
            }
            allResults.append(contentsOf: firestoreResults)
            print("☁️ Retrieved \(firestoreResults.count) items from Firestore")
        } catch {
            print("⚠️ Firestore query failed: \(error)")
            throw RepositoryError.firebaseError(error)
        }
        
        print("✅ Total results: \(allResults.count) items")
        return allResults
    }
    
    /// Query only Firestore (used when local storage is already handled separately)
    func queryFirestoreOnly(_ queryBuilder: (Query) -> Query) async throws -> [Model] {
        do {
            let baseQuery = firestore.collection(collectionName)
            let customQuery = queryBuilder(baseQuery)
            let snapshot = try await customQuery.getDocuments()
            
            let firestoreResults = try snapshot.documents.compactMap { document in
                try Model(from: document)
            }
            print("☁️ Retrieved \(firestoreResults.count) items from Firestore only")
            return firestoreResults
        } catch {
            print("⚠️ Firestore query failed: \(error)")
            throw RepositoryError.firebaseError(error)
        }
    }
}

// MARK: - Specific Repository Implementations

class MealRepository: BaseFirebaseRepository<Meal> {
    static let shared = MealRepository()
    
    private init() {
        super.init(collectionName: "meals")
    }
    
    // Meal-specific methods
    func fetchMealsForDate(_ date: Date, userId: String) async throws -> [Meal] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        var allMeals: [Meal] = []
        
        // Fetch from local encrypted storage (private meals)
        do {
            let localMeals = try await UnifiedDataService.shared.query(Meal.self) { _ in
                // For now, fetch all local meals and filter by date
                // In a more sophisticated implementation, we'd implement proper local date filtering
                return firestore.collection(collectionName)
            }
            
            // Filter local meals by date
            let filteredLocalMeals = localMeals.filter { meal in
                meal.date >= startOfDay && meal.date < endOfDay
            }
            allMeals.append(contentsOf: filteredLocalMeals)
            print("🔒 Retrieved \(filteredLocalMeals.count) private meals for date")
        } catch {
            print("⚠️ Local meal query failed: \(error)")
        }
        
        // Fetch from Firestore (public meals)
        let firestoreMeals = try await query { query in
            query
                .whereField("createdBy", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: startOfDay)
                .whereField("date", isLessThan: endOfDay)
                .order(by: "date", descending: false)
        }
        allMeals.append(contentsOf: firestoreMeals)
        print("☁️ Retrieved \(firestoreMeals.count) public meals for date")
        
        // Sort all meals by date
        let sortedMeals = allMeals.sorted { $0.date < $1.date }
        print("✅ Total meals for date: \(sortedMeals.count)")
        
        return sortedMeals
    }
    
    func fetchRecentMeals(userId: String, limit: Int = 20) async throws -> [Meal] {
        var allMeals: [Meal] = []
        
        // Fetch from local encrypted storage (private meals)
        do {
            let localMeals = try await UnifiedDataService.shared.query(Meal.self) { _ in
                // For now, fetch all local meals
                // In a more sophisticated implementation, we'd implement proper local querying
                return firestore.collection(collectionName)
            }
            allMeals.append(contentsOf: localMeals)
            print("🔒 Retrieved \(localMeals.count) private meals")
        } catch {
            print("⚠️ Local meal query failed: \(error)")
        }
        
        // Fetch from Firestore (public meals)
        let firestoreMeals = try await query { query in
            query
                .whereField("createdBy", isEqualTo: userId)
                .order(by: "date", descending: true)
                .limit(to: limit)
        }
        allMeals.append(contentsOf: firestoreMeals)
        print("☁️ Retrieved \(firestoreMeals.count) public meals")
        
        // Sort all meals by date (most recent first) and limit
        let sortedMeals = allMeals.sorted { $0.date > $1.date }
        let limitedMeals = Array(sortedMeals.prefix(limit))
        print("✅ Total recent meals: \(limitedMeals.count)")
        
        return limitedMeals
    }
}

class SymptomRepository: BaseFirebaseRepository<Symptom> {
    static let shared = SymptomRepository()
    
    private init() {
        super.init(collectionName: "symptoms")
    }
    
    // Convenience method for DashboardDataStore
    func getSymptoms(for date: Date) async throws -> [Symptom] {
        guard let userId = AuthenticationManager.shared.currentUserId else {
            throw RepositoryError.noAuthenticatedUser
        }
        return try await fetchSymptomsForDate(date, userId: userId)
    }
    
    // Symptom-specific methods
    func fetchSymptomsForDate(_ date: Date, userId: String) async throws -> [Symptom] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        print("🔍 SymptomRepository: Fetching symptoms for date \(date) (start: \(startOfDay), end: \(endOfDay))")
        
        var allSymptoms: [Symptom] = []
        
        // Fetch from local encrypted storage (private symptoms)
        do {
            print("🔍 SymptomRepository: Querying local encrypted storage...")
            let localSymptoms = try await UnifiedDataService.shared.query(Symptom.self) { _ in
                // For now, fetch all local symptoms and filter by date
                return firestore.collection(collectionName)
            }
            
            print("🔍 SymptomRepository: Found \(localSymptoms.count) total local symptoms")
            
            // Filter local symptoms by date
            print("🔍 SymptomRepository: Date filtering - startOfDay: \(startOfDay), endOfDay: \(endOfDay)")
            let filteredLocalSymptoms = localSymptoms.filter { symptom in
                let isInRange = symptom.date >= startOfDay && symptom.date < endOfDay
                print("🔍 SymptomRepository: Symptom \(symptom.id) date: \(symptom.date) - in range: \(isInRange)")
                return isInRange
            }
            allSymptoms.append(contentsOf: filteredLocalSymptoms)
            print("🔒 SymptomRepository: Retrieved \(filteredLocalSymptoms.count) private symptoms for date")
            
            // Debug: Print details of each local symptom
            for symptom in filteredLocalSymptoms {
                print("🔒 SymptomRepository: Local symptom - ID: \(symptom.id), date: \(symptom.date), notes: \(symptom.notes ?? "none")")
            }
        } catch {
            print("⚠️ SymptomRepository: Local symptom query failed: \(error)")
        }
        
        // Fetch from Firestore (public symptoms only - local storage already handled above)
        print("🔍 SymptomRepository: Querying Firestore...")
        let firestoreSymptoms = try await queryFirestoreOnly { query in
            query
                .whereField("createdBy", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: startOfDay)
                .whereField("date", isLessThan: endOfDay)
                .order(by: "date", descending: false)
        }
        allSymptoms.append(contentsOf: firestoreSymptoms)
        print("☁️ SymptomRepository: Retrieved \(firestoreSymptoms.count) public symptoms for date")
        
        // Debug: Print details of each Firestore symptom
        for symptom in firestoreSymptoms {
            print("☁️ SymptomRepository: Firestore symptom - ID: \(symptom.id), date: \(symptom.date), notes: \(symptom.notes ?? "none")")
        }
        
        // Sort all symptoms by date
        let sortedSymptoms = allSymptoms.sorted { $0.date < $1.date }
        print("✅ SymptomRepository: Total symptoms for date: \(sortedSymptoms.count)")
        
        // Debug: Check for duplicates
        let symptomIds = sortedSymptoms.map { $0.id }
        let uniqueIds = Set(symptomIds)
        if symptomIds.count != uniqueIds.count {
            print("⚠️ SymptomRepository: DUPLICATE SYMPTOMS DETECTED!")
            print("⚠️ SymptomRepository: Total count: \(symptomIds.count), Unique count: \(uniqueIds.count)")
            
            // Find duplicates
            let duplicateIds = symptomIds.filter { id in
                symptomIds.filter { $0 == id }.count > 1
            }
            print("⚠️ SymptomRepository: Duplicate IDs: \(duplicateIds)")
            
            // Remove duplicates by keeping only the first occurrence of each ID
            var deduplicatedSymptoms: [Symptom] = []
            var seenIds = Set<String>()
            
            for symptom in sortedSymptoms {
                if !seenIds.contains(symptom.id) {
                    deduplicatedSymptoms.append(symptom)
                    seenIds.insert(symptom.id)
                } else {
                    print("🔄 SymptomRepository: Removing duplicate symptom with ID: \(symptom.id)")
                }
            }
            
            print("✅ SymptomRepository: After deduplication: \(deduplicatedSymptoms.count) symptoms")
            return deduplicatedSymptoms
        }
        
        return sortedSymptoms
    }
    
    func fetchRecentSymptoms(userId: String, limit: Int = 20) async throws -> [Symptom] {
        var allSymptoms: [Symptom] = []
        
        // Fetch from local encrypted storage (private symptoms)
        do {
            let localSymptoms = try await UnifiedDataService.shared.query(Symptom.self) { _ in
                return firestore.collection(collectionName)
            }
            allSymptoms.append(contentsOf: localSymptoms)
            print("🔒 Retrieved \(localSymptoms.count) private symptoms")
        } catch {
            print("⚠️ Local symptom query failed: \(error)")
        }
        
        // Fetch from Firestore (public symptoms only - local storage already handled above)
        let firestoreSymptoms = try await queryFirestoreOnly { query in
            query
                .whereField("createdBy", isEqualTo: userId)
                .order(by: "date", descending: true)
                .limit(to: limit)
        }
        allSymptoms.append(contentsOf: firestoreSymptoms)
        print("☁️ Retrieved \(firestoreSymptoms.count) public symptoms")
        
        // Sort all symptoms by date (most recent first) and limit
        let sortedSymptoms = allSymptoms.sorted { $0.date > $1.date }
        
        // Remove duplicates by keeping only the first occurrence of each ID
        var deduplicatedSymptoms: [Symptom] = []
        var seenIds = Set<String>()
        
        for symptom in sortedSymptoms {
            if !seenIds.contains(symptom.id) {
                deduplicatedSymptoms.append(symptom)
                seenIds.insert(symptom.id)
            } else {
                print("🔄 SymptomRepository: Removing duplicate symptom with ID: \(symptom.id) from recent symptoms")
            }
        }
        
        let limitedSymptoms = Array(deduplicatedSymptoms.prefix(limit))
        print("✅ SymptomRepository: Total recent symptoms after deduplication: \(limitedSymptoms.count)")
        
        return limitedSymptoms
    }
}

class MedicationRepository: BaseFirebaseRepository<MedicationRecord> {
    static let shared = MedicationRepository()

    private init() {
        super.init(collectionName: "medications")
    }

    /// Fetch only active medications (isActive == true), deduped and sorted by startDate ascending.
    func fetchActiveMedications(userId: String) async throws -> [MedicationRecord] {
        var all: [MedicationRecord] = []

        // Local encrypted storage (privacyLevel == .private)
        do {
            let local = try await UnifiedDataService.shared.query(MedicationRecord.self) { _ in
                firestore.collection(collectionName)
            }
            all.append(contentsOf: local)
        } catch {
            print("⚠️ MedicationRepository: local query failed: \(error)")
        }

        // Firestore (public medications, if any)
        do {
            let remote = try await queryFirestoreOnly { query in
                query
                    .whereField("createdBy", isEqualTo: userId)
                    .whereField("isActive", isEqualTo: true)
                    .order(by: "startDate", descending: false)
            }
            all.append(contentsOf: remote)
        } catch {
            print("⚠️ MedicationRepository: Firestore query failed: \(error)")
        }

        return deduplicated(all.filter { $0.isActive }, sortedBy: { $0.startDate < $1.startDate })
    }

    /// Fetch all medications, deduped and sorted by startDate descending.
    func fetchAllMedications(userId: String) async throws -> [MedicationRecord] {
        var all: [MedicationRecord] = []

        do {
            let local = try await UnifiedDataService.shared.query(MedicationRecord.self) { _ in
                firestore.collection(collectionName)
            }
            all.append(contentsOf: local)
        } catch {
            print("⚠️ MedicationRepository: local query failed: \(error)")
        }

        do {
            let remote = try await queryFirestoreOnly { query in
                query
                    .whereField("createdBy", isEqualTo: userId)
                    .order(by: "startDate", descending: true)
            }
            all.append(contentsOf: remote)
        } catch {
            print("⚠️ MedicationRepository: Firestore query failed: \(error)")
        }

        return deduplicated(all, sortedBy: { $0.startDate > $1.startDate })
    }

    // MARK: - Helpers

    private func deduplicated(_ items: [MedicationRecord],
                              sortedBy comparator: (MedicationRecord, MedicationRecord) -> Bool)
        -> [MedicationRecord]
    {
        var seen = Set<String>()
        var result: [MedicationRecord] = []
        for item in items.sorted(by: comparator) {
            if seen.insert(item.id).inserted {
                result.append(item)
            }
        }
        return result
    }
}

class MedicationDoseRepository: BaseFirebaseRepository<MedicationDoseLog> {
    static let shared = MedicationDoseRepository()

    private init() {
        super.init(collectionName: "medicationDoses")
    }

    /// All doses taken on a given calendar day, sorted chronologically.
    func fetchDosesForDate(_ date: Date, userId: String) async throws -> [MedicationDoseLog] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end   = calendar.date(byAdding: .day, value: 1, to: start) ?? date

        var all: [MedicationDoseLog] = []

        do {
            let local = try await UnifiedDataService.shared.query(MedicationDoseLog.self) { _ in
                firestore.collection(collectionName)
            }
            all.append(contentsOf: local.filter { $0.dateTaken >= start && $0.dateTaken < end })
        } catch {
            print("⚠️ MedicationDoseRepository: local query failed: \(error)")
        }

        do {
            let remote = try await queryFirestoreOnly { query in
                query
                    .whereField("createdBy", isEqualTo: userId)
                    .whereField("dateTaken", isGreaterThanOrEqualTo: start)
                    .whereField("dateTaken", isLessThan: end)
                    .order(by: "dateTaken", descending: false)
            }
            all.append(contentsOf: remote)
        } catch {
            print("⚠️ MedicationDoseRepository: Firestore query failed: \(error)")
        }

        return deduplicated(all, ascending: true)
    }

    /// Most-recent doses across all dates, up to `limit`.
    func fetchRecentDoses(userId: String, limit: Int = 50) async throws -> [MedicationDoseLog] {
        var all: [MedicationDoseLog] = []

        do {
            let local = try await UnifiedDataService.shared.query(MedicationDoseLog.self) { _ in
                firestore.collection(collectionName)
            }
            all.append(contentsOf: local)
        } catch {
            print("⚠️ MedicationDoseRepository: local query failed: \(error)")
        }

        do {
            let remote = try await queryFirestoreOnly { query in
                query
                    .whereField("createdBy", isEqualTo: userId)
                    .order(by: "dateTaken", descending: true)
                    .limit(to: limit)
            }
            all.append(contentsOf: remote)
        } catch {
            print("⚠️ MedicationDoseRepository: Firestore query failed: \(error)")
        }

        return Array(deduplicated(all, ascending: false).prefix(limit))
    }

    // MARK: - Helpers

    private func deduplicated(_ items: [MedicationDoseLog], ascending: Bool) -> [MedicationDoseLog] {
        var seen   = Set<String>()
        var result = [MedicationDoseLog]()
        let sorted = items.sorted { ascending ? $0.dateTaken < $1.dateTaken : $0.dateTaken > $1.dateTaken }
        for item in sorted {
            if seen.insert(item.id).inserted { result.append(item) }
        }
        return result
    }
}

// MARK: - Repository Manager (Optional - for dependency injection)

class RepositoryManager {
    static let shared = RepositoryManager()

    private init() {}

    lazy var mealRepository: MealRepository = MealRepository.shared
    lazy var symptomRepository: SymptomRepository = SymptomRepository.shared
    lazy var reminderSettingsRepository: ReminderSettingsRepository = ReminderSettingsRepository.shared
    lazy var medicationRepository: MedicationRepository = MedicationRepository.shared
    lazy var medicationDoseRepository: MedicationDoseRepository = MedicationDoseRepository.shared
}

