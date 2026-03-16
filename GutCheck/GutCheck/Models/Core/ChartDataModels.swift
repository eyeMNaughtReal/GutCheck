import Foundation
import SwiftUI

// MARK: - Time Range for Charts

enum ChartTimeRange: String, CaseIterable, Identifiable {
    case last7Days = "7d"
    case last30Days = "30d"
    case last90Days = "90d"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .last7Days: return 7
        case .last30Days: return 30
        case .last90Days: return 90
        }
    }

    var displayName: String {
        switch self {
        case .last7Days: return "7 Days"
        case .last30Days: return "30 Days"
        case .last90Days: return "90 Days"
        }
    }
}

// MARK: - Symptom Chart Filter

enum SymptomChartFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pain = "Pain"
    case urgency = "Urgency"
    case stool = "Stool"

    var id: String { rawValue }
}

// MARK: - Chart Tab Selection

enum ChartTab: String, CaseIterable, Identifiable {
    case timeline = "Timeline"
    case severity = "Severity"
    case weekly = "Weekly"
    case ingredients = "Ingredients"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .timeline: return "calendar.day.timeline.left"
        case .severity: return "chart.xyaxis.line"
        case .weekly: return "chart.bar.fill"
        case .ingredients: return "chart.pie.fill"
        }
    }
}

// MARK: - Data Points

/// Timeline chart: one dot per symptom log day, color-coded by max severity
struct TimelineDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let severityLevel: Int       // 0=none, 1=mild, 2=moderate, 3=severe
    let symptomCount: Int
    let label: String

    var severityColor: Color {
        switch severityLevel {
        case 0: return .green
        case 1: return .yellow
        case 2: return .orange
        default: return .red
        }
    }
}

/// Severity line chart: daily max severity for pain and urgency
struct SeverityLineDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Int               // 0-3 severity scale
    let series: String           // "Pain" or "Urgency"
}

/// Weekly bar chart: symptom count per calendar week
struct WeeklyBarDataPoint: Identifiable {
    let id = UUID()
    let weekLabel: String        // e.g. "Mar 3"
    let weekStart: Date
    let count: Int
}

/// Ingredient pie chart: top repeated ingredients
struct IngredientSliceDataPoint: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}
