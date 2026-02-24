//
//  LocalProfileImageStrategy.swift
//  GutCheck
//
//  Local file storage strategy using iOS Documents directory
//

import UIKit
@preconcurrency import FirebaseFirestore

class LocalProfileImageStrategy: ProfileImageStrategy {
    private let firestore = Firestore.firestore()
    weak var delegate: ProfileImageStrategyDelegate?
    
    func uploadProfileImage(_ image: UIImage, for userId: String) async throws -> String {
        await MainActor.run {
            delegate?.strategyDidUpdateProgress(0.0)
        }
        
        let imageData = try ImageCompressionUtility.compress(image, quality: .standard)
        
        await MainActor.run {
            delegate?.strategyDidUpdateProgress(0.3)
        }
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ProfileImage", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        
        let profileImagesDirectory = documentsDirectory.appendingPathComponent("ProfileImages")
        if !FileManager.default.fileExists(atPath: profileImagesDirectory.path) {
            try FileManager.default.createDirectory(at: profileImagesDirectory, withIntermediateDirectories: true)
        }
        
        await MainActor.run {
            delegate?.strategyDidUpdateProgress(0.5)
        }
        
        let fileName = "profile_\(userId).jpg"
        let fileURL = profileImagesDirectory.appendingPathComponent(fileName)
        
        try imageData.write(to: fileURL)
        
        let localImagePath = "local://\(fileName)"
        
        await MainActor.run {
            delegate?.strategyDidUpdateProgress(1.0)
            print("📢 LocalProfileImageStrategy: Local image saved, posting refresh notification")
            NotificationCenter.default.post(name: .profileImageUpdated, object: nil)
        }
        
        return localImagePath
    }
    
    func downloadProfileImage(from urlString: String) async throws -> UIImage {
        if urlString.hasPrefix("local://") {
            let fileName = String(urlString.dropFirst(8))
            return try loadLocalImage(fileName: fileName)
        }
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "ProfileImage", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "ProfileImage", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to decode image"])
        }
        
        return image
    }
    
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
    
    func hasLocalProfileImage(for userId: String) -> Bool {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let profileImagesDirectory = documentsDirectory.appendingPathComponent("ProfileImages")
        let fileName = "profile_\(userId).jpg"
        let fileURL = profileImagesDirectory.appendingPathComponent(fileName)
        
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
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
    
    private func updateUserProfileImageURL(userId: String, imageURL: String) async throws {
        let userRef = FirebaseManager.shared.userDocument(userId)
        
        print("🔥 LocalProfileImageStrategy: Updating Firestore for user \(userId) with imageURL: \(imageURL)")
        
        try await userRef.updateData([
            "profileImageURL": imageURL,
            "updatedAt": Timestamp(date: Date())
        ])
        
        print("🔥 LocalProfileImageStrategy: Firestore update completed successfully")
        
        let document = try await userRef.getDocument()
        if let data = document.data(), let savedURL = data["profileImageURL"] as? String {
            print("🔥 LocalProfileImageStrategy: Verified Firestore has profileImageURL: \(savedURL)")
        } else {
            print("❌ LocalProfileImageStrategy: Failed to verify Firestore update")
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
