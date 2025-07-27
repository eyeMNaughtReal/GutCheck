import SwiftUI

struct SymptomExplanationView: View {
    let symptomType: SymptomType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.title2)
                            .bold()
                        
                        Text(symptomType.description)
                            .foregroundColor(ColorTheme.text.opacity(0.8))
                    }
                    .padding()
                    .roundedCard()
                    
                    // Severity Scale
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Severity Scale")
                            .font(.title2)
                            .bold()
                        
                        ForEach(SeverityLevel.allCases, id: \.self) { level in
                            SeverityRow(level: level)
                        }
                    }
                    .padding()
                    .roundedCard()
                    
                    // Common Triggers
                    if !symptomType.commonTriggers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Common Triggers")
                                .font(.title2)
                                .bold()
                            
                            ForEach(symptomType.commonTriggers, id: \.self) { trigger in
                                Label(trigger, systemImage: "exclamationmark.triangle")
                                    .foregroundColor(ColorTheme.text.opacity(0.8))
                                    .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .roundedCard()
                    }
                    
                    // Management Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Management Tips")
                            .font(.title2)
                            .bold()
                        
                        ForEach(symptomType.managementTips, id: \.self) { tip in
                            Label(tip, systemImage: "checkmark.circle")
                                .foregroundColor(ColorTheme.text.opacity(0.8))
                                .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .roundedCard()
                    
                    // When to Seek Help
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When to Seek Help")
                            .font(.title2)
                            .bold()
                        
                        ForEach(symptomType.warningSignals, id: \.self) { warning in
                            Label(warning, systemImage: "exclamationmark.shield")
                                .foregroundColor(.red)
                                .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .roundedCard()
                }
                .padding()
            }
            .navigationTitle(symptomType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct SeverityRow: View {
    let level: SeverityLevel
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(level.range)")
                .font(.headline)
                .foregroundColor(level.color)
                .frame(width: 60, alignment: .leading)
            
            VStack(alignment: .leading) {
                Text(level.title)
                    .font(.headline)
                Text(level.description)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.text.opacity(0.8))
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Supporting Types

enum SeverityLevel: Int, CaseIterable, Identifiable {
    case mild = 1
    case moderate = 2
    case severe = 3
    
    var id: Int { rawValue }
    
    var range: String {
        switch self {
        case .mild: return "1-3"
        case .moderate: return "4-7"
        case .severe: return "8-10"
        }
    }
    
    var title: String {
        switch self {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }
    
    var description: String {
        switch self {
        case .mild: return "Noticeable but not interfering with daily activities"
        case .moderate: return "Affecting daily activities but manageable"
        case .severe: return "Severely impacting daily activities, may require immediate attention"
        }
    }
    
    var color: Color {
        switch self {
        case .mild: return .green
        case .moderate: return .yellow
        case .severe: return .red
        }
    }
}

extension SymptomType {
    var description: String {
        switch self {
        case .bowelMovement:
            return "Track your bowel movements to identify patterns and monitor digestive health. Note consistency, frequency, and any discomfort."
        case .pain:
            return "Abdominal pain can range from mild discomfort to severe cramping. Track the location, intensity, and duration to identify patterns."
        case .bloating:
            return "A feeling of fullness or swelling in the abdomen. May be accompanied by visible distension."
        case .urgency:
            return "A sudden, intense need to use the bathroom. Important to note timing relative to meals and activities."
        case .nausea:
            return "An unpleasant sensation of wanting to vomit. Can be related to various triggers including foods and stress."
        case .other:
            return "Any other digestive symptoms not covered by the main categories. Use notes to describe the specific symptom."
        }
    }
    
    var commonTriggers: [String] {
        switch self {
        case .bowelMovement:
            return ["Dietary changes", "Stress", "Medications", "Sleep changes", "Exercise"]
        case .pain:
            return ["Spicy foods", "High-fat meals", "Large meals", "Stress", "Caffeine"]
        case .bloating:
            return ["Carbonated drinks", "High-FODMAP foods", "Dairy products", "Eating too quickly"]
        case .urgency:
            return ["Caffeine", "Alcohol", "High-sugar foods", "Stress"]
        case .nausea:
            return ["Strong odors", "Motion", "Certain medications", "Empty stomach"]
        case .other:
            return ["Various triggers depending on specific symptom"]
        }
    }
    
    var managementTips: [String] {
        switch self {
        case .bowelMovement:
            return [
                "Maintain regular eating schedule",
                "Stay hydrated",
                "Include fiber in diet",
                "Exercise regularly",
                "Manage stress levels"
            ]
        case .pain:
            return [
                "Use a heating pad",
                "Practice relaxation techniques",
                "Stay hydrated",
                "Avoid trigger foods",
                "Light exercise if comfortable"
            ]
        case .bloating:
            return [
                "Eat smaller meals",
                "Avoid carbonated drinks",
                "Stay upright after eating",
                "Gentle abdominal massage",
                "Try peppermint tea"
            ]
        case .urgency:
            return [
                "Map out bathroom locations",
                "Avoid trigger foods",
                "Practice pelvic floor exercises",
                "Stay calm when urgency hits",
                "Plan meals around activities"
            ]
        case .nausea:
            return [
                "Try ginger tea or candies",
                "Eat small, frequent meals",
                "Stay hydrated",
                "Practice deep breathing",
                "Rest in a cool, quiet place"
            ]
        case .other:
            return [
                "Track patterns and triggers",
                "Consult healthcare provider",
                "Keep detailed notes",
                "Consider lifestyle factors"
            ]
        }
    }
    
    var warningSignals: [String] {
        [
            "Severe pain that doesn't improve",
            "Blood in stool",
            "High fever",
            "Severe dehydration",
            "Significant weight loss"
        ]
    }
}

#Preview {
    SymptomExplanationView(symptomType: .pain)
}
