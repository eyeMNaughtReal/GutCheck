//
//  UnitSystem.swift
//  GutCheck
//
//  Shared unit system definitions
//

import Foundation

// MARK: - Unit System
enum UnitSystem: String, CaseIterable {
    case metric, imperial
    
    var displayName: String {
        switch self {
        case .metric: return "Metric"
        case .imperial: return "Imperial"
        }
    }
}

// MARK: - App Color Scheme
enum AppColorScheme: String, CaseIterable {
    case system, light, dark

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

// MARK: - App Language
enum AppLanguage: String, CaseIterable {
    case english, spanish, french
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        }
    }
}