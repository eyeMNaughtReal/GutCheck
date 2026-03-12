import SwiftUI

struct GraphPreviewView: View {
    let meals: [Meal]
    let symptoms: [Symptom]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Symptoms vs Meals")
                .font(.headline)
            Text("AI trend analysis coming soon...")
                .font(.caption)
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 120)
                .clipShape(.rect(cornerRadius: 8))
                .overlay(Text("Graph Placeholder"))
        }
    }
}
