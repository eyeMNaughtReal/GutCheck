//
//  LocalProfileImageService.swift
//  GutCheck
//
//  Local profile image storage using iOS Documents directory
//

import UIKit
import FirebaseFirestore

@MainActor
class LocalProfileImageService: ObservableObject {
    private let firestore = Firestore.firestore()
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    /// Save profile image locally and update Firestore with local flag
    func uploadProfileImage(_ image: UIImage, for userId: String) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        
        defer {
            isUploading = false
        }
        
        // Compress image
        let imageData = try ImageCompressionUtility.compress(image, quality: .standard)
        
        uploadProgress = 0.3
        
        // Get documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ProfileImage", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        
        // Create profile images directory if it doesn't exist
        let profileImagesDirectory = documentsDirectory.appendingPathComponent("ProfileImages")
        if !FileManager.default.fileExists(atPath: profileImagesDirectory.path) {
            try FileManager.default.createDirectory(at: profileImagesDirectory, withIntermediateDirectories: true)
        }
        
        uploadProgress = 0.5
        
        // Save image to local file
        let fileName = "profile_\(userId).jpg"
        let fileURL = profileImagesDirectory.appendingPathComponent(fileName)
        
        try imageData.write(to: fileURL)
        
        // Create a local identifier for the image
        let localImagePath = "local://\(fileName)"
        
        uploadProgress = 1.0
        
        // No Firestore update needed - image is stored locally
        // Post notification to trigger UI refresh
        print("📢 LocalProfileImageService: Local image saved, posting refresh notification")
        NotificationCenter.default.post(name: .profileImageUpdated, object: nil)
        
        return localImagePath
    }
    
    /// Load profile image from local storage
    func downloadProfileImage(from urlString: String) async throws -> UIImage {
        // Check if it's a local image
        if urlString.hasPrefix("local://") {
            let fileName = String(urlString.dropFirst(8)) // Remove "local://" prefix
            return try loadLocalImage(fileName: fileName)
        }
        
        // Handle remote URLs (if any exist from before)
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "ProfileImage", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "ProfileImage", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to decode image"])
        }
        
        return image
    }
    
    /// Load image from local storage
    private func loadLocalImage(fileName: String) throws -> UIImage {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ProfileImage", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        
        let profileImagesDirectory = documentsDirectory.appendingPathComponent("ProfileImages")
        let fileURL = profileImagesDirectory.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw NSError(domain: "ProfileImage", code: 5, userInfo: [NSLocalizedDescriptionKey: "Profile image file not found"])
        }
        
        guard let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            throw NSError(domain: "ProfileImage", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to load local image"])
        }
        
        return image
    }
    
    /// Delete profile image from local storage
    func deleteProfileImage(for userId: String) async throws {
        let fileName = "profile_\(userId).jpg"
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ProfileImage", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        
        let profileImagesDirectory = documentsDirectory.appendingPathComponent("ProfileImages")
        let fileURL = profileImagesDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        try await removeProfileImageURL(for: userId)
    }
    
    /// Check if user has a local profile image
    func hasLocalProfileImage(for userId: String) -> Bool {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let profileImagesDirectory = documentsDirectory.appendingPathComponent("ProfileImages")
        let fileName = "profile_\(userId).jpg"
        let fileURL = profileImagesDirectory.appendingPathComponent(fileName)
        
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Firestore Updates
    
    private func updateUserProfileImageURL(userId: String, imageURL: String) async throws {
        let userRef = FirebaseManager.shared.userDocument(userId)
        
        print("🔥 LocalProfileImageService: Updating Firestore for user \(userId) with imageURL: \(imageURL)")
        
        try await userRef.updateData([
            "profileImageURL": imageURL,
            "updatedAt": Timestamp(date: Date())
        ])
        
        print("🔥 LocalProfileImageService: Firestore update completed successfully")
        
        // Verify the update by reading it back
        let document = try await userRef.getDocument()
        if let data = document.data(), let savedURL = data["profileImageURL"] as? String {
            print("🔥 LocalProfileImageService: Verified Firestore has profileImageURL: \(savedURL)")
        } else {
            print("❌ LocalProfileImageService: Failed to verify Firestore update")
        }
    }
    
    private func removeProfileImageURL(for userId: String) async throws {
        let userRef = FirebaseManager.shared.userDocument(userId)
        
        try await userRef.updateData([
            "profileImageURL": FieldValue.delete(),
            "updatedAt": Timestamp(date: Date())
        ])
    }
}
