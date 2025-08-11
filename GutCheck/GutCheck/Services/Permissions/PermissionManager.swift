//
//  PermissionManager.swift
//  GutCheck
//
//  Comprehensive permission management for iOS 18.5+
//  Follows Apple Design Guidelines and App Store Review Guidelines
//

import Foundation
import AVFoundation
import Photos
import UserNotifications
import HealthKit
import CoreLocation
import UIKit

/// Centralized permission management following Apple's iOS 18.5+ guidelines
@MainActor
class PermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = PermissionManager()
    
    // MARK: - Published States
    @Published var cameraStatus: PermissionStatus = .notDetermined
    @Published var photoLibraryStatus: PermissionStatus = .notDetermined
    @Published var notificationStatus: PermissionStatus = .notDetermined
    @Published var healthKitStatus: PermissionStatus = .notDetermined
    @Published var locationStatus: PermissionStatus = .notDetermined
    
    // MARK: - Permission Status Enum
    enum PermissionStatus: Equatable {
        case notDetermined
        case requesting
        case granted
        case denied
        case restricted
        case limited // For photos in iOS 14+
        
        var isGranted: Bool {
            return self == .granted || self == .limited
        }
        
        var needsRequest: Bool {
            return self == .notDetermined
        }
        
        var canOpenSettings: Bool {
            return self == .denied || self == .restricted
        }
    }
    
    // MARK: - Permission Types
    enum PermissionType: CaseIterable {
        case camera
        case photoLibrary
        case notifications
        case healthKit
        case location
        
        var title: String {
            switch self {
            case .camera: return "Camera"
            case .photoLibrary: return "Photo Library"
            case .notifications: return "Notifications"
            case .healthKit: return "Health Data"
            case .location: return "Location"
            }
        }
        
        var icon: String {
            switch self {
            case .camera: return "camera"
            case .photoLibrary: return "photo"
            case .notifications: return "bell"
            case .healthKit: return "heart.text.square"
            case .location: return "location"
            }
        }
        
        var description: String {
            switch self {
            case .camera:
                return "Scan food barcodes and estimate portion sizes with advanced camera technology"
            case .photoLibrary:
                return "Save meal photos to help you visually track your food intake"
            case .notifications:
                return "Receive helpful reminders to log meals and symptoms consistently"
            case .healthKit:
                return "Sync nutrition and symptom data with Apple Health for comprehensive tracking"
            case .location:
                return "Get contextual meal suggestions when dining out (optional)"
            }
        }
        
        var isRequired: Bool {
            switch self {
            case .camera: return true // Required for core barcode scanning
            case .photoLibrary: return false
            case .notifications: return false
            case .healthKit: return false
            case .location: return false
            }
        }
    }
    
    // MARK: - HealthKit Manager
    private let healthStore = HKHealthStore()
    
    // MARK: - Location Manager
    private let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        updateAllPermissionStates()
    }
    
    // MARK: - Permission State Updates
    func updateAllPermissionStates() {
        updateCameraStatus()
        updatePhotoLibraryStatus()
        updateNotificationStatus()
        updateHealthKitStatus()
        updateLocationStatus()
    }
    
    private func updateCameraStatus() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        cameraStatus = authStatus.toPermissionStatus()
    }
    
    private func updatePhotoLibraryStatus() {
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        photoLibraryStatus = authStatus.toPermissionStatus()
    }
    
    private func updateNotificationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                self.notificationStatus = settings.authorizationStatus.toPermissionStatus()
            }
        }
    }
    
    private func updateHealthKitStatus() {
        // HealthKit doesn't have a simple authorization status check
        // We'll determine this based on whether we can access data
        if HKHealthStore.isHealthDataAvailable() {
            healthKitStatus = .notDetermined // Will be updated when actually requested
        } else {
            healthKitStatus = .restricted
        }
    }
    
    private func updateLocationStatus() {
        locationStatus = locationManager.authorizationStatus.toPermissionStatus()
    }
    
    // MARK: - Permission Request Methods
    
    /// Request camera permission with proper user context
    func requestCameraPermission() async -> Bool {
        guard cameraStatus.needsRequest else {
            return cameraStatus.isGranted
        }
        
        cameraStatus = .requesting
        
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        
        await MainActor.run {
            self.cameraStatus = granted ? .granted : .denied
        }
        
        return granted
    }
    
    /// Request photo library permission for saving meal photos
    func requestPhotoLibraryPermission() async -> Bool {
        guard photoLibraryStatus.needsRequest else {
            return photoLibraryStatus.isGranted
        }
        
        photoLibraryStatus = .requesting
        
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        
        await MainActor.run {
            self.photoLibraryStatus = status.toPermissionStatus()
        }
        
        return photoLibraryStatus.isGranted
    }
    
    /// Request notification permission with specific options
    func requestNotificationPermission() async -> Bool {
        guard notificationStatus.needsRequest else {
            return notificationStatus.isGranted
        }
        
        notificationStatus = .requesting
        
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            
            await MainActor.run {
                self.notificationStatus = granted ? .granted : .denied
            }
            
            return granted
        } catch {
            await MainActor.run {
                self.notificationStatus = .denied
            }
            return false
        }
    }
    
    /// Request HealthKit permissions for nutrition and symptom data
    func requestHealthKitPermission() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitStatus = .restricted
            return false
        }
        
        guard healthKitStatus.needsRequest else {
            return healthKitStatus.isGranted
        }
        
        healthKitStatus = .requesting
        
        // Define data types we want to read and write
        let nutritionTypes: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!,
            HKQuantityType.quantityType(forIdentifier: .dietarySodium)!,
            HKQuantityType.quantityType(forIdentifier: .dietarySugar)!
        ]
        
        let readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .height)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: nutritionTypes, read: readTypes)
            
            await MainActor.run {
                self.healthKitStatus = .granted
            }
            
            return true
        } catch {
            await MainActor.run {
                self.healthKitStatus = .denied
            }
            return false
        }
    }
    
    /// Request location permission for contextual features
    func requestLocationPermission() async -> Bool {
        guard locationStatus.needsRequest else {
            return locationStatus.isGranted
        }
        
        locationStatus = .requesting
        locationManager.requestWhenInUseAuthorization()
        
        // Note: Location permission response is handled via delegate
        // For now, we'll just update the status
        await MainActor.run {
            self.updateLocationStatus()
        }
        
        return locationStatus.isGranted
    }
    
    // MARK: - Settings Management
    
    /// Opens the app's settings page
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Permission Checking
    
    /// Check if permission is granted for a specific type
    func isPermissionGranted(_ type: PermissionType) -> Bool {
        switch type {
        case .camera: return cameraStatus.isGranted
        case .photoLibrary: return photoLibraryStatus.isGranted
        case .notifications: return notificationStatus.isGranted
        case .healthKit: return healthKitStatus.isGranted
        case .location: return locationStatus.isGranted
        }
    }
    
    /// Get status for a specific permission type
    func getPermissionStatus(_ type: PermissionType) -> PermissionStatus {
        switch type {
        case .camera: return cameraStatus
        case .photoLibrary: return photoLibraryStatus
        case .notifications: return notificationStatus
        case .healthKit: return healthKitStatus
        case .location: return locationStatus
        }
    }
    
    // MARK: - Bulk Permission Requests
    
    /// Request core permissions required for the app
    func requestCorePermissions() async -> [PermissionType: Bool] {
        var results: [PermissionType: Bool] = [:]
        
        // Camera is required for core functionality
        results[.camera] = await requestCameraPermission()
        
        // Notifications for better user experience
        results[.notifications] = await requestNotificationPermission()
        
        return results
    }
    
    /// Request all optional permissions
    func requestOptionalPermissions() async -> [PermissionType: Bool] {
        var results: [PermissionType: Bool] = [:]
        
        results[.photoLibrary] = await requestPhotoLibraryPermission()
        results[.healthKit] = await requestHealthKitPermission()
        results[.location] = await requestLocationPermission()
        
        return results
    }
}

// MARK: - Extensions for Status Conversion

extension AVAuthorizationStatus {
    func toPermissionStatus() -> PermissionManager.PermissionStatus {
        switch self {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .granted
        @unknown default: return .notDetermined
        }
    }
}

extension PHAuthorizationStatus {
    func toPermissionStatus() -> PermissionManager.PermissionStatus {
        switch self {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .granted
        case .limited: return .limited
        @unknown default: return .notDetermined
        }
    }
}

extension UNAuthorizationStatus {
    func toPermissionStatus() -> PermissionManager.PermissionStatus {
        switch self {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .granted
        case .provisional: return .granted
        case .ephemeral: return .granted
        @unknown default: return .notDetermined
        }
    }
}

extension CLAuthorizationStatus {
    func toPermissionStatus() -> PermissionManager.PermissionStatus {
        switch self {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorizedAlways, .authorizedWhenInUse: return .granted
        @unknown default: return .notDetermined
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension PermissionManager {
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.locationStatus = status.toPermissionStatus()
            print("📍 PermissionManager: Location authorization changed to \(status)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ PermissionManager: Location manager failed with error: \(error)")
        }
    }
}
