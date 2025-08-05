
import SwiftUI
import PhotosUI

// MARK: - Supporting Components

struct ProfileImageView: View {
    let user: User
    @Binding var profileImage: UIImage?
    @Binding var showImagePicker: Bool
    @StateObject private var profileImageService = UnifiedProfileImageService(strategy: LocalProfileImageStrategy())
    @State private var isLoadingImage = false
    @State private var showingUploadError = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Button(action: { showImagePicker = true }) {
                profileImageContent
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(profileImageService.isUploading)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profileImage)
            }
            .onChange(of: profileImage) { _, newImage in
                if let image = newImage {
                    uploadProfileImage(image)
                }
            }
            .onAppear {
                loadExistingProfileImage()
            }
            
            // Upload progress indicator
            if profileImageService.isUploading {
                VStack(spacing: 8) {
                    ProgressView(value: profileImageService.uploadProgress)
                        .progressViewStyle(CircularProgressViewStyle(tint: ColorTheme.accent))
                        .scaleEffect(0.8)
                    
                    Text("Uploading...")
                        .font(.caption2)
                        .foregroundColor(ColorTheme.accent)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ColorTheme.surface.opacity(0.9))
                )
                .offset(y: -20)
            }
            
            // Pro badge
            Text("Pro")
                .font(.caption2.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(ColorTheme.accent))
                .offset(y: 18)
        }
        .padding(.top, 32)
        .padding(.bottom, 12)
        .alert("Upload Error", isPresented: $showingUploadError) {
            Button("OK") { }
        } message: {
            Text(profileImageService.errorMessage ?? "Failed to upload profile image")
        }
    }
    
    @ViewBuilder
    private var profileImageContent: some View {
        ZStack {
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(ColorTheme.accent, lineWidth: 5))
            } else {
                Circle()
                    .strokeBorder(ColorTheme.accent, lineWidth: 5)
                    .frame(width: 110, height: 110)
                    .background(
                        Circle()
                            .fill(ColorTheme.cardBackground)
                            .frame(width: 110, height: 110)
                    )
                    .overlay(
                        Group {
                            if isLoadingImage {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: ColorTheme.accent))
                            } else {
                                Text(user.initials)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(ColorTheme.accent)
                            }
                        }
                    )
            }
            
            // Camera icon overlay
            if !profileImageService.isUploading {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(ColorTheme.accent))
                            .offset(x: -8, y: -8)
                    }
                }
                .frame(width: 110, height: 110)
            }
        }
    }
    
    private func loadExistingProfileImage() {
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
                        self.isLoadingImage = false
                        print("Failed to load profile image: \(error)")
                    }
                }
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        Task {
            do {
                let imageURL = try await profileImageService.uploadProfileImage(image, for: user.id)
                await MainActor.run {
                    // Update the local profile image immediately
                    self.profileImage = image
                }
                print("✅ Profile image uploaded successfully: \(imageURL)")
                
            } catch {
                await MainActor.run {
                    self.showingUploadError = true
                    print("❌ Failed to upload profile image: \(error)")
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct ProfileInfoSection: View {
    let user: User
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 20) {
                ProfileInfoCard(title: "Gender", value: user.genderString, icon: "person.fill")
                ProfileInfoCard(title: "Age", value: ageString, icon: "calendar")
            }
            HStack(spacing: 20) {
                ProfileInfoCard(title: "Weight", value: user.formattedWeight(using: settingsVM.unitOfMeasure), icon: "scalemass")
                ProfileInfoCard(title: "Height", value: user.formattedHeight(using: settingsVM.unitOfMeasure), icon: "ruler")
            }
        }
        .padding(.top, 8)
    }
    
    private var ageString: String {
        if let age = user.age {
            return "\(age) Years"
        } else {
            return "Not Set"
        }
    }
}

struct ProfileActionSection: View {
    @Binding var showSettings: Bool
    @Binding var showHealthData: Bool
    @Binding var showReminder: Bool
    let authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: { showSettings = true }) {
                ProfileActionRow(icon: "gearshape", title: "Settings")
            }

            Button(action: { showHealthData = true }) {
                ProfileActionRow(icon: "heart", title: "Health Data Integration")
            }
            
            Button(action: { showReminder = true }) {
                ProfileActionRow(icon: "bell.badge", title: "Reminders")
            }
            
            Button(action: signOut) {
                ProfileActionRow(icon: "arrow.right.square", title: "Sign Out", textColor: ColorTheme.error)
            }
        }
    }
    
    private func signOut() {
        Task {
            do {
                try authService.signOut()
                dismiss()
            } catch {
                print("Error signing out: \(error)")
            }
        }
    }
}

import PhotosUI

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    let user: User
    
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showSettings = false
    @State private var showHealthData = false
    @State private var showReminder = false
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    profileHeaderSection
                    
                    ProfileInfoSection(user: user)
                        .environmentObject(settingsVM)
                    
                    ProfileActionSection(
                        showSettings: $showSettings,
                        showHealthData: $showHealthData, 
                        showReminder: $showReminder,
                        authService: authService
                    )
                    
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
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(settingsVM)
            }
            .sheet(isPresented: $showHealthData) {
                HealthDataIntegrationView()
                    .environmentObject(settingsVM)
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showReminder) {
                UserRemindersView()
            }
        }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            ProfileImageView(
                user: user,
                profileImage: $profileImage,
                showImagePicker: $showImagePicker
            )
            
            Text(user.fullName)
                .font(.title2.bold())
                .foregroundColor(ColorTheme.primaryText)
                .padding(.top, 4)
            
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
                .padding(.bottom, 8)
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
