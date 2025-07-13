import SwiftUI

struct ProfileAvatarButton: View {
    var action: () -> Void
    var image: Image = Image(systemName: "person.circle.fill")

    var body: some View {
        Button(action: action) {
            image
                .resizable()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .foregroundColor(ColorTheme.accent)
                .accessibilityLabel("Profile Menu")
        }
    }
}
