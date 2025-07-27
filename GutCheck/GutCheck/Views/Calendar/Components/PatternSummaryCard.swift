import SwiftUI

struct PatternSummaryCard: View {
    let patterns: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Identified Patterns")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(patterns, id: \.self) { pattern in
                Text(pattern)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    PatternSummaryCard(patterns: ["Morning symptoms", "Post-meal discomfort"])
}
