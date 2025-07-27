import SwiftUI

struct TriggerAlertView: View {
    @Environment(\.dismiss) private var dismiss
    let trigger: FoodTrigger
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Trigger Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Potential Trigger Detected", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text(trigger.food)
                            .font(.title)
                            .bold()
                            .foregroundColor(ColorTheme.text)
                        
                        Text("Confidence Level: \(Int(trigger.confidence * 100))%")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.text.opacity(0.8))
                    }
                    .padding()
                    .roundedCard()
                    
                    // Symptom Correlation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Symptom Correlation")
                            .font(.headline)
                        
                        ForEach(trigger.symptoms) { symptom in
                            HStack {
                                Text(symptom.name)
                                Spacer()
                                Text("\(Int(symptom.correlation * 100))%")
                                    .foregroundColor(correlationColor(symptom.correlation))
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .roundedCard()
                    
                    // Occurrence Pattern
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Occurrence Pattern")
                            .font(.headline)
                        
                        Text("This trigger appears in \(trigger.occurrenceRate)% of your symptom episodes")
                            .foregroundColor(ColorTheme.text.opacity(0.8))
                        
                        if let timeFrame = trigger.timeFrame {
                            Text("Typical onset: \(timeFrame)")
                                .foregroundColor(ColorTheme.text.opacity(0.8))
                        }
                    }
                    .padding()
                    .roundedCard()
                    
                    // Recommendations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommendations")
                            .font(.headline)
                        
                        ForEach(trigger.recommendations, id: \.self) { recommendation in
                            Label(recommendation, systemImage: "checkmark.circle")
                                .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .roundedCard()
                }
                .padding()
            }
            .navigationTitle("Trigger Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func correlationColor(_ correlation: Double) -> Color {
        switch correlation {
        case 0.8...: return .red
        case 0.6...: return .orange
        case 0.4...: return .yellow
        default: return .green
        }
    }
}

// MARK: - Supporting Types

struct FoodTrigger {
    let id = UUID()
    let food: String
    let confidence: Double
    let symptoms: [SymptomCorrelation]
    let occurrenceRate: Int
    let timeFrame: String?
    let recommendations: [String]
}

struct SymptomCorrelation: Identifiable {
    let id = UUID()
    let name: String
    let correlation: Double
}

#Preview {
    TriggerAlertView(trigger: FoodTrigger(
        food: "Dairy Products",
        confidence: 0.85,
        symptoms: [
            SymptomCorrelation(name: "Bloating", correlation: 0.9),
            SymptomCorrelation(name: "Cramps", correlation: 0.7),
            SymptomCorrelation(name: "Diarrhea", correlation: 0.6)
        ],
        occurrenceRate: 75,
        timeFrame: "2-4 hours after consumption",
        recommendations: [
            "Consider lactose-free alternatives",
            "Try smaller portions to test tolerance",
            "Keep track of different dairy types separately"
        ]
    ))
}
