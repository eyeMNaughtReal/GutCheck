import SwiftUI

struct ProfileAvatarButton: View {
    let user: User?
    let size: CGFloat
    let action: () -> Void
    
    @StateObject private var profileImageService = LocalProfileImageService()
    @State private var profileImage: UIImage?
    @State private var isLoadingImage = false
    
    init(user: User?, size: CGFloat = 36, action: @escaping () -> Void) {
        self.user = user
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if let image = profileImage {
                    // Profile image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(ColorTheme.accent, lineWidth: 2))
                } else if isLoadingImage {
                    // Loading state
                    Circle()
                        .fill(ColorTheme.cardBackground)
                        .frame(width: size, height: size)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: ColorTheme.accent))
                                .scaleEffect(0.7)
                        )
                        .overlay(Circle().stroke(ColorTheme.accent, lineWidth: 2))
                } else {
                    // Default avatar with initials or fallback icon
                    Circle()
                        .fill(ColorTheme.accent.opacity(0.2))
                        .frame(width: size, height: size)
                        .overlay(
                            Group {
                                if let user = user {
                                    Text(user.initials)
                                        .font(.system(size: size * 0.4, weight: .semibold))
                                        .foregroundColor(ColorTheme.accent)
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: size * 0.8))
                                        .foregroundColor(ColorTheme.accent)
                                }
                            }
                        )
                        .overlay(Circle().stroke(ColorTheme.accent, lineWidth: 2))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Profile Menu")
        .onAppear {
            loadProfileImage()
        }
        .onChange(of: user?.profileImageURL) { _, _ in
            loadProfileImage()
        }
        .onChange(of: user?.id) { _, _ in
            // Reload when user changes
            loadProfileImage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileImageUpdated)) { _ in
            // Reload profile image when updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loadProfileImage()
            }
        }
    }
    
    private func loadProfileImage() {
        // Reset state first
        profileImage = nil
        isLoadingImage = false
        
        guard let user = user else {
            print("🖼️ ProfileAvatarButton: No user provided")
            return
        }
        
        // Check if user has a local profile image
        if profileImageService.hasLocalProfileImage(for: user.id) {
            let localImagePath = "local://profile_\(user.id).jpg"
            print("🖼️ ProfileAvatarButton: Loading local profile image: \(localImagePath)")
            isLoadingImage = true
            
            Task {
                do {
                    let image = try await profileImageService.downloadProfileImage(from: localImagePath)
                    await MainActor.run {
                        print("🖼️ ProfileAvatarButton: Successfully loaded local profile image")
                        self.profileImage = image
                        self.isLoadingImage = false
                    }
                } catch {
                    await MainActor.run {
                        print("🖼️ ProfileAvatarButton: Failed to load local profile image: \(error.localizedDescription)")
                        self.profileImage = nil
                        self.isLoadingImage = false
                    }
                }
            }
        } else {
            print("🖼️ ProfileAvatarButton: No local profile image found for user \(user.id)")
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProfileAvatarButton(user: nil, size: 36) { }
        
        ProfileAvatarButton(
            user: User(
                id: "preview",
                email: "test@example.com",
                firstName: "John",
                lastName: "Doe",
                signInMethod: .email,
                createdAt: Date(),
                updatedAt: Date()
            ),
            size: 50
        ) { }
    }
    .padding()
}
