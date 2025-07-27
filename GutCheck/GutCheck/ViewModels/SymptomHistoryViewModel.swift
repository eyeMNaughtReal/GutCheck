import SwiftUI
import FirebaseFirestore

@MainActor
class SymptomHistoryViewModel: ObservableObject {
    @Published var groupedSymptoms: [Date: [Symptom]] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    @Published var startDate = Date.distantPast
    @Published var endDate = Date.now
    
    private let db = Firestore.firestore()
    
    func loadSymptoms(filter: SymptomFilter) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            var query = db.collection("symptoms")
                .order(by: "date", descending: true)
            
            // Apply filter
            if filter != .all {
                query = query.whereField("type", isEqualTo: filter.rawValue)
            }
            
            let querySnapshot = try await query.getDocuments()
            let symptoms = querySnapshot.documents.compactMap { document in
                try? document.data(as: Symptom.self)
            }
            
            // Group by date
            groupedSymptoms = Dictionary(grouping: symptoms) { symptom in
                symptom.date.startOfDay()
            }
        } catch {
            self.error = error
        }
    }
    
    func deleteSymptom(_ symptom: Symptom) async {
        do {
            let id = symptom.id
            try await db.collection("symptoms").document(id).delete()
            // Remove from grouped symptoms
            for (date, symptoms) in groupedSymptoms {
                if let index = symptoms.firstIndex(where: { $0.id == id }) {
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
    
    func exportSymptoms() {
        // TODO: Implement CSV export functionality
    }
}

