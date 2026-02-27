//
//  LocalStorageService.swift
//  GutCheck
//
//  Service for encrypted local storage of private user data.
//  Implements CryptoKit encryption for sensitive information that should
//  never leave the device (private notes, detailed symptoms, personal observations).
//
//  Created by Mark Conley on 8/11/25.
//

import Foundation
import CryptoKit
import Security

/// Service for encrypted local storage of private user data
/// All private data is encrypted with CryptoKit and stored locally on the device
/// This ensures sensitive information never leaves the user's control
class LocalStorageService {
    static let shared = LocalStorageService()

    // MARK: - Keychain Constants

    private static let keychainService = "com.gutcheck.localstorage"
    private static let keychainAccount = "LocalStorageEncryptionKey"

    // MARK: - Private Properties

    /// Encryption key loaded from (or persisted to) the iOS Keychain
    private var encryptionKey: SymmetricKey?
    
    /// File manager for document directory access
    private let fileManager = FileManager.default
    
    /// Document directory path for local storage
    private var documentDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// Private data directory path
    private var privateDataDirectory: URL {
        documentDirectory.appendingPathComponent("PrivateData", isDirectory: true)
    }
    
    // MARK: - Initialization
    
    private init() {
        setupPrivateDataDirectory()
        loadOrCreateEncryptionKey()
    }
    
    // MARK: - Setup Methods
    
    /// Create the private data directory if it doesn't exist
    private func setupPrivateDataDirectory() {
        if !fileManager.fileExists(atPath: privateDataDirectory.path) {
            try? fileManager.createDirectory(at: privateDataDirectory, withIntermediateDirectories: true)
        }
    }
    
    /// Load the encryption key from the Keychain, or generate and store a new one on first launch.
    /// The key is a random 256-bit value stored with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`,
    /// which ties it to this device and survives app reinstalls (until the device is wiped).
    private func loadOrCreateEncryptionKey() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: LocalStorageService.keychainService,
            kSecAttrAccount as String: LocalStorageService.keychainAccount,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let keyData = result as? Data {
            encryptionKey = SymmetricKey(data: keyData)
            return
        }

