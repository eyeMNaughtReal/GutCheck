import SwiftUI

struct RecentActivityListView: View {
    let meals: [Meal]
    let symptoms: [Symptom]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today’s Activity")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)

            ForEach(meals) { meal in
                HStack {
                    Image(systemName: "fork.knife")
                        .foregroundColor(ColorTheme.accent)
                    Text(meal.name)
                        .foregroundColor(ColorTheme.primaryText)
                    Spacer()
                    Text(meal.date, style: .time)
                        .foregroundColor(ColorTheme.secondaryText)
                        .font(.caption)
                }
                .padding(8)
                .background(ColorTheme.surface)
                .cornerRadius(8)
            }

            ForEach(symptoms) { symptom in
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(ColorTheme.warning)
                    Text("Symptom Logged")
                        .foregroundColor(ColorTheme.primaryText)
                    Spacer()
                    Text(symptom.date, style: .time)
                        .foregroundColor(ColorTheme.secondaryText)
                        .font(.caption)
                }
                .padding(8)
                .background(ColorTheme.surface)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
}

