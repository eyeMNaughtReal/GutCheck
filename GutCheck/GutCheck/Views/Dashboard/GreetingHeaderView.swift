import SwiftUI

struct GreetingHeaderView: View {
    @Environment(AuthService.self) var authService
    @Environment(AppRouter.self) var router

    /// "Good morning/afternoon/evening!" based on the current hour.
    private var timeOfDayGreeting: String {
        switch Calendar.current.component(.hour, from: Date.now) {
        case 0..<12:  return "Good morning!"
        case 12..<17: return "Good afternoon!"
        default:      return "Good evening!"
        }
    }

    private var displayName: String {
        guard let user = authService.currentUser else { return "" }
        let name = user.fullName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? user.firstName : name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Identity row: avatar left, greeting + name, settings right.
            HStack(spacing: 12) {
                ProfileAvatarButton(user: authService.currentUser, size: 48) {
                    router.showProfile()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(timeOfDayGreeting)
                        .typography(Typography.subheadline)
                        .foregroundStyle(ColorTheme.secondaryText)

                    if !displayName.isEmpty {
                        Text(displayName)
                            .typography(Typography.headline)
                            .foregroundStyle(ColorTheme.primaryText)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                NavigationLink(value: AppDestination.settings) {
                    Image(systemName: "gearshape")
                        .typography(Typography.headline)
                        .foregroundStyle(ColorTheme.primaryText)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(ColorTheme.cardBackground))
                }
                .accessibilityLabel("Settings")
            }

            // Hero line — carries the page, so it gets the largest type level.
            Text("Here's how your day is going so far:")
                .typography(Typography.largeTitle)
                .foregroundStyle(ColorTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
