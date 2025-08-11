//
//  HealthKitMedicationService.swift
//  GutCheck
//
//  Service for real-time medication tracking via HealthKit integration.
//  Features include:
//  - Real-time medication detection using HKObserverQuery
//  - Background delivery for continuous monitoring
//  - Privacy-compliant local data processing
//  - Automatic medication-symptom correlation tracking
//
//  Created by Mark Conley on 12/15/25.
//

import Foundation
import HealthKit
import Combine
import UIKit

/// Main service for HealthKit medication integration
/// Provides real-time medication tracking without requiring daily polling.
/// All medication data is processed locally for privacy compliance.
@MainActor
class HealthKitMedicationService: ObservableObject {
    // MARK: - Private Properties
    
    /// HealthKit store for accessing health data
    private let healthStore = HKHealthStore()
    
    /// Active medication observers for real-time updates
    private var medicationObservers: [HKObserverQuery] = []
    
    /// Background delivery observers for continuous monitoring
    private var backgroundDeliveryObservers: [HKObserverQuery] = []
    
    // MARK: - Published Properties
    
    /// Currently active medications from HealthKit
    @Published var currentMedications: [MedicationRecord] = []
    
    /// Complete medication history for analysis
    @Published var medicationHistory: [MedicationRecord] = []
    
    /// Whether HealthKit medication access is authorized
    @Published var isAuthorized = false
    
    /// Timestamp of last medication data update
    @Published var lastUpdateTime: Date?
    
    // MARK: - Authorization
    
