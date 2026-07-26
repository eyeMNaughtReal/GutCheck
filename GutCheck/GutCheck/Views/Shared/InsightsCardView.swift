import SwiftUI

struct InsightsCardView: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Insight", systemImage: "lightbulb")
                .typography(Typography.headline)
            Text(message)
                .typography(Typography.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.1)))
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color.yellow, lineWidth: 1) }

    }
}
