import SwiftUI

struct ProfileSheetView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if let currentUser = authService.currentUser {
                UserProfileView(user: currentUser)
                    .environmentObject(authService)
            } else if authService.isAuthenticated {
                ProfileSetupView()
                    .environmentObject(authService)
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading profile...")
                        .foregroundColor(ColorTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ColorTheme.background)
            }
        }
    }
}
