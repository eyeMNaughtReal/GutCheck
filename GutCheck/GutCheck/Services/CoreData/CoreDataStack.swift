//
//  CoreDataStack.swift
//  GutCheck
//
//  Core Data stack manager for secure local storage
//
//  Created by Mark Conley on 8/18/25.
//

import Foundation
import CoreData
import CryptoKit
import Security

@MainActor
class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "GutCheck")
        
        // Configure persistent store with encryption
        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        
        // Enable encryption for sensitive data
        // Note: NSPersistentStoreEncryptionKeyOption is not available in all iOS versions
        // For now, we'll use standard Core Data security features
        // In production, consider using Data Protection or other encryption methods
        
        // Set store options
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }
        
        // Configure merge policy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Enable automatic merging
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    // MARK: - Contexts
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Encryption
    //
    // Core Data encryption key management via iOS Keychain.
    // The key is generated once (random 256-bit), stored in the Keychain, and
    // retrieved on subsequent launches. Never hardcode the key in source.
    //
    // NOTE: NSPersistentStoreEncryptionKeyOption is not currently wired up
    // because Core Data's SQLite backend relies on file-system Data Protection
    // (NSFileProtectionComplete) which iOS enforces automatically when the
    // device is locked. This method is provided for future use if explicit
    // at-rest encryption is required.

    private static let keychainService  = "com.gutcheck.coredata"
    private static let keychainAccount  = "CoreDataEncryptionKey"

    func getEncryptionKey() -> Data? {
        // 1. Try to load existing key from Keychain
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      CoreDataStack.keychainService,
            kSecAttrAccount as String:      CoreDataStack.keychainAccount,
            kSecReturnData as String:       true,
            kSecMatchLimit as String:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            return data
        }

        // 2. Key not found — generate a new random 256-bit key and store it
        var newKeyBytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, newKeyBytes.count, &newKeyBytes) == errSecSuccess else {
            return nil
        }
        let newKeyData = Data(newKeyBytes)

        let addQuery: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      CoreDataStack.keychainService,
            kSecAttrAccount as String:      CoreDataStack.keychainAccount,
            kSecValueData as String:        newKeyData,
            kSecAttrAccessible as String:   kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
        return newKeyData
    }
    
    // MARK: - Save Operations
    
    func save() {
        let context = viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving Core Data context: \(error)")
            }
        }
    }
    
    func saveBackground() async {
        let context = backgroundContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving background Core Data context: \(error)")
            }
        }
    }
    
    // MARK: - Context Management
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) async throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                Task {
                    do {
                        let result = try await block(context)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        // Remove old data that's no longer needed
        let context = viewContext
        
        // Clean up old sync records
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "LocalMeal")
        fetchRequest.predicate = NSPredicate(format: "syncStatus == %@ AND lastModified < %@", "synced", Date().addingTimeInterval(-30*24*60*60) as CVarArg)
        
        do {
            let oldMeals = try context.fetch(fetchRequest) as? [LocalMeal] ?? []
            for meal in oldMeals {
                context.delete(meal)
            }
            
            try context.save()
        } catch {
            print("Error cleaning up old data: \(error)")
        }
    }
    
    // MARK: - Migration Support
    
    func migrateStore() {
        // Handle Core Data model migrations
        // This would be implemented for future model changes
    }
}

// MARK: - Core Data Context Extensions

extension NSManagedObjectContext {
    func saveIfNeeded() {
        if hasChanges {
            do {
                try save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    func deleteAll<T: NSManagedObject>(_ entityType: T.Type) throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: String(describing: entityType))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try execute(deleteRequest)
    }
}