        // Key not found — generate a fresh random 256-bit key and persist it.
        var newKeyBytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, newKeyBytes.count, &newKeyBytes) == errSecSuccess else {
            return
        }
        let newKeyData = Data(newKeyBytes)

        let addQuery: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: LocalStorageService.keychainService,
            kSecAttrAccount as String: LocalStorageService.keychainAccount,
            kSecValueData as String:   newKeyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
        encryptionKey = SymmetricKey(data: newKeyData)
    }

    /// Delete the Keychain key and generate a fresh one. All previously encrypted
    /// files become permanently unreadable — always call clearAllPrivateData() first.
    private func resetKeychainKey() {
        let deleteQuery: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: LocalStorageService.keychainService,
            kSecAttrAccount as String: LocalStorageService.keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        loadOrCreateEncryptionKey()
    }
    
    // MARK: - Public Methods
    
    /// Store private data locally with encryption
    /// - Parameters:
    ///   - item: The data item to store
    ///   - type: The type of data for organization
    /// - Throws: Encryption or storage errors
    func storePrivateData<T: Codable>(_ item: T, type: String, id: String) async throws {
        guard let encryptionKey = encryptionKey else {
            throw LocalStorageError.encryptionKeyUnavailable
        }
        
        do {
            // Encode the data
            let data = try JSONEncoder().encode(item)
            #if DEBUG
            print("🔒 Encoding data for storage: \(type)/\(id), size: \(data.count) bytes")
            #endif

            // Encrypt the data
            let encryptedData = try encrypt(data, using: encryptionKey)
            #if DEBUG
            print("🔒 Data encrypted successfully: \(encryptedData.count) bytes")
            #endif

            // Create file path
            let fileName = "\(type)_\(id).encrypted"
            let fileURL = privateDataDirectory.appendingPathComponent(fileName)

            // Write encrypted data to file
            try encryptedData.write(to: fileURL)

            #if DEBUG
            print("🔒 Stored private data: \(type)/\(id) (encrypted)")
            #endif
        } catch let error as LocalStorageError {
            #if DEBUG
            print("❌ LocalStorage error: \(error)")
            #endif
            throw error
        } catch {
            #if DEBUG
            print("❌ Unexpected error during encryption/storage: \(error)")
            if let cryptoError = error as? CryptoKitError {
                print("🔐 CryptoKit error code: \(cryptoError)")
            }
            #endif
            throw LocalStorageError.encryptionFailed
        }
    }
    
    /// Retrieve private data from local encrypted storage
    /// - Parameters:
    ///   - type: The type of data to retrieve
    ///   - id: The unique identifier
    ///   - itemType: The expected data type
    /// - Returns: The decrypted data item
    /// - Throws: Decryption or storage errors
    func retrievePrivateData<T: Codable>(type: String, id: String, as itemType: T.Type) async throws -> T? {
        guard let encryptionKey = encryptionKey else {
            throw LocalStorageError.encryptionKeyUnavailable
        }
        
        do {
            // Create file path
            let fileName = "\(type)_\(id).encrypted"
            let fileURL = privateDataDirectory.appendingPathComponent(fileName)
            
            // Check if file exists
            guard fileManager.fileExists(atPath: fileURL.path) else {
                #if DEBUG
                print("🔍 File not found: \(fileName)")
                #endif
                return nil
            }

            // Read encrypted data
            let encryptedData = try Data(contentsOf: fileURL)
            #if DEBUG
            print("🔓 Reading encrypted data: \(fileName), size: \(encryptedData.count) bytes")
            #endif

            // Decrypt the data
            let decryptedData = try decrypt(encryptedData, using: encryptionKey)
            #if DEBUG
            print("🔓 Data decrypted successfully: \(decryptedData.count) bytes")
            #endif

            // Decode the data
            let item = try JSONDecoder().decode(itemType, from: decryptedData)

            #if DEBUG
            print("🔓 Retrieved private data: \(type)/\(id) (decrypted)")
            #endif
            return item
        } catch let error as LocalStorageError {
            #if DEBUG
            print("❌ LocalStorage error during retrieval: \(error)")
            #endif
            throw error
        } catch {
            #if DEBUG
            print("❌ Unexpected error during decryption/retrieval: \(error)")
            if let cryptoError = error as? CryptoKitError {
                print("🔐 CryptoKit error code: \(cryptoError)")
            }
            #endif
            throw LocalStorageError.decryptionFailed
        }
    }
    
    /// Delete private data from local storage
    /// - Parameters:
    ///   - type: The type of data to delete
    ///   - id: The unique identifier
    /// - Throws: File system errors
    func deletePrivateData(type: String, id: String) async throws {
        let fileName = "\(type)_\(id).encrypted"
        let fileURL = privateDataDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
            #if DEBUG
            print("🗑️ Deleted private data: \(type)/\(id)")
            #endif
        }
    }
    
    /// List all stored private data types
    /// - Returns: Array of data type identifiers
    func listPrivateDataTypes() -> [String] {
        do {
            let files = try fileManager.contentsOfDirectory(at: privateDataDirectory, includingPropertiesForKeys: nil)
            let types = files.compactMap { file -> String? in
                let fileName = file.lastPathComponent
                let components = fileName.components(separatedBy: "_")
                return components.first
            }
            return Array(Set(types)) // Remove duplicates
        } catch {
            #if DEBUG
            print("❌ Error listing private data types: \(error)")
            #endif
            return []
        }
    }
    
    /// List all private data files for a specific type
    /// - Parameter type: The data type to list files for
    /// - Returns: Array of filenames for the specified type
    func listPrivateDataFiles(for type: String) async throws -> [String] {
        do {
            let files = try fileManager.contentsOfDirectory(at: privateDataDirectory, includingPropertiesForKeys: nil)
            let typeFiles = files.compactMap { file -> String? in
                let fileName = file.lastPathComponent
                if fileName.hasPrefix("\(type)_") && fileName.hasSuffix(".encrypted") {
                    return fileName
                }
                return nil
            }
            #if DEBUG
            print("🔍 Found \(typeFiles.count) files for type: \(type)")
            #endif
            return typeFiles
        } catch {
            #if DEBUG
            print("❌ Error listing private data files for type \(type): \(error)")
            #endif
            return []
        }
    }
    
    /// Clear all private data (used for account deletion)
    func clearAllPrivateData() async throws {
        let files = try fileManager.contentsOfDirectory(at: privateDataDirectory, includingPropertiesForKeys: nil)
        
        for file in files {
            try fileManager.removeItem(at: file)
        }

        #if DEBUG
        print("🗑️ Cleared all private data")
        #endif
    }
    
    /// Reset encryption and clear all data (recovery from corruption).
    /// Deletes the Keychain key and all encrypted files, then generates a fresh key.
    func resetEncryptionAndClearData() async throws {
        // Clear all existing encrypted files first — the old key is still
        // available at this point so decryption would still be possible if needed.
        try await clearAllPrivateData()

        // Remove old Keychain key and generate a new random one.
        resetKeychainKey()

        #if DEBUG
        print("✅ Encryption reset and data cleared")
        #endif
    }
    
    // MARK: - Encryption Methods
    
    /// Encrypt data using AES-GCM
    /// - Parameters:
    ///   - data: The data to encrypt
    ///   - key: The encryption key
    /// - Returns: Encrypted data
    /// - Throws: Encryption errors
    private func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    /// Decrypt data using AES-GCM
    /// - Parameters:
    ///   - data: The encrypted data
    ///   - key: The decryption key
    /// - Returns: Decrypted data
    /// - Throws: Decryption errors
    private func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

// MARK: - Errors

enum LocalStorageError: LocalizedError {
    case encryptionKeyUnavailable
    case encryptionFailed
    case decryptionFailed
    case storageFailed
    case dataNotFound
    
    var errorDescription: String? {
        switch self {
        case .encryptionKeyUnavailable:
            return "Encryption key is not available"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .storageFailed:
            return "Failed to store data locally"
        case .dataNotFound:
            return "Private data not found"
        }
    }
}
