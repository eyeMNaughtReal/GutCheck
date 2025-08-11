//
//  UnifiedDataService.swift
//  GutCheck
//
//  Service for unified data storage that automatically routes data to the appropriate
//  storage location based on privacy levels:
//  - Private data → Local encrypted storage (device only)
//  - Public data → Firebase cloud storage (with sync)
//
//  Created by Mark Conley on 8/11/25.
//

import Foundation
import FirebaseFirestore

/// Protocol for data items that can be classified by privacy level
protocol DataClassifiable {
    var privacyLevel: DataPrivacyLevel { get }
    var requiresLocalStorage: Bool { get }
    var allowsCloudSync: Bool { get }
}

/// Unified data service that automatically routes data to appropriate storage
/// based on privacy classification and user preferences
class UnifiedDataService: ObservableObject {
    static let shared = UnifiedDataService()
    
    // MARK: - Private Properties
    
    /// Local encrypted storage for private data
    private let privateStorage = LocalStorageService.shared
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Save data item to appropriate storage based on privacy level
    /// - Parameter item: The data item to save
    /// - Throws: Storage or encryption errors
    func save<T: DataClassifiable & Codable>(_ item: T) async throws {
        print("🔄 UnifiedDataService: Saving item with privacy level: \(item.privacyLevel)")
        
        switch item.privacyLevel {
        case .private, .confidential:
            // Store sensitive data locally with encryption
            try await storePrivateData(item)
            
        case .public:
            // Store non-sensitive data in the cloud
            try await storeCloudData(item)
        }
    }
    
    /// Fetch data item from appropriate storage
    /// - Parameters:
    ///   - type: The expected data type
    ///   - id: The unique identifier
    /// - Returns: The retrieved data item
    /// - Throws: Storage or decryption errors
    func fetch<T: DataClassifiable & Codable>(_ type: T.Type, id: String) async throws -> T? {
        print("🔄 UnifiedDataService: Fetching item with ID: \(id)")
        
        // Try private storage first (for sensitive data)
        if let privateItem = try await privateStorage.retrievePrivateData(type: String(describing: type), id: id, as: type) {
            print("🔒 Retrieved from private storage: \(id)")
            return privateItem
        }
        
        // For now, we'll need to implement cloud storage fetching
        // This is a simplified approach
        print("☁️ Cloud storage fetching not yet implemented")
        return nil
    }
    
    /// Delete data item from all storage locations
    /// - Parameters:
    ///   - type: The data type
    ///   - id: The unique identifier
    /// - Throws: Storage errors
    func delete<T: DataClassifiable>(_ type: T.Type, id: String) async throws {
        print("🔄 UnifiedDataService: Deleting item with ID: \(id)")
        
        // Delete from private storage
        try await privateStorage.deletePrivateData(type: String(describing: type), id: id)
        
        // TODO: Delete from cloud storage when implemented
        print("✅ Deleted item from private storage: \(id)")
    }
    
    /// Query data from appropriate storage based on privacy requirements
    /// - Parameters:
    ///   - type: The data type to query
    ///   - queryBuilder: Query builder closure
    /// - Returns: Array of matching data items
    /// - Throws: Storage or decryption errors
    func query<T: DataClassifiable & Codable>(_ type: T.Type, queryBuilder: (Query) -> Query) async throws -> [T] {
        print("🔄 UnifiedDataService: Querying data of type: \(String(describing: type))")
        
        let results: [T] = []
        
        // Query private storage for sensitive data
        let privateTypes = privateStorage.listPrivateDataTypes()
        for dataType in privateTypes {
            if dataType == String(describing: type) {
                // For now, we'll need to implement a more sophisticated query system
                // This is a simplified approach
                print("🔒 Querying private storage for type: \(dataType)")
            }
        }
        
        // TODO: Query cloud storage for public data
        print("☁️ Cloud storage querying not yet implemented")
        
        print("✅ Query completed. Found \(results.count) items")
        return results
    }
    
    // MARK: - Private Methods
    
    /// Store data in private local storage
    /// - Parameter item: The data item to store
    /// - Throws: Encryption or storage errors
    private func storePrivateData<T: Codable>(_ item: T) async throws {
        let type = String(describing: type(of: item))
        let id = (item as? any Identifiable)?.id as? String ?? UUID().uuidString
        
        try await privateStorage.storePrivateData(item, type: type, id: id)
        print("🔒 Stored in private storage: \(type)/\(id)")
    }
    
    /// Store data in cloud storage
    /// - Parameter item: The data item to store
    /// - Throws: Cloud storage errors
    private func storeCloudData<T: Codable>(_ item: T) async throws {
        // TODO: Implement cloud storage when Firebase integration is ready
        print("☁️ Cloud storage not yet implemented for: \(String(describing: type(of: item)))")
    }
}

// MARK: - Extensions for Existing Models

/// Extension to make Meal conform to DataClassifiable
extension Meal: DataClassifiable {}

/// Extension to make Symptom conform to DataClassifiable
extension Symptom: DataClassifiable {}

/// Extension to make MedicationRecord conform to DataClassifiable
extension MedicationRecord: DataClassifiable {}
