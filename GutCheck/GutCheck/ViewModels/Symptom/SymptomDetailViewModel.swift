import Foundation

@MainActor
class SymptomDetailViewModel: DetailViewModel<Symptom> {
    @Published var symptomId: String?
    
    private let repository: SymptomRepository
    
    // Initialize with a Symptom object
    init(entity: Symptom, repository: SymptomRepository = SymptomRepository.shared) {
        self.symptomId = entity.id
        self.repository = repository
        super.init(entity: entity)
    }
    
    // Initialize with a symptom ID
    init(symptomId: String, repository: SymptomRepository = SymptomRepository.shared) {
        self.symptomId = symptomId
        self.repository = repository
        super.init(entity: Symptom.emptySymptom())
        
        // Load the symptom when initialized with ID
        Task {
            await loadEntity()
        }
    }
    
    // MARK: - Entity Loading
    
    override func loadEntity() async {
        guard let symptomId = symptomId else { return }
        
        await executeWithLoading {
            let symptom = try await self.repository.fetch(id: symptomId)
            if let symptom = symptom {
                self.entity = symptom
            }
        }
    }
    
    // MARK: - Entity Operations
    
    /// Save changes
    func saveSymptom() async -> Bool {
        await executeWithSaving {
            try await self.repository.save(self.entity)
        } onSuccess: { _ in
            self.isEditing = false
        } onError: { _ in
            // Error already handled by base class
        }
        
        return errorMessage == nil
    }
    
    /// Delete symptom
    func deleteSymptom() async -> Bool {
        await executeWithLoading {
            try await self.repository.delete(id: self.entity.id)
        } onSuccess: { _ in
            self.shouldDismiss = true
        }
        
        return errorMessage == nil
    }
    
    // MARK: - Helper Methods
    
    /// Update symptom data
    func updateSymptom(_ symptom: Symptom) {
        self.entity = symptom
    }
    
    /// Check if symptom has been modified
    var hasChanges: Bool {
        // Compare with original symptom if needed
        return true // For now, assume always has changes
    }
    
    /// Reset to original state
    func resetToOriginal() {
        // Reload the original symptom
        Task {
            await loadEntity()
        }
    }
}

// MARK: - Error Types

enum SymptomError: LocalizedError {
    case notFound
    case invalidData
    case saveFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Could not find the symptom"
        case .invalidData:
            return "Invalid symptom data"
        case .saveFailed:
            return "Failed to save symptom"
        case .deleteFailed:
            return "Failed to delete symptom"
        }
    }
}

// MARK: - Extensions

// Extension on Symptom to provide an empty symptom for initialization
extension Symptom {
    static func emptySymptom() -> Symptom {
        return Symptom(
            id: "",
            date: Date(),
            stoolType: .type4,
            painLevel: .none,
            urgencyLevel: .none,
            notes: nil,
            tags: [],
            createdBy: ""
        )
    }
}