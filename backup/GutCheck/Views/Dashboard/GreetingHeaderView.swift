import SwiftUI

struct GreetingHeaderView: View {
    @EnvironmentObject var authService: AuthService
    
    private var greeting: String {
        if let user = authService.currentUser {
            return "Welcome back, \(user.firstName)!"
        } else {
            return "Welcome back!"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.primaryText)
                Text("Here's how your day is going so far:")
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
