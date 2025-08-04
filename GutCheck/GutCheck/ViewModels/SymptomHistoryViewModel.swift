import SwiftUI
import FirebaseFirestore

@MainActor
class SymptomHistoryViewModel: ObservableObject {
    @Published var groupedSymptoms: [Date: [Symptom]] = [:]
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMoreData = true
    @Published var error: Error?
    @Published var startDate = Date.distantPast
    @Published var endDate = Date.now
    @Published var selectedFilter: SymptomFilter = .all
    
    private let firebaseManager = FirebaseManager.shared
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20
    
    func loadSymptoms(filter: SymptomFilter = .all, refresh: Bool = false) async {
        if refresh {
            await refreshSymptoms(filter: filter)
            return
        }
        
        guard !isLoading else { return }
        
        isLoading = true
        selectedFilter = filter
        error = nil
        
        do {
            var additionalFilters: [String: Any] = [:]
            if filter != .all {
                additionalFilters["type"] = filter.rawValue
            }
            
            let result: (items: [Symptom], lastDocument: DocumentSnapshot?, hasMore: Bool) = try await firebaseManager.getPaginatedDocuments(
                from: "symptoms",
                pageSize: pageSize,
                lastDocument: nil,
                sortField: "date",
                sortDescending: true,
                additionalFilters: additionalFilters
            )
            
            self.lastDocument = result.lastDocument
            self.hasMoreData = result.hasMore
            
            // Group by date
            self.groupedSymptoms = Dictionary(grouping: result.items) { symptom in
                Calendar.current.startOfDay(for: symptom.date)
            }
            
        } catch {
            self.error = error
        }
        
        self.isLoading = false
    }
    
    func loadMoreSymptoms() async {
        guard !isLoadingMore && hasMoreData && !isLoading else { return }
        
        isLoadingMore = true
        
        do {
            var additionalFilters: [String: Any] = [:]
            if selectedFilter != .all {
                additionalFilters["type"] = selectedFilter.rawValue
            }
            
            let result: (items: [Symptom], lastDocument: DocumentSnapshot?, hasMore: Bool) = try await firebaseManager.getPaginatedDocuments(
                from: "symptoms",
                pageSize: pageSize,
                lastDocument: lastDocument,
                sortField: "date",
                sortDescending: true,
                additionalFilters: additionalFilters
            )
            
            self.lastDocument = result.lastDocument
            self.hasMoreData = result.hasMore
            
            // Merge new items with existing grouped symptoms
            let newGroupedSymptoms = Dictionary(grouping: result.items) { symptom in
                Calendar.current.startOfDay(for: symptom.date)
            }
            
            for (date, symptoms) in newGroupedSymptoms {
                if groupedSymptoms[date] != nil {
                    groupedSymptoms[date]?.append(contentsOf: symptoms)
                } else {
                    groupedSymptoms[date] = symptoms
                }
            }
            
        } catch {
            self.error = error
        }
        
        self.isLoadingMore = false
    }
    
    func refreshSymptoms(filter: SymptomFilter = .all) async {
        lastDocument = nil
        hasMoreData = true
        groupedSymptoms.removeAll()
        await loadSymptoms(filter: filter)
    }
    
    func deleteSymptom(_ symptom: Symptom) async {
        do {
            try await firebaseManager.deleteDocument(from: "symptoms", documentId: symptom.id)
            
            // Remove from grouped symptoms
            for (date, symptoms) in groupedSymptoms {
                if let index = symptoms.firstIndex(where: { $0.id == symptom.id }) {
                    groupedSymptoms[date]?.remove(at: index)
                    if groupedSymptoms[date]?.isEmpty == true {
                        groupedSymptoms.removeValue(forKey: date)
                    }
                    break
                }
            }
        } catch {
            self.error = error
        }
    }
    
    func exportSymptoms() async {
        // TODO: Implement CSV export functionality
        // This will be an async operation that:
        // 1. Fetches all symptoms
        // 2. Formats them as CSV
        // 3. Creates a temporary file
        // 4. Shows share sheet
    }
}

