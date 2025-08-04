//
//  PaginationService.swift
//  GutCheck
//
//  Generic pagination service for handling paginated data loading
//

import Foundation
import FirebaseFirestore
import Combine

// MARK: - Pagination Models

struct PaginationState {
    let isLoading: Bool
    let hasMoreData: Bool
    let currentPage: Int
    let totalItems: Int?
    let error: Error?
    
    static let initial = PaginationState(
        isLoading: false,
        hasMoreData: true,
        currentPage: 0,
        totalItems: nil,
        error: nil
    )
}

struct PaginationConfig {
    let pageSize: Int
    let sortField: String
    let sortDescending: Bool
    
    static let `default` = PaginationConfig(
        pageSize: 20,
        sortField: "date",
        sortDescending: true
    )
}

// MARK: - Paginated Result

struct PaginatedResult<T> {
    let items: [T]
    let hasMoreData: Bool
    let lastDocument: DocumentSnapshot?
    let totalCount: Int?
}

// MARK: - Pagination Service

@MainActor
class PaginationService<T: Codable & Identifiable>: ObservableObject {
    @Published var items: [T] = []
    @Published var paginationState = PaginationState.initial
    
    internal let collection: String
    internal let config: PaginationConfig
    private var lastDocument: DocumentSnapshot?
    private var cancellables = Set<AnyCancellable>()
    
    init(collection: String, config: PaginationConfig = .default) {
        self.collection = collection
        self.config = config
    }
    
    // MARK: - Public Methods
    
    func loadFirstPage(
        userId: String,
        additionalFilters: [String: Any] = [:]
    ) async {
        guard !paginationState.isLoading else { return }
        
        await updatePaginationState { state in
            PaginationState(
                isLoading: true,
                hasMoreData: state.hasMoreData,
                currentPage: 0,
                totalItems: state.totalItems,
                error: nil
            )
        }
        
        do {
            let result = try await fetchPage(
                userId: userId,
                lastDocument: nil,
                additionalFilters: additionalFilters
            )
            
            await MainActor.run {
                self.items = result.items
                self.lastDocument = result.lastDocument
                self.updatePaginationState { _ in
                    PaginationState(
                        isLoading: false,
                        hasMoreData: result.hasMoreData,
                        currentPage: 1,
                        totalItems: result.totalCount,
                        error: nil
                    )
                }
            }
        } catch {
            await handleError(error)
        }
    }
    
    func loadNextPage(
        userId: String,
        additionalFilters: [String: Any] = [:]
    ) async {
        guard !paginationState.isLoading && paginationState.hasMoreData else { return }
        
        await updatePaginationState { state in
            PaginationState(
                isLoading: true,
                hasMoreData: state.hasMoreData,
                currentPage: state.currentPage,
                totalItems: state.totalItems,
                error: nil
            )
        }
        
        do {
            let result = try await fetchPage(
                userId: userId,
                lastDocument: lastDocument,
                additionalFilters: additionalFilters
            )
            
            await MainActor.run {
                self.items.append(contentsOf: result.items)
                self.lastDocument = result.lastDocument
                self.updatePaginationState { state in
                    PaginationState(
                        isLoading: false,
                        hasMoreData: result.hasMoreData,
                        currentPage: state.currentPage + 1,
                        totalItems: result.totalCount,
                        error: nil
                    )
                }
            }
        } catch {
            await handleError(error)
        }
    }
    
    func refresh(
        userId: String,
        additionalFilters: [String: Any] = [:]
    ) async {
        lastDocument = nil
        await loadFirstPage(userId: userId, additionalFilters: additionalFilters)
    }
    
    func addItem(_ item: T) {
        items.insert(item, at: 0)
    }
    
    func updateItem(_ item: T) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }
    
    func removeItem(withId id: T.ID) {
        items.removeAll { $0.id == id }
    }
    
    func clear() {
        items.removeAll()
        lastDocument = nil
        paginationState = .initial
    }
    
    // MARK: - Internal Methods
    
    internal func fetchPage(
        userId: String,
        lastDocument: DocumentSnapshot?,
        additionalFilters: [String: Any]
    ) async throws -> PaginatedResult<T> {
        let db = Firestore.firestore()
        var query = db.collection(collection)
            .whereField("userId", isEqualTo: userId)
        
        // Apply additional filters
        for (field, value) in additionalFilters {
            query = query.whereField(field, isEqualTo: value)
        }
        
        // Apply sorting
        query = query.order(by: config.sortField, descending: config.sortDescending)
        
        // Apply pagination
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query = query.limit(to: config.pageSize)
        
        let snapshot = try await query.getDocuments()
        let documents = snapshot.documents
        
        let items = try documents.compactMap { document in
            try document.data(as: T.self)
        }
        
        let hasMoreData = documents.count == config.pageSize
        let lastDoc = documents.last
        
        return PaginatedResult(
            items: items,
            hasMoreData: hasMoreData,
            lastDocument: lastDoc,
            totalCount: nil // We could implement count queries separately if needed
        )
    }
    
    private func updatePaginationState(_ update: (PaginationState) -> PaginationState) {
        paginationState = update(paginationState)
    }
    
    private func handleError(_ error: Error) async {
        await updatePaginationState { state in
            PaginationState(
                isLoading: false,
                hasMoreData: state.hasMoreData,
                currentPage: state.currentPage,
                totalItems: state.totalItems,
                error: error
            )
        }
    }
}

// MARK: - Date Filterable Protocol

protocol DateFilterable {
    var date: Date { get }
}

// Make your models conform to DateFilterable
extension Meal: DateFilterable {}
extension Symptom: DateFilterable {}