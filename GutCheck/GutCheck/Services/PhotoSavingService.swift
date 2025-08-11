//
//  PhotoSavingService.swift
//  GutCheck
//
//  Service for saving meal photos with proper permission handling
//

import UIKit
import Photos

@MainActor
class PhotoSavingService: ObservableObject {
    static let shared = PhotoSavingService()
    
    @Published var isSaving = false
    @Published var lastSaveResult: SaveResult?
    
    enum SaveResult {
        case success
        case permissionDenied
        case error(String)
    }
    
    private init() {}
    
    /// Save a meal photo to the user's photo library
    func saveMealPhoto(_ image: UIImage, mealName: String = "Meal") async -> SaveResult {
        let permissionManager = PermissionManager.shared
        
        // Check if we have permission
        if !permissionManager.photoLibraryStatus.isGranted {
            // Request permission if not determined
            if permissionManager.photoLibraryStatus.needsRequest {
                let granted = await permissionManager.requestPhotoLibraryPermission()
                if !granted {
                    await MainActor.run {
                        self.lastSaveResult = .permissionDenied
                    }
                    return .permissionDenied
                }
            } else {
                await MainActor.run {
                    self.lastSaveResult = .permissionDenied
                }
                return .permissionDenied
            }
        }
        
        // Save to photo library
        await MainActor.run {
            self.isSaving = true
        }
        
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: image.jpegData(compressionQuality: 0.8)!, options: nil)
                
                // Add metadata for meal context
                if let _ = request.placeholderForCreatedAsset {
                    // Could add custom metadata here if needed
                }
            }) { [weak self] success, error in
                Task { @MainActor in
                    self?.isSaving = false
                    
                    let result: SaveResult
                    if success {
                        result = .success
                        print("✅ PhotoSavingService: Successfully saved meal photo")
                    } else {
                        let errorMessage = error?.localizedDescription ?? "Unknown error"
                        result = .error(errorMessage)
                        print("❌ PhotoSavingService: Failed to save photo: \(errorMessage)")
                    }
                    
                    self?.lastSaveResult = result
                    continuation.resume(returning: result)
                }
            }
        }
    }
    
    /// Check if photo library access is available
    func canSavePhotos() -> Bool {
        let permissionManager = PermissionManager.shared
        return permissionManager.photoLibraryStatus.isGranted || permissionManager.photoLibraryStatus.needsRequest
    }
    
    /// Present permission request if needed
    func requestPhotoLibraryAccess() async -> Bool {
        let permissionManager = PermissionManager.shared
        return await permissionManager.requestPhotoLibraryPermission()
    }
}

