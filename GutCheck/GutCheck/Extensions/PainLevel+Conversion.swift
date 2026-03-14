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
