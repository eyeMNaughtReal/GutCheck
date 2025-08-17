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
            return meal.type.rawValue.capitalized
        case .symptom:
            return "Symptom Logged"
        case .medication(let medication):
            return medication.name
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
        case .medication(let medication):
            var components: [String] = []
            components.append("\(medication.dosage.amount) \(medication.dosage.unit)")
            if let notes = medication.notes, !notes.isEmpty {
                components.append(notes)
            }
            return components.joined(separator: " • ")
        }
    }
    
    var icon: String {
        switch type {
        case .meal:
            return "fork.knife"
        case .symptom:
            return "exclamationmark.triangle"
        case .medication:
            return "pills"
        }
    }
    
    var iconColor: Color {
        switch type {
        case .meal:
            return ColorTheme.accent
        case .symptom:
            return ColorTheme.warning
        case .medication:
            return ColorTheme.primary
        }
    }
}

enum ActivityType: Hashable, Equatable {
    case meal(Meal)
    case symptom(Symptom)
    case medication(MedicationRecord)
    
    static func == (lhs: ActivityType, rhs: ActivityType) -> Bool {
        switch (lhs, rhs) {
        case (.meal(let lhsMeal), .meal(let rhsMeal)):
            return lhsMeal.id == rhsMeal.id
        case (.symptom(let lhsSymptom), .symptom(let rhsSymptom)):
            return lhsSymptom.id == rhsSymptom.id
        case (.medication(let lhsMed), .medication(let rhsMed)):
            return lhsMed.id == rhsMed.id
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
        case .medication(let medication):
            hasher.combine("medication")
            hasher.combine(medication.id)
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
