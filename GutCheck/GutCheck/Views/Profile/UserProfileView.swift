import SwiftUI

struct UserProfileView: View {
    let user: UserProfile
    var body: some View {
        VStack(spacing: 24) {
            // Profile section
            VStack(spacing: 8) {
                ZStack(alignment: .bottom) {
                    Circle()
                        .strokeBorder(ColorTheme.accent, lineWidth: 5)
                        .frame(width: 110, height: 110)
                        .background(
                            Circle()
                                .fill(ColorTheme.cardBackground)
                                .frame(width: 110, height: 110)
                        )
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(ColorTheme.accent)
                        )
                    Text("Pro")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(ColorTheme.accent))
                        .offset(y: 18)
                }
                .padding(.top, 16)
                Text(user.fullName ?? "Name")
                    .font(.title2.bold())
                    .foregroundColor(ColorTheme.primaryText)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            // Info cards
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ProfileInfoCard(title: "Gender", value: "Male", icon: "person.fill")
                    ProfileInfoCard(title: "Age", value: "\(user.age ?? 0) Years", icon: "calendar")
                }
                HStack(spacing: 16) {
                    ProfileInfoCard(title: "Weight", value: "\(Int(user.weight ?? 0)) kg", icon: "scalemass")
                    ProfileInfoCard(title: "Height", value: "\(Int(user.height ?? 0)) cm", icon: "ruler")
                }
            }
            // Action rows
            VStack(spacing: 4) {
                ProfileActionRow(icon: "heart", title: "Track with Watch")
                ProfileActionRow(icon: "bell", title: "Notification")
                NavigationLink(destination: UserRemindersView()) {
                    ProfileActionRow(icon: "bell.badge", title: "Reminders")
                }
            }
            Spacer()
        }
        .padding()
        .background(ColorTheme.background.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileInfoCard: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ColorTheme.accent)
                .padding(8)
                .background(Circle().fill(ColorTheme.accent.opacity(0.08)))
            Text(title)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
            Text(value)
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: ColorTheme.shadowColor.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

struct ProfileActionRow: View {
    let icon: String
    let title: String
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(ColorTheme.accent)
                .frame(width: 36, height: 36)
                .background(Circle().fill(ColorTheme.accent.opacity(0.08)))
            Text(title)
                .font(.body)
                .foregroundColor(ColorTheme.primaryText)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(ColorTheme.secondaryText)
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: ColorTheme.shadowColor.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

#if DEBUG
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            UserProfileView(user: UserProfile(id: "1", email: "jenny@email.com", fullName: "Jenny Wilson", age: 20, weight: 76, height: 176))
        }
    }
}
#endif
