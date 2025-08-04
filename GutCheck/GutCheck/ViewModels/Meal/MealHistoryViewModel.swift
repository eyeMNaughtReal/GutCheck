//
//  MealHistoryViewModel.swift
//  GutCheck
//
//  Paginated meal history view model
//

import SwiftUI
import FirebaseFirestore

enum MealFilter: String, CaseIterable {
    case all = "all"
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch" 
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }
}

@MainActor
class MealHistoryViewModel: ObservableObject {
    @Published var groupedMeals: [Date: [Meal]] = [:]
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMoreData = true
    @Published var error: Error?
    @Published var selectedFilter: MealFilter = .all
    @Published var startDate: Date?
    @Published var endDate: Date?
    
    private let firebaseManager = FirebaseManager.shared
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20
    
    func loadMeals(filter: MealFilter = .all, refresh: Bool = false) async {
        if refresh {
            await refreshMeals(filter: filter)
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
            
            let result: (items: [Meal], lastDocument: DocumentSnapshot?, hasMore: Bool)
            
            if let startDate = startDate, let endDate = endDate {
                result = try await firebaseManager.getPaginatedDocumentsWithDateRange(
                    from: "meals",
                    pageSize: pageSize,
                    lastDocument: nil,
                    sortField: "date",
                    sortDescending: true,
                    startDate: startDate,
                    endDate: endDate,
                    additionalFilters: additionalFilters
                )
            } else {
                result = try await firebaseManager.getPaginatedDocuments(
                    from: "meals",
                    pageSize: pageSize,
                    lastDocument: nil,
                    sortField: "date",
                    sortDescending: true,
                    additionalFilters: additionalFilters
                )
            }
            
            self.lastDocument = result.lastDocument
            self.hasMoreData = result.hasMore
            
            // Group by date
            self.groupedMeals = Dictionary(grouping: result.items) { meal in
                Calendar.current.startOfDay(for: meal.date)
            }
            
        } catch {
            self.error = error
        }
        
        self.isLoading = false
    }
    
    func loadMoreMeals() async {
        guard !isLoadingMore && hasMoreData && !isLoading else { return }
        
        isLoadingMore = true
        
        do {
            var additionalFilters: [String: Any] = [:]
            if selectedFilter != .all {
                additionalFilters["type"] = selectedFilter.rawValue
            }
            
            let result: (items: [Meal], lastDocument: DocumentSnapshot?, hasMore: Bool)
            
            if let startDate = startDate, let endDate = endDate {
                result = try await firebaseManager.getPaginatedDocumentsWithDateRange(
                    from: "meals",
                    pageSize: pageSize,
                    lastDocument: lastDocument,
                    sortField: "date",
                    sortDescending: true,
                    startDate: startDate,
                    endDate: endDate,
                    additionalFilters: additionalFilters
                )
            } else {
                result = try await firebaseManager.getPaginatedDocuments(
                    from: "meals",
                    pageSize: pageSize,
                    lastDocument: lastDocument,
                    sortField: "date",
                    sortDescending: true,
                    additionalFilters: additionalFilters
                )
            }
            
            self.lastDocument = result.lastDocument
            self.hasMoreData = result.hasMore
            
            // Merge new items with existing grouped meals
            let newGroupedMeals = Dictionary(grouping: result.items) { meal in
                Calendar.current.startOfDay(for: meal.date)
            }
            
            for (date, meals) in newGroupedMeals {
                if groupedMeals[date] != nil {
                    groupedMeals[date]?.append(contentsOf: meals)
                } else {
                    groupedMeals[date] = meals
                }
            }
            
        } catch {
            self.error = error
        }
        
        self.isLoadingMore = false
    }
    
    func refreshMeals(filter: MealFilter = .all) async {
        lastDocument = nil
        hasMoreData = true
        groupedMeals.removeAll()
        await loadMeals(filter: filter)
    }
    
    func setDateRange(start: Date?, end: Date?) {
        startDate = start
        endDate = end
    }
    
    func clearDateRange() {
        startDate = nil
        endDate = nil
    }
    
    func deleteMeal(_ meal: Meal) async {
        do {
            try await firebaseManager.deleteDocument(from: "meals", documentId: meal.id)
            
            // Remove from grouped meals
            for (date, meals) in groupedMeals {
                if let index = meals.firstIndex(where: { $0.id == meal.id }) {
                    groupedMeals[date]?.remove(at: index)
                    if groupedMeals[date]?.isEmpty == true {
                        groupedMeals.removeValue(forKey: date)
                    }
                    break
                }
            }
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Analytics Support
    
    var totalMealsCount: Int {
        groupedMeals.values.reduce(0) { $0 + $1.count }
    }
    
    var dateRange: String {
        let dates = groupedMeals.keys.sorted()
        guard let firstDate = dates.first, let lastDate = dates.last else {
            return "No data"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if Calendar.current.isDate(firstDate, inSameDayAs: lastDate) {
            return formatter.string(from: firstDate)
        } else {
            return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
        }
    }
    
    func getMealsByType() -> [MealFilter: Int] {
        var counts: [MealFilter: Int] = [:]
        
        for meals in groupedMeals.values {
            for meal in meals {
                if let mealType = MealFilter(rawValue: meal.type.rawValue) {
                    counts[mealType, default: 0] += 1
                }
            }
        }
        
        return counts
    }
}

