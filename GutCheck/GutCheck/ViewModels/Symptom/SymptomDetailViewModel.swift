import Foundation

@MainActor
class SymptomDetailViewModel: ObservableObject {
    @Published var error: Error?
    
    func updateSymptom(_ updatedSymptom: Symptom) async {
        do {
            try await SymptomRepository.shared.save(updatedSymptom)
        } catch {
            self.error = error
        }
    }
    
    func deleteSymptom(_ symptom: Symptom) async {
        do {
            try await SymptomRepository.shared.delete(id: symptom.id)
        } catch {
            self.error = error
        }
    }
}
