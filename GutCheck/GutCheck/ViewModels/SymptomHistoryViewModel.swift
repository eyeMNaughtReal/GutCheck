import SwiftUI

@MainActor
@Observable class SymptomHistoryViewModel {
    var groupedSymptoms: [Date: [Symptom]] = [:]
    var isLoading = false
    var isLoadingMore = false
    var hasMoreData = true
    var error: Error?
    var startDate = Date.distantPast
    var endDate = Date.now
    var selectedFilter: SymptomFilter = .all

    private let symptomRepository: any SymptomRepositoryProtocol

    /// How many records have been read so far. Replaces the Firestore cursor
    /// the previous implementation carried between pages.
    private var loadedCount = 0
    private let pageSize = 20

    init(symptomRepository: any SymptomRepositoryProtocol = SymptomRepository.shared) {
        self.symptomRepository = symptomRepository
    }

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
            let page = try await SymptomRepository.shared.fetchSymptomsPage(
                userId: LocalUserService.currentProfileId,
                offset: 0,
                limit: pageSize
            )

            loadedCount = page.count
            // A short page means the store is exhausted. This is measured
            // against the raw page, not the filtered result, so a page where
            // everything is filtered out still advances rather than stopping.
            hasMoreData = page.count == pageSize
            groupedSymptoms = Self.grouped(Self.applying(filter, to: page))
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func loadMoreSymptoms() async {
        guard !isLoadingMore && hasMoreData && !isLoading else { return }

        isLoadingMore = true

        do {
            let page = try await SymptomRepository.shared.fetchSymptomsPage(
                userId: LocalUserService.currentProfileId,
                offset: loadedCount,
                limit: pageSize
            )

            loadedCount += page.count
            hasMoreData = page.count == pageSize

            for (date, symptoms) in Self.grouped(Self.applying(selectedFilter, to: page)) {
                groupedSymptoms[date, default: []].append(contentsOf: symptoms)
            }
        } catch {
            self.error = error
        }

        isLoadingMore = false
    }

    func refreshSymptoms(filter: SymptomFilter = .all) async {
        loadedCount = 0
        hasMoreData = true
        groupedSymptoms.removeAll()
        await loadSymptoms(filter: filter)
    }

    func deleteSymptom(_ symptom: Symptom) async {
        do {
            try await symptomRepository.delete(id: symptom.id)
            SpotlightIndexingService.shared.removeSymptom(id: symptom.id)

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

    func updateSymptom(_ updatedSymptom: Symptom) async {
        do {
            try await symptomRepository.save(updatedSymptom)
            SpotlightIndexingService.shared.indexSymptom(updatedSymptom)

            // Trigger dashboard refresh after successful update
            DataSyncManager.shared.triggerRefreshAfterSave(operation: "Symptom update", dataType: .symptoms)

            // Update in grouped symptoms
            for (date, symptoms) in groupedSymptoms {
                if let index = symptoms.firstIndex(where: { $0.id == updatedSymptom.id }) {
                    groupedSymptoms[date]?[index] = updatedSymptom
                    // If the date changed, we need to move the symptom to the correct group
                    let newDate = Calendar.current.startOfDay(for: updatedSymptom.date)
                    if date != newDate {
                        // Remove from old date
                        groupedSymptoms[date]?.remove(at: index)
                        if groupedSymptoms[date]?.isEmpty == true {
                            groupedSymptoms.removeValue(forKey: date)
                        }
                        // Add to new date
                        groupedSymptoms[newDate, default: []].append(updatedSymptom)
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

    // MARK: - Helpers

    private static func grouped(_ symptoms: [Symptom]) -> [Date: [Symptom]] {
        Dictionary(grouping: symptoms) { Calendar.current.startOfDay(for: $0.date) }
    }

    /// Applies the selected filter in memory.
    ///
    /// This used to be pushed down as a Firestore `where type == …` clause,
    /// which silently matched nothing: `Symptom` has no `type` field, so every
    /// filter but `.all` returned an empty history. The severity fields below
    /// are what the filter names actually refer to.
    private static func applying(_ filter: SymptomFilter, to symptoms: [Symptom]) -> [Symptom] {
        switch filter {
        case .all:
            return symptoms
        case .pain:
            return symptoms.filter { $0.painLevel != .none }
        case .urgency:
            return symptoms.filter { $0.urgencyLevel != .none }
        case .stool:
            // Anything outside the two "normal" Bristol types.
            return symptoms.filter { $0.stoolType != .type3 && $0.stoolType != .type4 }
        case .bloating, .nausea:
            // Not modelled as their own fields — surfaced through tags.
            return symptoms.filter { $0.tags.contains(filter.rawValue) }
        }
    }
}
