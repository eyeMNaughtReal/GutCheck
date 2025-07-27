import Foundation
import FirebaseFirestore

/// Manages batch operations for Firebase
class FirebaseBatchManager {
    static let shared = FirebaseBatchManager()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    func perform<T: Encodable>(_ operations: [FirebaseBatchOperation<T>]) async throws {
        let batch = db.batch()
        
        for operation in operations {
            let docRef = db.collection(operation.collection).document(operation.documentId)
            
            switch operation.type {
            case .add(let data):
                try batch.setData(from: data, forDocument: docRef)
            case .update(let data):
                try batch.setData(from: data, forDocument: docRef, merge: true)
            case .delete:
                batch.deleteDocument(docRef)
            }
        }
        
        try await batch.commit()
    }
}

// MARK: - Supporting Types

/// Represents a single batch operation
struct FirebaseBatchOperation<T: Encodable> {
    let collection: String
    let documentId: String
    let type: OperationType
    
    enum OperationType {
        case add(T)
        case update(T)
        case delete
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
