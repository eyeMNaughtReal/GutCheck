import SwiftUI

struct SymptomSummaryCard: View {
    let symptom: Symptom
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Stool Type \(symptom.stoolType.rawValue)")
                if symptom.painLevel != .none {
                    Text("Pain: \(symptom.painLevel.rawValue)")
                }
                if symptom.urgencyLevel != .none {
                    Text("Urgency: \(symptom.urgencyLevel.rawValue)")
                }
            }
            .font(.headline)
            .foregroundColor(.primary)
            
            if let notes = symptom.notes, !notes.isEmpty {
                Text(notes)
                    .foregroundColor(.secondary)
            }
            
            Text(symptom.date.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    SymptomSummaryCard(symptom: Symptom(
        id: "1",
        date: Date(),
        stoolType: .type4,
        painLevel: .moderate,
        urgencyLevel: .mild,
        notes: "Mild discomfort",
        tags: [],
        createdBy: "user123"
    ))
}
