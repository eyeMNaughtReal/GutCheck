//
//  DataSyncManager.swift
//  GutCheck
//
//  Centralized data synchronization and refresh management
//

import Foundation
import SwiftUI

class DataSyncManager: ObservableObject {
    static let shared = DataSyncManager()
    
    @Published private(set) var lastRefreshTime: Date = Date()
    @Published private(set) var isRefreshing: Bool = false
    
    // Refresh triggers for different data types
    @Published var shouldRefreshDashboard: Bool = false
    @Published var shouldRefreshMeals: Bool = false
    @Published var shouldRefreshSymptoms: Bool = false
    @Published var shouldRefreshCalendar: Bool = false
    
    private init() {}
    
    // MARK: - Main Refresh Methods
    
    /// Trigger a dashboard refresh after data changes
    @MainActor
    func triggerRefresh() {
        print("🔄 DataSyncManager: Triggering dashboard refresh")
        updateRefreshStates()
    }
    
    /// Trigger a specific data type refresh
    @MainActor
    func triggerRefresh(for dataType: DataType) {
        print("🔄 DataSyncManager: Triggering \(dataType.rawValue) refresh")
        
        switch dataType {
        case .dashboard:
            updateRefreshStates()
        case .meals:
            shouldRefreshMeals.toggle()
            updateRefreshStates()
        case .symptoms:
            shouldRefreshSymptoms.toggle()
            updateRefreshStates()
        case .calendar:
            shouldRefreshCalendar.toggle()
            updateRefreshStates()
        case .all:
            updateAllRefreshStates()
        }
    }
    
    /// Trigger refresh after successful save operation
    func triggerRefreshAfterSave(operation: String, dataType: DataType = .dashboard) {
        print("✅ DataSyncManager: \(operation) successful, triggering \(dataType.rawValue) refresh")
        Task { @MainActor in
            triggerRefresh(for: dataType)
        }
    }
    
    /// Trigger refresh with delay (useful for UI transitions)
    func triggerRefreshWithDelay(seconds: Double = 0.5, dataType: DataType = .dashboard) {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            await MainActor.run {
                triggerRefresh(for: dataType)
            }
        }
    }
    
    // MARK: - Batch Operations
    
    /// Start a batch operation that will trigger refresh when completed
    @MainActor
    func startBatchOperation() {
        isRefreshing = true
        print("🔄 DataSyncManager: Starting batch operation")
    }
    
    /// Complete a batch operation and trigger refresh
    @MainActor
    func completeBatchOperation(dataType: DataType = .all) {
        defer { isRefreshing = false }
        print("✅ DataSyncManager: Completing batch operation")
        triggerRefresh(for: dataType)
    }
    
    // MARK: - Private Helpers
    
    @MainActor
    private func updateRefreshStates() {
        shouldRefreshDashboard.toggle()
        lastRefreshTime = Date()
    }
    
    @MainActor
    private func updateAllRefreshStates() {
        shouldRefreshDashboard.toggle()
        shouldRefreshMeals.toggle()
        shouldRefreshSymptoms.toggle()
        shouldRefreshCalendar.toggle()
        lastRefreshTime = Date()
    }
    
    // MARK: - Reset Methods
    
    /// Reset all refresh states (useful for testing or state cleanup)
    @MainActor
    func resetRefreshStates() {
        shouldRefreshDashboard = false
        shouldRefreshMeals = false
        shouldRefreshSymptoms = false
        shouldRefreshCalendar = false
        isRefreshing = false
        print("🔄 DataSyncManager: Reset all refresh states")
    }
    
    // MARK: - Computed Properties
    
    var formattedLastRefreshTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: lastRefreshTime)
    }
    
    var timeSinceLastRefresh: TimeInterval {
        Date().timeIntervalSince(lastRefreshTime)
    }
}

// MARK: - Data Types

extension DataSyncManager {
    enum DataType: String, CaseIterable {
        case dashboard = "dashboard"
        case meals = "meals"
        case symptoms = "symptoms"
        case calendar = "calendar"
        case all = "all"
        
        var displayName: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .meals: return "Meals"
            case .symptoms: return "Symptoms"
            case .calendar: return "Calendar"
            case .all: return "All Data"
            }
        }
    }
}

// MARK: - Convenience Extensions

extension DataSyncManager {
    /// Convenience method for meal-related operations
    func triggerMealRefresh() {
        Task { @MainActor in
            triggerRefresh(for: .meals)
        }
    }
    
    /// Convenience method for symptom-related operations
    func triggerSymptomRefresh() {
        Task { @MainActor in
            triggerRefresh(for: .symptoms)
        }
    }
    
    /// Convenience method for calendar-related operations
    func triggerCalendarRefresh() {
        Task { @MainActor in
            triggerRefresh(for: .calendar)
        }
    }
}

// MARK: - Protocol for ViewModels

protocol DataSyncCapable {
    func triggerDataRefresh()
}

extension DataSyncCapable {
    func triggerDataRefresh() {
        Task { @MainActor in
            DataSyncManager.shared.triggerRefresh()
        }
    }
}