    /// Request permission to access medication data from HealthKit
    /// Uses clinical types for medication records as per HealthKit guidelines
    /// - Returns: True if authorization granted, false otherwise
    func requestMedicationAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return false
        }
        
        // Use clinical types for medication data - this is the correct approach
        // for medication records in HealthKit
        let medicationType = HKObjectType.clinicalType(forIdentifier: .medicationRecord)!
        let medicationTypes: Set<HKSampleType> = [medicationType]
        
        do {
            try await healthStore.requestAuthorization(toShare: medicationTypes, read: medicationTypes)
            isAuthorized = true
            await startObservingMedications()
            return true
        } catch {
            print("Failed to request medication authorization: \(error)")
            return false
        }
    }
    
    // MARK: - Real-time Observation
    
    /// Start real-time observation of medication changes
    /// This method sets up observers that automatically detect when medications
    /// are added, modified, or removed in HealthKit without requiring polling.
    func startObservingMedications() async {
        guard isAuthorized else { return }
        
        // Stop existing observers to prevent duplicates
        stopObservingMedications()
        
        // Start real-time observation for medication changes
        await observeMedicationChanges()
        
        // Enable background delivery for medication updates
        await enableBackgroundDelivery()
    }
    
    /// Set up real-time medication change detection
    /// Uses HKObserverQuery to monitor medication record changes and automatically
    /// fetches updated data when changes are detected.
    private func observeMedicationChanges() async {
        let medicationType = HKObjectType.clinicalType(forIdentifier: .medicationRecord)!
        
        // Create observer query that triggers on any medication record change
        let query = HKObserverQuery(sampleType: medicationType, predicate: nil) { [weak self] _, completion, error in
            if let error = error {
                print("Medication observer error: \(error)")
                completion()
                return
            }
            
            // When medication changes are detected, fetch the latest data
            Task { @MainActor in
                await self?.fetchLatestMedications()
                completion()
            }
        }
        
        medicationObservers.append(query)
        healthStore.execute(query)
        
        // Also observe when the app becomes active to catch any missed updates
        // This ensures we don't miss medication changes that occurred while the app was backgrounded
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchLatestMedications()
            }
        }
    }
    
    /// Enable background delivery for medication updates
    /// This allows the app to receive medication change notifications even when
    /// it's not actively running, ensuring continuous monitoring.
    private func enableBackgroundDelivery() async {
        let medicationType = HKObjectType.clinicalType(forIdentifier: .medicationRecord)!
        
        do {
            try await healthStore.enableBackgroundDelivery(for: medicationType, frequency: .immediate)
            print("Enabled background delivery for medication records")
        } catch {
            print("Failed to enable background delivery for medication records: \(error)")
        }
    }
    
    /// Stop all medication observers and clean up resources
    /// This method is called when the service is deallocated or when stopping observation
    func stopObservingMedications() {
        medicationObservers.forEach { healthStore.stop($0) }
        medicationObservers.removeAll()
        
        backgroundDeliveryObservers.forEach { healthStore.stop($0) }
        backgroundDeliveryObservers.removeAll()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Data Fetching
    
    func fetchLatestMedications() async {
        guard isAuthorized else { return }
        
        do {
            let medications = try await fetchMedicationsFromHealthKit()
            await MainActor.run {
                self.currentMedications = medications.filter { $0.isActive }
                self.medicationHistory = medications
                self.lastUpdateTime = Date()
            }
        } catch {
            print("Failed to fetch medications: \(error)")
        }
    }
    
    private func fetchMedicationsFromHealthKit() async throws -> [MedicationRecord] {
        let medicationType = HKObjectType.clinicalType(forIdentifier: .medicationRecord)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
            end: nil,
            options: .strictStartDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: medicationType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                if let error = error {
                    print("Query error for medication records: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKClinicalRecord] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let medications = samples.compactMap { sample -> MedicationRecord? in
                    return self?.convertHealthKitSampleToMedicationRecord(sample)
                }
                
                continuation.resume(returning: medications)
            }
            
            healthStore.execute(query)
        }
    }
    
    private nonisolated func convertHealthKitSampleToMedicationRecord(_ sample: HKClinicalRecord) -> MedicationRecord? {
        // Extract medication information from clinical record
        guard let medicationName = extractMedicationName(from: sample) else { return nil }
        
        // In HealthKit, endDate might be a distant future date to represent "no end date"
        let isActive: Bool
        let endDate: Date?
        
        // Check if endDate is a reasonable date (not distant future)
        let distantFuture = Calendar.current.date(byAdding: .year, value: 100, to: Date()) ?? Date.distantFuture
        if sample.endDate > distantFuture {
            // This represents "no end date" in HealthKit
            endDate = nil
            isActive = true
        } else {
            endDate = sample.endDate
            if let endDate = endDate {
                isActive = endDate > Date()
            } else {
                isActive = true
            }
        }
        
        return MedicationRecord(
            id: sample.uuid.uuidString,
            createdBy: "", // HealthKit doesn't provide user ID
            name: medicationName,
            dosage: MedicationDosage(
                amount: 0, // HealthKit doesn't provide dosage amounts
                unit: "mg",
                frequency: .asNeeded
            ),
            startDate: sample.startDate,
            endDate: endDate,
            isActive: isActive,
            notes: sample.metadata?["notes"] as? String,
            source: .healthKit,
            privacyLevel: .private,
            healthKitUUID: sample.uuid
        )
    }
    
    private nonisolated func extractMedicationName(from sample: HKClinicalRecord) -> String? {
        // Try to extract medication name from various sources in the clinical record
        if let medicationName = sample.metadata?["medicationName"] as? String {
            return medicationName
        }
        
        // displayName is non-optional in HKClinicalRecord
        let displayName = sample.displayName
        if !displayName.isEmpty {
            return displayName
        }
        
        // Fallback to UUID if no name is available
        let uuidString = sample.uuid.uuidString
        let shortUUID = String(uuidString.prefix(8))
        return "Medication \(shortUUID)"
    }
    
    // MARK: - Manual Medication Entry
    
    func addMedication(_ medication: MedicationRecord) async throws {
        // For manual entries, we'll store locally since HealthKit doesn't support writing medication data
        // This maintains privacy while allowing user input
        await MainActor.run {
            self.currentMedications.append(medication)
            self.medicationHistory.append(medication)
            self.lastUpdateTime = Date()
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        // For cleanup in deinit, we'll use weak references to avoid self capture
        // This is a common pattern for cleanup operations
        let healthStore = self.healthStore
        let medicationObservers = self.medicationObservers
        let backgroundDeliveryObservers = self.backgroundDeliveryObservers
        
        // Clean up observers directly without capturing self
        medicationObservers.forEach { healthStore.stop($0) }
        backgroundDeliveryObservers.forEach { healthStore.stop($0) }
        
        // Remove notification observer - use weak reference to avoid self capture
        if let observer = self as? NSObject {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - HealthKit Extensions

extension HKClinicalRecord {
    var isActive: Bool {
        // In HealthKit, endDate might be a distant future date to represent "no end date"
        let distantFuture = Calendar.current.date(byAdding: .year, value: 100, to: Date()) ?? Date.distantFuture
        
        if self.endDate > distantFuture {
            // This represents "no end date" in HealthKit
            return true
        } else {
            return self.endDate > Date()
        }
    }
}

