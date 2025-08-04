import Foundation
import FirebaseFirestore
import FirebaseAuth

// FirebaseError moved to FirebaseBatchManager.swift to avoid duplicate declarations

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    private init() {}
    
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
