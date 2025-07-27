import SwiftUI

struct TodaySummaryView: View {
    let mealsCount: Int
    let symptomsCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Summary")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            HStack(spacing: 16) {
                Label("\(mealsCount) Meals", systemImage: "fork.knife")
                    .foregroundColor(ColorTheme.accent)
                Spacer()
                Label("\(symptomsCount) Symptoms", systemImage: "exclamationmark.triangle")
                    .foregroundColor(ColorTheme.warning)
            }
            .font(.subheadline)
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
}
