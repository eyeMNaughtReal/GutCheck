import SwiftUI

struct InsightsCardView: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Insight", systemImage: "lightbulb")
                .font(.headline)
            Text(message)
                .font(.subheadline)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow, lineWidth: 1))
    }
}
