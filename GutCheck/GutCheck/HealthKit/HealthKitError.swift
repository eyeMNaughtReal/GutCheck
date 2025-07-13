//
//  HealthKitError.swift
//  GutCheck
//
//  Complete HealthKit error handling implementation
//

import Foundation
import HealthKit

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case noData
    case invalidData
    case permissionDenied
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit access not authorized"
        case .noData:
            return "No health data available"
        case .invalidData:
            return "Invalid health data format"
        case .permissionDenied:
            return "Permission to access health data was denied"
        case .unknownError(let error):
            return "Unknown HealthKit error: \(error.localizedDescription)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .notAvailable:
            return "This device does not support HealthKit functionality"
        case .notAuthorized:
            return "The app is not authorized to access HealthKit data"
        case .noData:
            return "No health data has been recorded or is accessible"
        case .invalidData:
            return "The health data format is corrupted or invalid"
        case .permissionDenied:
            return "User denied permission to access health data"
        case .unknownError:
            return "An unexpected error occurred while accessing HealthKit"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is only available on iOS devices. This feature will not work in the simulator."
        case .notAuthorized, .permissionDenied:
            return "Please go to Settings > Privacy & Security > Health > GutCheck and enable the required permissions."
        case .noData:
            return "Please ensure you have health data recorded in the Health app, or try syncing with a fitness device."
        case .invalidData:
            return "Try restarting the app or re-authorizing HealthKit access."
        case .unknownError:
            return "Please try again. If the problem persists, restart the app."
        }
    }
}

// MARK: - HealthKit Authorization Status Extension
extension HKAuthorizationStatus {
    var isAuthorized: Bool {
        return self == .sharingAuthorized
    }
    
    var errorDescription: String {
        switch self {
        case .notDetermined:
            return "HealthKit authorization not requested"
        case .sharingDenied:
            return "HealthKit access denied"
        case .sharingAuthorized:
            return "HealthKit access authorized"
        @unknown default:
            return "Unknown HealthKit authorization status"
        }
    }
}

// MARK: - HealthKit Result Type
enum HealthKitResult<T> {
    case success(T)
    case failure(HealthKitError)
    
    var value: T? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    var error: HealthKitError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
