//
//  BaseViewModel.swift
//  GutCheck
//
//  Base ViewModel class to consolidate common patterns across all ViewModels
//

import Foundation
import SwiftUI

// MARK: - Base ViewModel Class

@MainActor
open class BaseViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingErrorAlert: Bool = false
    @Published var shouldDismiss: Bool = false
    
    public init() {}
    
    // MARK: - Common Operations
    
    /// Execute operation with loading state management
    func executeWithLoading<T>(
        _ operation: @escaping () async throws -> T,
        onSuccess: ((T) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await operation()
            onSuccess?(result)
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
            onError?(error)
        }
        isLoading = false
    }
    
    /// Execute save operation with saving state management
    func executeWithSaving<T>(
        _ operation: @escaping () async throws -> T,
        onSuccess: ((T) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) async {
        isSaving = true
        errorMessage = nil
        do {
            let result = try await operation()
            onSuccess?(result)
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
            onError?(error)
        }
        isSaving = false
    }
    
    /// Handle errors consistently
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingErrorAlert = true
        print("❌ Error in \(String(describing: type(of: self))): \(error)")
    }
    
    /// Handle success consistently
    func handleSuccess(message: String? = nil) {
        errorMessage = nil
        if let message = message {
            print("✅ Success in \(String(describing: type(of: self))): \(message)")
        }
    }
    
    /// Reset all state
    func resetState() {
        isLoading = false
        isSaving = false
        errorMessage = nil
        showingErrorAlert = false
        shouldDismiss = false
    }
}

// MARK: - Specialized Base ViewModels

/// Base ViewModel for detail views (editing single entities)
@MainActor
open class DetailViewModel<T>: BaseViewModel {
    @Published var isEditing = false
    @Published var showingDeleteConfirmation = false
    
    /// The entity being viewed/edited
    @Published var entity: T
    
    public init(entity: T) {
        self.entity = entity
        super.init()
    }
    
    /// Override this to implement loading by ID
    open func loadEntity() async {
        // Override in subclasses
    }
    
    /// Override this to implement saving
    open func saveEntity() async {
        // Override in subclasses
    }
    
    /// Override this to implement deletion
    open func deleteEntity() async {
        // Override in subclasses
    }
    
    /// Toggle editing mode
    func toggleEditing() {
        isEditing.toggle()
        if !isEditing {
            // Cancel editing - you might want to reload entity
            resetState()
        }
    }
    
    /// Confirm deletion
    func confirmDelete() {
        showingDeleteConfirmation = true
    }
    
    func resetDetailState() {
        isEditing = false
        showingDeleteConfirmation = false
    }
    
    override func resetState() {
        super.resetState()
        resetDetailState()
    }
}

/// Base ViewModel for list views (displaying collections)
@MainActor
open class ListViewModel<T>: BaseViewModel {
    @Published var items: [T] = []
    @Published var hasMoreData: Bool = false
    
    /// Override this to implement data loading
    open func loadItems() async {
        // Override in subclasses
    }
    
    /// Override this to implement pagination
    open func loadMoreItems() async {
        // Override in subclasses
    }
    
    /// Refresh data
    func refresh() async {
        items.removeAll()
        await loadItems()
    }
    
    override func resetState() {
        super.resetState()
        items.removeAll()
        hasMoreData = false
    }
}

/// Base ViewModel for form views (creating new entities)
@MainActor
open class FormViewModel<T>: BaseViewModel {
    /// Override this to implement form validation
    open var isFormValid: Bool {
        return true // Override in subclasses
    }
    
    /// Override this to implement form submission
    open func submitForm() async {
        // Override in subclasses
    }
    
    /// Override this to implement form reset
    open func resetForm() {
        // Override in subclasses
        resetState()
    }
}

