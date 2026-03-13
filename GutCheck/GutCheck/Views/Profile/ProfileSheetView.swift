import SwiftUI

struct ProfileSheetView: View {
    @Environment(AuthService.self) var authService

    var body: some View {
        Group {
            if let currentUser = authService.currentUser {
                UserProfileView(user: currentUser)
                    .environment(authService)
            } else if authService.isAuthenticated {
                ProfileSetupView()
                    .environment(authService)
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading profile...")
                        .foregroundStyle(ColorTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ColorTheme.background)
            }
        }
    }
}
