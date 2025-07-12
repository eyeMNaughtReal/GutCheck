import SwiftUI

struct GreetingHeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back, Mark!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.primaryText)
                Text("Here’s how your day is going so far:")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            Spacer()
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
}
