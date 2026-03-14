import SwiftUI

struct ProfileAvatarButton: View {
    let user: User?
    let size: CGFloat
    let action: () -> Void
    
    @State private var profileImageService = UnifiedProfileImageService(strategy: LocalProfileImageStrategy())
    @State private var profileImage: UIImage?
    @State private var isLoadingImage = false
    
    init(user: User?, size: CGFloat = 36, action: @escaping () -> Void) {
        self.user = user
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ProfileAvatarContent(
                user: user,
                size: size,
                profileImage: profileImage,
                isLoadingImage: isLoadingImage
            )
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
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                loadProfileImage()
            }
        }
    }
    
    private func loadProfileImage() {
        // Reset state first
        profileImage = nil
        isLoadingImage = false
        
        guard let user = user else {
            return
        }
        
        // Check if user has a local profile image
        if let localStrategy = profileImageService.strategy as? LocalProfileImageStrategy,
           localStrategy.hasLocalProfileImage(for: user.id) {
            let localImagePath = "local://profile_\(user.id).jpg"
            isLoadingImage = true
            
            Task {
                do {
                    let image = try await profileImageService.downloadProfileImage(from: localImagePath)
                    await MainActor.run {
                        self.profileImage = image
                        self.isLoadingImage = false
                    }
                } catch {
                    await MainActor.run {
                        self.profileImage = nil
                        self.isLoadingImage = false
                    }
                }
            }
        } else {
        }
    }
}

// MARK: - Avatar Content

struct ProfileAvatarContent: View {
    let user: User?
    let size: CGFloat
    let profileImage: UIImage?
    let isLoadingImage: Bool
    
    var body: some View {
        ZStack {
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay { Circle().stroke(ColorTheme.accent, lineWidth: 2) }
            } else if isLoadingImage {
                Circle()
                    .fill(ColorTheme.cardBackground)
                    .frame(width: size, height: size)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: ColorTheme.accent))
                            .scaleEffect(0.7)
                    )
                    .overlay { Circle().stroke(ColorTheme.accent, lineWidth: 2) }
            } else {
                Circle()
                    .fill(ColorTheme.accent.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        Group {
                            if let user = user {
                                Text(user.initials)
                                    .font(.system(size: size * 0.4, weight: .semibold))
                                    .foregroundStyle(ColorTheme.accent)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: size * 0.8))
                                    .foregroundStyle(ColorTheme.accent)
                            }
                        }
                    )
                    .overlay { Circle().stroke(ColorTheme.accent, lineWidth: 2) }
            }
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
                createdAt: Date.now,
                updatedAt: Date.now
            ),
            size: 50
        ) { }
    }
    .padding()
}
