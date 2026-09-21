//
//  SymptomLevel+Display.swift
//  GutCheck
//
//  Display helpers for the symptom severity enums.
//
//  These lived at the bottom of PaginatedSymptomHistoryView.swift, a view
//  nothing presented. Deleting that file broke CalendarView, which reads
//  `displayName` — the view was dead but these extensions were not. Moved here
//  so their lifetime no longer depends on an unrelated screen.
//

import SwiftUI

extension PainLevel {
    /// Delegates to the shared severity ramp — see ColorTheme.severity(_:).
    var color: Color { severityColor }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }
}

extension UrgencyLevel {
    /// Delegates to the shared severity ramp — see ColorTheme.severity(_:).
    var color: Color { severityColor }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .urgent: return "Urgent"
        }
    }
}

extension StoolType {
    var typeNumber: Int {
        switch self {
        case .type1: return 1
        case .type2: return 2
        case .type3: return 3
        case .type4: return 4
        case .type5: return 5
        case .type6: return 6
        case .type7: return 7
        }
    }
}
