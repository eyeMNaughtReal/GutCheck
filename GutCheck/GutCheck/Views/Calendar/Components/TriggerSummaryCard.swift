import SwiftUI

struct TriggerSummaryCard: View {
    let triggers: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Identified Triggers")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(triggers, id: \.self) { trigger in
                Text(trigger)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    TriggerSummaryCard(triggers: ["Dairy", "Gluten"])
}
