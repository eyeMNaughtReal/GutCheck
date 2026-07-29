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
@Observable class CoreDataStack {
    static let shared = CoreDataStack()
    
    // MARK: - Core Data Stack
    
    @ObservationIgnored lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "GutCheck")
        
        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType

        // Data Protection for the store file.
        //
        // The store holds PII and health data — email, date of birth, weight,
        // height, meals and symptoms — which CodeQL flags as cleartext storage
        // in a local database (alerts #9, #10). Without this option the file
        // gets iOS's default, `completeUntilFirstUserAuthentication`, meaning it
        // stays readable from the moment the device is first unlocked after
        // boot until it powers off.
        //
        // `.completeUnlessOpen` is used rather than `.complete` deliberately.
        // `.complete` makes the file unreadable whenever the device is locked,
        // which would break the BGProcessingTask insight refresh — background
        // tasks typically run while locked, and it would fail every time.
        // `.completeUnlessOpen` protects the file at rest but lets a handle
        // opened before locking keep working, which is the balance this app
        // needs.
        description.setOption(FileProtectionType.completeUnlessOpen as NSObject,
                              forKey: NSPersistentStoreFileProtectionKey)

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
    // NOTE: NSPersistentStoreEncryptionKeyOption is not currently wired up.
    // At-rest protection comes from file-system Data Protection, now set
    // explicitly as `.completeUnlessOpen` on the store description above.
    //
    // This comment previously claimed iOS applied NSFileProtectionComplete
    // "automatically". It does not — the default for app container files is
    // `completeUntilFirstUserAuthentication`, which is materially weaker, and
    // no protection level was being set at all. This method remains available
    // if explicit at-rest encryption is required later.

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
            }
        }
    }
    
    func saveBackground() async {
        let context = backgroundContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
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
        fetchRequest.predicate = NSPredicate(format: "syncStatus == %@ AND lastModified < %@", "synced", Date.now.addingTimeInterval(-30*24*60*60) as CVarArg)
        
        do {
            let oldMeals = try context.fetch(fetchRequest) as? [LocalMeal] ?? []
            for meal in oldMeals {
                context.delete(meal)
            }
            
            try context.save()
        } catch {
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
            }
        }
    }
    
    func deleteAll<T: NSManagedObject>(_ entityType: T.Type) throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: String(describing: entityType))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try execute(deleteRequest)
    }
}
