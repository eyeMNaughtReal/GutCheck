import SwiftUI
import Foundation

// MARK: - Activity Entry Model
struct ActivityEntry: Identifiable, Hashable {
    let id = UUID()
    let type: ActivityType
    let timestamp: Date
    
    var title: String {
        switch type {
        case .meal(let meal):
            return meal.name
        case .symptom:
            return "Symptom Logged"
        }
    }
    
    var subtitle: String? {
        switch type {
        case .meal(let meal):
            return meal.notes
        case .symptom(let symptom):
            var components: [String] = []
            if symptom.painLevel != .none {
                components.append("Pain: \(symptom.painLevel.description)")
            }
            if symptom.urgencyLevel != .none {
                components.append("Urgency: \(symptom.urgencyLevel.description)")
            }
            return components.isEmpty ? nil : components.joined(separator: "\n")
        }
    }
    
    var icon: String {
        switch type {
        case .meal:
            return "fork.knife"
        case .symptom:
            return "exclamationmark.triangle"
        }
    }
    
    var iconColor: Color {
        switch type {
        case .meal:
            return ColorTheme.accent
        case .symptom:
            return ColorTheme.warning
        }
    }
}

enum ActivityType: Hashable, Equatable {
    case meal(Meal)
    case symptom(Symptom)
    
    static func == (lhs: ActivityType, rhs: ActivityType) -> Bool {
        switch (lhs, rhs) {
        case (.meal(let lhsMeal), .meal(let rhsMeal)):
            return lhsMeal.id == rhsMeal.id
        case (.symptom(let lhsSymptom), .symptom(let rhsSymptom)):
            return lhsSymptom.id == rhsSymptom.id
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .meal(let meal):
            hasher.combine("meal")
            hasher.combine(meal.id)
        case .symptom(let symptom):
            hasher.combine("symptom")
            hasher.combine(symptom.id)
        }
    }
}

// MARK: - Extensions for better display
extension PainLevel {
    var description: String {
        switch self {
        case .none:
            return "None"
        case .mild:
            return "Mild"
        case .moderate:
            return "Moderate"
        case .severe:
            return "Severe"
        }
    }
}

extension UrgencyLevel {
    var description: String {
        switch self {
        case .none:
            return "None"
        case .mild:
            return "Mild"
        case .moderate:
            return "Moderate"
        case .urgent:
            return "Urgent"
        }
    }
}
