//
//  PainLevel+Conversion.swift
//  GutCheck
//
//  Extension to handle PainLevel integer conversion.
//

// Extension to handle PainLevel conversion
extension PainLevel {
    var intValue: Int {
        switch self {
        case .none: return 0
        case .mild: return 1
        case .moderate: return 2
        case .severe: return 3
        }
    }
    
    static func fromInt(_ value: Int) -> PainLevel {
        switch value {
        case 0: return .none
        case 1: return .mild
        case 2: return .moderate
        case 3: return .severe
        default: return .none
        }
    }
}

// MARK: - Comparable

/// Lets severity be compared as `pain >= .moderate` rather than through
/// `rawValue`.
///
/// Added after three unreachable branches were found in DashboardDataStore
/// comparing `painLevel.rawValue` against 7 and 8 — thresholds from a 0-10
/// scale this enum has never used. Comparing raw integers silently accepts any
/// number; comparing cases can only be written against values that exist.
extension PainLevel: Comparable {
    static func < (lhs: PainLevel, rhs: PainLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
