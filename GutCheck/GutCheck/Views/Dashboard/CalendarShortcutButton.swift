import SwiftUI

struct CalendarShortcutButton: View {
    var body: some View {
        NavigationLink(value: AppDestination.calendar(Date.now)) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(ColorTheme.accent)
                Text("View Full Calendar")
                    .foregroundStyle(ColorTheme.primaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(ColorTheme.secondaryText)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(ColorTheme.cardBackground))
            .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
        }
    }
}
