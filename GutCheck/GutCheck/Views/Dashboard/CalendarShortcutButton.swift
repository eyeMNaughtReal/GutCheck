import SwiftUI

struct CalendarShortcutButton: View {
    var body: some View {
        NavigationLink(destination: CalendarView(selectedDate: Date())) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(ColorTheme.accent)
                Text("View Full Calendar")
                    .foregroundColor(ColorTheme.primaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(ColorTheme.secondaryText)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(ColorTheme.cardBackground))
            .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
        }
    }
}
