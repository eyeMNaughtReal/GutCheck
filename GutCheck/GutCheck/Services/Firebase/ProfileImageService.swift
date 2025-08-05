//
//  ProfileImageService.swift
//  GutCheck
//
//  Service for handling profile image upload, download, and management with Firebase Storage
//

import UIKit
import FirebaseStorage
import FirebaseFirestore

@MainActor
class ProfileImageService: ObservableObject {
    private let storage = Storage.storage()
    private let firestore = Firestore.firestore()
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    /// Upload a profile image to Firebase Storage and update the user's profile
    func uploadProfileImage(_ image: UIImage, for userId: String) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        
        defer {
            isUploading = false
            uploadProgress = 0.0
        }
        
        do {
            // Compress and prepare image data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw ProfileImageError.imageCompressionFailed
            }
            
            // Create storage reference
            let fileName = "profile_\(userId)_\(Date().timeIntervalSince1970).jpg"
            let storageRef = storage.reference().child("profile_images").child(fileName)
            
            // Set upload progress to indicate start
            uploadProgress = 0.1
            
            // Upload image using proper Firebase Storage method
            return try await withCheckedThrowingContinuation { continuation in
                let uploadTask = storageRef.putData(imageData, metadata: nil) { metadata, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    // Upload successful, wait a moment then get download URL
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.getDownloadURLWithRetry(storageRef: storageRef, userId: userId, maxRetries: 3) { result in
                            switch result {
                            case .success(let imageURLString):
                                continuation.resume(returning: imageURLString)
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
                
                // Monitor upload progress
                uploadTask.observe(.progress) { [weak self] snapshot in
                    if let progress = snapshot.progress {
                        Task { @MainActor in
                            self?.uploadProgress = 0.1 + (Double(progress.completedUnitCount) / Double(progress.totalUnitCount) * 0.7)
                        }
                    }
                }
            }
            
        } catch {
            errorMessage = "Failed to upload profile image: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Download profile image from URL
    func downloadProfileImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw ProfileImageError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw ProfileImageError.imageDecodingFailed
        }
        
        return image
    }
    
    /// Delete old profile image from storage
    func deleteProfileImage(from urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw ProfileImageError.invalidURL
        }
        
        // Extract the path from the URL
        let pathComponents = url.pathComponents
        if let profileImagesIndex = pathComponents.firstIndex(of: "profile_images"),
           profileImagesIndex + 1 < pathComponents.count {
            let fileName = pathComponents[profileImagesIndex + 1]
            let storageRef = storage.reference().child("profile_images").child(fileName)
            
            try await storageRef.delete()
        }
    }
    
    /// Update user's profile image URL in Firestore
    private func updateUserProfileImageURL(userId: String, imageURL: String) async throws {
        let userRef = FirebaseCollectionManager.shared.userDocument(userId)
        
        try await userRef.updateData([
            "profileImageURL": imageURL,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    /// Remove profile image URL from user document
    func removeProfileImageURL(for userId: String) async throws {
        let userRef = FirebaseCollectionManager.shared.userDocument(userId)
        
        try await userRef.updateData([
            "profileImageURL": FieldValue.delete(),
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    /// Helper method to get download URL with retry logic
    private func getDownloadURLWithRetry(storageRef: StorageReference, userId: String, maxRetries: Int, completion: @escaping (Result<String, Error>) -> Void) {
        storageRef.downloadURL { url, error in
            if let error = error {
                if maxRetries > 0 {
                    // Retry after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.getDownloadURLWithRetry(storageRef: storageRef, userId: userId, maxRetries: maxRetries - 1, completion: completion)
                    }
                } else {
                    completion(.failure(error))
                }
                return
            }
            
            guard let downloadURL = url else {
                if maxRetries > 0 {
                    // Retry after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.getDownloadURLWithRetry(storageRef: storageRef, userId: userId, maxRetries: maxRetries - 1, completion: completion)
                    }
                } else {
                    completion(.failure(ProfileImageError.uploadFailed))
                }
                return
            }
            
            let imageURLString = downloadURL.absoluteString
            
            // Update progress
            Task { @MainActor in
                self.uploadProgress = 0.9
            }
            
            // Update user document in Firestore
            Task {
                do {
                    try await self.updateUserProfileImageURL(userId: userId, imageURL: imageURLString)
                    await MainActor.run {
                        self.uploadProgress = 1.0
                    }
                    completion(.success(imageURLString))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
}

