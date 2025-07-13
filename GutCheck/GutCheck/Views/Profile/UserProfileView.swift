import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    let user: User
    
    var body: some View {
        NavigationStack {
            ScrollView {
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
                                    Text(user.initials)
                                        .font(.system(size: 36, weight: .bold))
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
                        
                        Text(user.fullName)
                            .font(.title2.bold())
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    
                    // Info cards
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            ProfileInfoCard(title: "Gender", value: user.genderString, icon: "person.fill")
                            ProfileInfoCard(title: "Age", value: user.age != nil ? "\(user.age!) Years" : "Not Set", icon: "calendar")
                        }
                        HStack(spacing: 16) {
                            ProfileInfoCard(title: "Weight", value: user.formattedWeight, icon: "scalemass")
                            ProfileInfoCard(title: "Height", value: user.formattedHeight, icon: "ruler")
                        }
                    }
                    
                    // Action rows
                    VStack(spacing: 4) {
                        Button(action: {
                            // Health data integration action
                        }) {
                            ProfileActionRow(icon: "heart", title: "Health Data Integration")
                        }
                        
                        Button(action: {
                            // Navigate to Reminders
                        }) {
                            ProfileActionRow(icon: "bell.badge", title: "Reminders")
                        }
                        
                        Button(action: {
                            // Sign out action
                            Task {
                                do {
                                    try authService.signOut()
                                    dismiss()
                                } catch {
                                    print("Error signing out: \(error)")
                                }
                            }
                        }) {
                            ProfileActionRow(icon: "arrow.right.square", title: "Sign Out", textColor: ColorTheme.error)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(ColorTheme.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
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
    var textColor: Color = ColorTheme.primaryText
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(ColorTheme.accent)
                .frame(width: 36, height: 36)
                .background(Circle().fill(ColorTheme.accent.opacity(0.08)))
            Text(title)
                .font(.body)
                .foregroundColor(textColor)
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
            UserProfileView(user: User(
                id: "1",
                email: "jenny@email.com",
                firstName: "Jenny",
                lastName: "Wilson"
            ))
        }
    }
}
#endif
