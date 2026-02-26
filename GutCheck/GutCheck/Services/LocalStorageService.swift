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
import UIKit // Added for UIDevice

/// Service for encrypted local storage of private user data
/// All private data is encrypted with CryptoKit and stored locally on the device
/// This ensures sensitive information never leaves the user's control
class LocalStorageService {
    static let shared = LocalStorageService()
    
    // MARK: - Private Properties
    
    /// Encryption key derived from device-specific information
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
        generateEncryptionKey()
    }
    
    // MARK: - Setup Methods
    
    /// Create the private data directory if it doesn't exist
    private func setupPrivateDataDirectory() {
        if !fileManager.fileExists(atPath: privateDataDirectory.path) {
            try? fileManager.createDirectory(at: privateDataDirectory, withIntermediateDirectories: true)
        }
    }
    
    /// Generate encryption key from device-specific information
    /// This ensures data can only be decrypted on the same device
    private func generateEncryptionKey() {
        // Use device identifier and user-specific salt for key generation
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let salt = "GutCheckPrivateData2025" // In production, this should be user-specific
        
        // Create a deterministic but properly sized key using SHA256
        let combinedString = deviceId + salt
        let keyData = Data(combinedString.utf8)
        let hash = SHA256.hash(data: keyData)
        
        // Create a 256-bit key (32 bytes) from the hash
        encryptionKey = SymmetricKey(data: hash)
        
        #if DEBUG
        print("🔑 Generated encryption key from device ID")
        #endif
    }
    
    /// Regenerate encryption key (useful for recovery from key corruption)
    private func regenerateEncryptionKey() {
        print("🔄 Regenerating encryption key...")
        generateEncryptionKey()
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
            print("🔒 Encoding data for storage: \(type)/\(id), size: \(data.count) bytes")
            
            // Encrypt the data
            let encryptedData = try encrypt(data, using: encryptionKey)
            print("🔒 Data encrypted successfully: \(encryptedData.count) bytes")
            
            // Create file path
            let fileName = "\(type)_\(id).encrypted"
            let fileURL = privateDataDirectory.appendingPathComponent(fileName)
            
            // Write encrypted data to file
            try encryptedData.write(to: fileURL)
            
            print("🔒 Stored private data: \(type)/\(id) (encrypted)")
        } catch let error as LocalStorageError {
            print("❌ LocalStorage error: \(error)")
            throw error
        } catch {
            print("❌ Unexpected error during encryption/storage: \(error)")
            if let cryptoError = error as? CryptoKitError {
                print("🔐 CryptoKit error code: \(cryptoError)")
            }
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
                print("🔍 File not found: \(fileName)")
                return nil
            }
            
            // Read encrypted data
            let encryptedData = try Data(contentsOf: fileURL)
            print("🔓 Reading encrypted data: \(fileName), size: \(encryptedData.count) bytes")
            
            // Decrypt the data
            let decryptedData = try decrypt(encryptedData, using: encryptionKey)
            print("🔓 Data decrypted successfully: \(decryptedData.count) bytes")
            
            // Decode the data
            let item = try JSONDecoder().decode(itemType, from: decryptedData)
            
            print("🔓 Retrieved private data: \(type)/\(id) (decrypted)")
            return item
        } catch let error as LocalStorageError {
            print("❌ LocalStorage error during retrieval: \(error)")
            throw error
        } catch {
            print("❌ Unexpected error during decryption/retrieval: \(error)")
            if let cryptoError = error as? CryptoKitError {
                print("🔐 CryptoKit error code: \(cryptoError)")
            }
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
            print("🗑️ Deleted private data: \(type)/\(id)")
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
            print("❌ Error listing private data types: \(error)")
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
            print("🔍 Found \(typeFiles.count) files for type: \(type)")
            return typeFiles
        } catch {
            print("❌ Error listing private data files for type \(type): \(error)")
            return []
        }
    }
    
    /// Clear all private data (used for account deletion)
    func clearAllPrivateData() async throws {
        let files = try fileManager.contentsOfDirectory(at: privateDataDirectory, includingPropertiesForKeys: nil)
        
        for file in files {
            try fileManager.removeItem(at: file)
        }
        
        print("🗑️ Cleared all private data")
    }
    
    /// Reset encryption and clear all data (recovery from corruption)
    func resetEncryptionAndClearData() async throws {
        print("🔄 Resetting encryption and clearing all data...")
        
        // Clear all existing data
        try await clearAllPrivateData()
        
        // Regenerate encryption key
        regenerateEncryptionKey()
        
        print("✅ Encryption reset and data cleared")
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
