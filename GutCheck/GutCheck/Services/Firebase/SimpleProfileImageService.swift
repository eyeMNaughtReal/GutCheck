//
//  SimpleProfileImageService.swift
//  GutCheck
//
//  Simple, reliable profile image service using standard Firebase Storage patterns
//

import UIKit
import FirebaseStorage
import FirebaseFirestore

@MainActor
class SimpleProfileImageService: ObservableObject {
    private let storage = Storage.storage()
    private let firestore = Firestore.firestore()
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    /// Upload profile image - dead simple approach
    func uploadProfileImage(_ image: UIImage, for userId: String) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        
        defer {
            isUploading = false
        }
        
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProfileImage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        // Create simple storage reference
        let fileName = "profile_\(userId).jpg"
        let storageRef = storage.reference().child("users").child(userId).child(fileName)
        
        uploadProgress = 0.3
        
        // Upload with completion handler (most reliable)
        return try await withCheckedThrowingContinuation { continuation in
            storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                Task { @MainActor in
                    self.uploadProgress = 0.7
                }
                
                // Get download URL
                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let downloadURL = url else {
                        continuation.resume(throwing: NSError(domain: "ProfileImage", code: 2, userInfo: [NSLocalizedDescriptionKey: "No download URL"]))
                        return
                    }
                    
                    let imageURLString = downloadURL.absoluteString
                    
                    // Update Firestore
                    Task {
                        do {
                            try await self.updateUserProfileImageURL(userId: userId, imageURL: imageURLString)
                            await MainActor.run {
                                self.uploadProgress = 1.0
                            }
                            continuation.resume(returning: imageURLString)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
    
    /// Download profile image from URL
    func downloadProfileImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "ProfileImage", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "ProfileImage", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to decode image"])
        }
        
        return image
    }
    
    /// Delete profile image from storage
    func deleteProfileImage(for userId: String) async throws {
        let fileName = "profile_\(userId).jpg"
        let storageRef = storage.reference().child("users").child(userId).child(fileName)
        
        try await storageRef.delete()
        try await removeProfileImageURL(for: userId)
    }
    
    // MARK: - Firestore Updates
    
    private func updateUserProfileImageURL(userId: String, imageURL: String) async throws {
        let userRef = FirebaseCollectionManager.shared.userDocument(userId)
        
        try await userRef.updateData([
            "profileImageURL": imageURL,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    private func removeProfileImageURL(for userId: String) async throws {
        let userRef = FirebaseCollectionManager.shared.userDocument(userId)
        
        try await userRef.updateData([
            "profileImageURL": FieldValue.delete(),
            "updatedAt": Timestamp(date: Date())
        ])
    }
}
