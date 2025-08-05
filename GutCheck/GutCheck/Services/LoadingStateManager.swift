//
//  LoadingStateManager.swift
//  GutCheck
//
//  Centralized loading state management to eliminate duplicate @Published properties
//

import SwiftUI
import Combine

// MARK: - LoadingState Protocol
@MainActor
protocol LoadingStateManaging: ObservableObject {
    var isLoading: Bool { get set }
    var isSaving: Bool { get set }
    var isLoadingMore: Bool { get set }
    var uploadProgress: Double { get set }
    var errorMessage: String? { get set }
    
    func startLoading()
    func stopLoading()
    func startSaving()
    func stopSaving()
    func startLoadingMore()
    func stopLoadingMore()
    func setProgress(_ progress: Double)
    func setError(_ message: String?)
    func clearError()
    func reset()
}

// MARK: - Default Implementations
extension LoadingStateManaging {
    func startLoading() {
        isLoading = true
        clearError()
    }
    
    func stopLoading() {
        isLoading = false
    }
    
    func startSaving() {
        isSaving = true
        clearError()
    }
    
    func stopSaving() {
        isSaving = false
    }
    
    func startLoadingMore() {
        isLoadingMore = true
        clearError()
    }
    
    func stopLoadingMore() {
        isLoadingMore = false
    }
    
    func setProgress(_ progress: Double) {
        uploadProgress = progress
    }
    
    func setError(_ message: String?) {
        errorMessage = message
        stopLoading()
        stopSaving()
        stopLoadingMore()
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func reset() {
        isLoading = false
        isSaving = false
        isLoadingMore = false
        uploadProgress = 0.0
        errorMessage = nil
    }
}

// MARK: - Concrete Implementation
@MainActor
class LoadingStateManager: ObservableObject, LoadingStateManaging {
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String? = nil
    
    nonisolated init() {}
}

// MARK: - Specialized Loading States
@MainActor
class UploadLoadingStateManager: LoadingStateManager {
    @Published var isUploading: Bool = false
    
    override nonisolated init() {
        super.init()
    }
    
    func startUploading() {
        isUploading = true
        clearError()
    }
    
    func stopUploading() {
        isUploading = false
        uploadProgress = 0.0
    }
    
    func resetUpload() {
        reset()
        isUploading = false
    }
}

// MARK: - Loading State Mixins
protocol HasLoadingState {
    var loadingState: LoadingStateManager { get }
}

@MainActor
extension HasLoadingState where Self: ObservableObject {
    var isLoading: Bool {
        get { loadingState.isLoading }
        set { loadingState.isLoading = newValue }
    }
    
    var isSaving: Bool {
        get { loadingState.isSaving }
        set { loadingState.isSaving = newValue }
    }
    
    var errorMessage: String? {
        get { loadingState.errorMessage }
        set { loadingState.errorMessage = newValue }
    }
}