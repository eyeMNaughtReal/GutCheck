import SwiftUI

struct ProfileSheetView: View {
    @Environment(LocalUserService.self) var userService

    var body: some View {
        Group {
            if let currentUser = userService.currentUser {
                UserProfileView(user: currentUser)
                    .environment(userService)
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
