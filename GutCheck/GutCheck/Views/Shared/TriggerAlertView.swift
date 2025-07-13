import SwiftUI

struct TriggerAlertView: View {
    let alerts: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Trigger Alert", systemImage: "exclamationmark.circle")
                .font(.headline)
                .foregroundColor(.red)
            ForEach(alerts, id: \.self) { alert in
                Text("• \(alert)")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: 1))
        .frame(maxWidth: .infinity)
    }
}
