//
//  UnifiedProfileImageService.swift
//  GutCheck
//
//  Unified profile image service using strategy pattern to handle different storage approaches
//

import UIKit

@MainActor
class UnifiedProfileImageService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private let loadingState = UploadLoadingStateManager()
    
    private var _strategy: ProfileImageStrategy
    
    var strategy: ProfileImageStrategy {
        return _strategy
    }
    
    init(strategy: ProfileImageStrategy) {
        self._strategy = strategy
        
        // Set up delegate if strategy supports it
        if let delegateStrategy = strategy as? LocalProfileImageStrategy {
            delegateStrategy.delegate = self
        }
    }
    
    func setStrategy(_ strategy: ProfileImageStrategy) {
        self._strategy = strategy
    }
    
    func uploadProfileImage(_ image: UIImage, for userId: String) async throws -> String {
        loadingState.startUploading()
        
        defer {
            loadingState.stopUploading()
        }
        
        do {
            let result = try await _strategy.uploadProfileImage(image, for: userId)
            loadingState.setProgress(1.0)
            return result
        } catch {
            loadingState.setError(error.localizedDescription)
            throw error
        }
    }
    
    func downloadProfileImage(from urlString: String) async throws -> UIImage {
        return try await _strategy.downloadProfileImage(from: urlString)
    }
    
    func deleteProfileImage(for userId: String) async throws {
        try await _strategy.deleteProfileImage(for: userId)
    }
}

extension UnifiedProfileImageService: ProfileImageStrategyDelegate {
    func strategyDidUpdateProgress(_ progress: Double) {
        uploadProgress = progress
        loadingState.setProgress(progress)
    }
    
    func strategyDidEncounterError(_ error: String) {
        errorMessage = error
        loadingState.setError(error)
    }
}