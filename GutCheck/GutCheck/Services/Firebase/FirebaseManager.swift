import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private lazy var db = Firestore.firestore()
    private let auth = Auth.auth()
    
    private init() {}
    
    // MARK: - Collection Names
    private enum CollectionName {
        static let users = "users"
        static let meals = "meals"
        static let symptoms = "symptoms"
        static let activities = "activities"
        static let reminders = "reminders"
        static let reminderSettings = "reminderSettings"
        static let test = "test"
        static let foodItems = "foodItems"
        static let dataDeletionRequests = "dataDeletionRequests"
    }
    
    // MARK: - Storage Paths
    private enum StoragePath {
        static let profileImages = "profile_images"
        static let users = "users"
    }
    
    // MARK: - Collection Management
    
    // User Collection
    func usersCollection() -> CollectionReference {
        return db.collection(CollectionName.users)
    }
    
    func userDocument(_ userId: String) -> DocumentReference {
        return usersCollection().document(userId)
    }
    
    func userMealsCollection(_ userId: String) -> CollectionReference {
        return userDocument(userId).collection(CollectionName.meals)
    }
    
    func userMealDocument(_ userId: String, mealId: String) -> DocumentReference {
        return userMealsCollection(userId).document(mealId)
    }
    
    // Symptoms Collection
    func userSymptomsCollection(_ userId: String) -> CollectionReference {
        return userDocument(userId).collection(CollectionName.symptoms)
    }
    
    func userSymptomDocument(_ userId: String, symptomId: String) -> DocumentReference {
        return userSymptomsCollection(userId).document(symptomId)
    }
    
    // Activities Collection
    func userActivitiesCollection(_ userId: String) -> CollectionReference {
        return userDocument(userId).collection(CollectionName.activities)
    }
    
    func userActivityDocument(_ userId: String, activityId: String) -> DocumentReference {
        return userActivitiesCollection(userId).document(activityId)
    }
    
    // Reminders Collection
    func userRemindersCollection(_ userId: String) -> CollectionReference {
        return userDocument(userId).collection(CollectionName.reminders)
    }
    
    func userReminderDocument(_ userId: String, reminderId: String) -> DocumentReference {
        return userRemindersCollection(userId).document(reminderId)
    }
    
    // Global Collections
    func globalMealsCollection() -> CollectionReference {
        return db.collection(CollectionName.meals)
    }
    
    func globalSymptomsCollection() -> CollectionReference {
        return db.collection(CollectionName.symptoms)
    }
    
    // Additional Collections
    func reminderSettingsCollection() -> CollectionReference {
        return db.collection(CollectionName.reminderSettings)
    }
    
    func testCollection() -> CollectionReference {
        return db.collection(CollectionName.test)
    }
    
    func testDocument(_ documentId: String) -> DocumentReference {
        return testCollection().document(documentId)
    }
    
    // Food Items Subcollection
    func mealFoodItemsCollection(_ userId: String, mealId: String) -> CollectionReference {
        return userMealDocument(userId, mealId: mealId).collection(CollectionName.foodItems)
    }
    
    // Data Deletion Requests Collection
    func dataDeletionRequestsCollection() -> CollectionReference {
        return db.collection(CollectionName.dataDeletionRequests)
    }
    
    func dataDeletionRequestDocument(_ requestId: String) -> DocumentReference {
        return dataDeletionRequestsCollection().document(requestId)
    }
    
    func userDataDeletionRequestsQuery(_ userId: String) -> Query {
        return dataDeletionRequestsCollection().whereField("userId", isEqualTo: userId)
    }
    
    // Storage Path Helpers
    func profileImagesStoragePath() -> String {
        return StoragePath.profileImages
    }
    
    func userStoragePath() -> String {
        return StoragePath.users
    }
    
    // Query Helpers
    func createUserQuery(_ userId: String, collection: String) -> Query {
        return db.collection(CollectionName.users)
            .document(userId)
            .collection(collection)
    }
    
    func queryMealsByUser(_ userId: String) -> Query {
        return db.collection(CollectionName.meals).whereField("userId", isEqualTo: userId)
    }
    
    func querySymptomsByUser(_ userId: String) -> Query {
        return db.collection(CollectionName.symptoms).whereField("userId", isEqualTo: userId)
    }
    
    // Batch Operations Helper
    func batch() -> WriteBatch {
        return db.batch()
    }
    
    // MARK: - Authentication
    
    var currentUser: FirebaseAuth.User? {
        auth.currentUser
    }
    
    func getCurrentUser() async throws -> FirebaseAuth.User {
        guard let user = auth.currentUser else {
            throw FirebaseError.notAuthenticated
        }
        return user
    }
    
    func getFirestoreUser() async throws -> User {
        guard let user = auth.currentUser else {
            throw FirebaseError.notAuthenticated
        }
        
        let docRef = db.collection("users").document(user.uid)
        let document = try await docRef.getDocument()
        
        if !document.exists {
            throw FirebaseError.documentNotFound
        }
        
        return try document.data(as: User.self)
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    // MARK: - Firestore Operations
    
    func getDocuments<T: Decodable>(from collection: String, where field: String, isEqualTo value: Any) async throws -> [T] {
        guard let user = auth.currentUser else {
            throw FirebaseError.notAuthenticated
        }
        
        let query = db.collection(collection)
            .whereField("userId", isEqualTo: user.uid)
            .whereField(field, isEqualTo: value)
            
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.map { try $0.data(as: T.self) }
    }
    
    func updateDocument<T: Encodable>(_ data: T, in collection: String, documentId: String) async throws {
        guard let user = auth.currentUser else {
            throw FirebaseError.notAuthenticated
        }
        
        let docRef = db.collection(collection).document(documentId)
        let document = try await docRef.getDocument()
        
        guard let docData = document.data(),
              let documentUserId = docData["userId"] as? String,
              documentUserId == user.uid else {
            throw FirebaseError.documentNotFound
        }
        
        var dict = try Firestore.Encoder().encode(data)
        dict["updatedAt"] = FieldValue.serverTimestamp()
        
        try await docRef.setData(dict, merge: true)
    }
    
    func deleteDocument(from collection: String, documentId: String) async throws {
        guard let user = auth.currentUser else {
            throw FirebaseError.notAuthenticated
        }
        
        let docRef = db.collection(collection).document(documentId)
        let document = try await docRef.getDocument()
        
        guard let docData = document.data(),
              let documentUserId = docData["userId"] as? String,
              documentUserId == user.uid else {
            throw FirebaseError.documentNotFound
        }
        
        try await docRef.delete()
    }
    
    func addDocument<T: Encodable>(_ data: T, to collection: String) async throws -> String {
        guard let user = auth.currentUser else {
            throw FirebaseError.notAuthenticated
        }
        
        let docRef = db.collection(collection).document()
        
        // Convert to dictionary and add metadata
        var dict = try Firestore.Encoder().encode(data)
        dict["userId"] = user.uid
        dict["createdAt"] = FieldValue.serverTimestamp()
        dict["updatedAt"] = FieldValue.serverTimestamp()
        
        try await docRef.setData(dict)
        return docRef.documentID
    }
    
    func getDocument<T: Decodable>(_ type: T.Type, from collection: String, documentId: String) async throws -> T {
        guard let user = auth.currentUser else {
            throw FirebaseError.notAuthenticated
        }
        
        let docRef = db.collection(collection).document(documentId)
        let document = try await docRef.getDocument()
        
        guard let docData = document.data(),
              let documentUserId = docData["userId"] as? String,
              documentUserId == user.uid else {
            throw FirebaseError.documentNotFound
        }
        
        return try document.data(as: T.self)
    }
    
    // MARK: - Pagination Support
    
    func getPaginatedDocuments<T: Decodable>(
        from collection: String,
        pageSize: Int,
        lastDocument: DocumentSnapshot? = nil,
        sortField: String = "date",
        sortDescending: Bool = true,
        additionalFilters: [String: Any] = [:]
    ) async throws -> (items: [T], lastDocument: DocumentSnapshot?, hasMore: Bool) {
        guard let user = auth.currentUser else {
            throw FirebaseError.notAuthenticated
        }
        
        var query = db.collection(collection)
            .whereField("userId", isEqualTo: user.uid)
        
        // Apply additional filters
        for (field, value) in additionalFilters {
            query = query.whereField(field, isEqualTo: value)
        }
        
        // Apply sorting
        query = query.order(by: sortField, descending: sortDescending)
        
        // Apply pagination
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query = query.limit(to: pageSize)
        
        let snapshot = try await query.getDocuments()
        let documents = snapshot.documents
        
        let items = try documents.compactMap { document in
            try document.data(as: T.self)
        }
        
        let hasMore = documents.count == pageSize
        let lastDoc = documents.last
        
        return (items: items, lastDocument: lastDoc, hasMore: hasMore)
    }
    
    func getPaginatedDocumentsWithDateRange<T: Decodable>(
        from collection: String,
        pageSize: Int,
        lastDocument: DocumentSnapshot? = nil,
        sortField: String = "date",
        sortDescending: Bool = true,
        startDate: Date,
        endDate: Date,
        additionalFilters: [String: Any] = [:]
    ) async throws -> (items: [T], lastDocument: DocumentSnapshot?, hasMore: Bool) {
        guard let user = auth.currentUser else {
            throw FirebaseError.notAuthenticated
        }
        
        var query = db.collection(collection)
            .whereField("userId", isEqualTo: user.uid)
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
        
        // Apply additional filters
        for (field, value) in additionalFilters {
            query = query.whereField(field, isEqualTo: value)
        }
        
        // Apply sorting
        query = query.order(by: sortField, descending: sortDescending)
        
        // Apply pagination
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query = query.limit(to: pageSize)
        
        let snapshot = try await query.getDocuments()
        let documents = snapshot.documents
        
        let items = try documents.compactMap { document in
            try document.data(as: T.self)
        }
        
        let hasMore = documents.count == pageSize
        let lastDoc = documents.last
        
        return (items: items, lastDocument: lastDoc, hasMore: hasMore)
    }
    
    func getDocumentCount(
        from collection: String,
        additionalFilters: [String: Any] = [:]
    ) async throws -> Int {
        guard let user = auth.currentUser else {
            throw FirebaseError.notAuthenticated
        }
        
        var query = db.collection(collection)
            .whereField("userId", isEqualTo: user.uid)
        
        // Apply additional filters
        for (field, value) in additionalFilters {
            query = query.whereField(field, isEqualTo: value)
        }
        
        let snapshot = try await query.count.getAggregation(source: .server)
        return Int(truncating: snapshot.count)
    }
    
    // MARK: - Batch Operations
    
    func batchWrite(_ operations: [BatchOperation]) async throws {
        let batch = db.batch()
        
        for operation in operations {
            let docRef = db.collection(operation.collection).document(operation.documentId)
            
            switch operation {
            case .add(_, _, let data):
                try batch.setData(from: data, forDocument: docRef)
            case .update(_, _, let data):
                try batch.setData(from: data, forDocument: docRef, merge: true)
            case .delete:
                batch.deleteDocument(docRef)
            }
        }
        
        try await batch.commit()
    }
}

// MARK: - Supporting Types

enum BatchOperation {
    case add(collection: String, documentId: String, data: Encodable)
    case update(collection: String, documentId: String, data: Encodable)
    case delete(collection: String, documentId: String)
    
    var collection: String {
        switch self {
        case .add(let collection, _, _),
             .update(let collection, _, _),
             .delete(let collection, _):
            return collection
        }
    }
    
    var documentId: String {
        switch self {
        case .add(_, let documentId, _),
             .update(_, let documentId, _),
             .delete(_, let documentId):
            return documentId
        }
    }
}

// MARK: - Error Types

enum FirebaseError: LocalizedError {
    case notAuthenticated
    case documentNotFound
    case invalidData
    case encodingError
    case decodingError
    case invalidQuery
    case networkError
    case permissionDenied
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid data format"
        case .encodingError:
            return "Failed to encode data"
        case .decodingError:
            return "Failed to decode data"
        case .invalidQuery:
            return "Invalid query parameters"
        case .networkError:
            return "Network error occurred"
        case .permissionDenied:
            return "Permission denied"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
