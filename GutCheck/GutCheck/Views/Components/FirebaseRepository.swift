//
//  FirebaseRepository.swift
//  GutCheck
//
//  Generic Firebase Repository Pattern Implementation
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

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

protocol FirestoreModel: Codable, Identifiable {
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

class BaseFirebaseRepository<T: FirestoreModel>: FirebaseRepository {
    typealias Model = T
    
    let collectionName: String
    let firestore = Firestore.firestore()
    
    init(collectionName: String) {
        self.collectionName = collectionName
    }
    
    private func testFirestoreConnectivity() async throws {
        let testData: [String: Any] = ["test": "connectivity", "timestamp": Date().timeIntervalSince1970]
        try await firestore.collection("test").document("connectivity").setData(testData)
        print("✅ Basic Firestore connectivity test passed")
    }
    
    // MARK: - CRUD Operations
    
    func save(_ item: Model) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw RepositoryError.noAuthenticatedUser
        }
        
        var mutableItem = item
        mutableItem.createdBy = userId
        
        let data = mutableItem.toFirestoreData()
        
        do {
            print("🔥 Saving to Firestore - Collection: \(collectionName), Document ID: \(item.id)")
            print("🔥 Data to save: \(data)")
            
            // First try a simple test write to verify connectivity
            try await testFirestoreConnectivity()
            
            // Try using addDocument instead of setData to bypass WriteStream issues
            let docRef = try await firestore.collection(collectionName).addDocument(data: data)
            print("✅ Document added with ID: \(docRef.documentID)")
            print("✅ Successfully saved to Firestore")
        } catch {
            print("❌ Firestore save error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw RepositoryError.firebaseError(error)
        }
    }
    
    func fetch(id: String) async throws -> Model? {
        do {
            let document = try await firestore.collection(collectionName).document(id).getDocument()
            
            guard document.exists else {
                return nil
            }
            
            return try Model(from: document)
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
        do {
            try await firestore.collection(collectionName).document(id).delete()
        } catch {
            throw RepositoryError.firebaseError(error)
        }
    }
    
    func query(_ queryBuilder: (Query) -> Query) async throws -> [Model] {
        do {
            let baseQuery = firestore.collection(collectionName)
            let customQuery = queryBuilder(baseQuery)
            let snapshot = try await customQuery.getDocuments()
            
            return try snapshot.documents.compactMap { document in
                try Model(from: document)
            }
        } catch {
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
        
        return try await query { query in
            query
                .whereField("createdBy", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: startOfDay)
                .whereField("date", isLessThan: endOfDay)
                .order(by: "date", descending: false)
        }
    }
    
    func fetchMealsByType(_ type: MealType, userId: String, limit: Int = 10) async throws -> [Meal] {
        return try await query { query in
            query
                .whereField("createdBy", isEqualTo: userId)
                .whereField("type", isEqualTo: type.rawValue)
                .order(by: "date", descending: true)
                .limit(to: limit)
        }
    }
    
    func fetchRecentMeals(userId: String, limit: Int = 20) async throws -> [Meal] {
        return try await query { query in
            query
                .whereField("createdBy", isEqualTo: userId)
                .order(by: "date", descending: true)
                .limit(to: limit)
        }
    }
}

class SymptomRepository: BaseFirebaseRepository<Symptom> {
    static let shared = SymptomRepository()
    
    private init() {
        super.init(collectionName: "symptoms")
    }
    
    // Symptom-specific methods
    func fetchSymptomsForDate(_ date: Date, userId: String) async throws -> [Symptom] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        return try await query { query in
            query
                .whereField("createdBy", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: startOfDay)
                .whereField("date", isLessThan: endOfDay)
                .order(by: "date", descending: false)
        }
    }
    
    func fetchSymptomsByPainLevel(_ painLevel: PainLevel, userId: String) async throws -> [Symptom] {
        return try await query { query in
            query
                .whereField("createdBy", isEqualTo: userId)
                .whereField("painLevel", isEqualTo: painLevel.rawValue)
                .order(by: "date", descending: true)
        }
    }
    
    func fetchRecentSymptoms(userId: String, limit: Int = 20) async throws -> [Symptom] {
        return try await query { query in
            query
                .whereField("createdBy", isEqualTo: userId)
                .order(by: "date", descending: true)
                .limit(to: limit)
        }
    }
}

// MARK: - Repository Manager (Optional - for dependency injection)

class RepositoryManager {
    static let shared = RepositoryManager()
    
    private init() {}
    
    lazy var mealRepository: MealRepository = MealRepository.shared
    lazy var symptomRepository: SymptomRepository = SymptomRepository.shared
    
    // Add other repositories as needed
}

