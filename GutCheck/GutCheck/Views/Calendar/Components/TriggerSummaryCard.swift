import SwiftUI

struct TriggerSummaryCard: View {
    let triggers: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Identified Triggers")
                .font(.headline)
                .foregroundStyle(.primary)
            
            ForEach(triggers, id: \.self) { trigger in
                Text(trigger)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
    }
}

#Preview {
    TriggerSummaryCard(triggers: ["Dairy", "Gluten"])
}
