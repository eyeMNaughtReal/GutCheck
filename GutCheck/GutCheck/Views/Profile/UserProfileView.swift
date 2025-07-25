
import SwiftUI
import PhotosUI
// MARK: - Supporting Types (file scope)

enum UnitSystem: String, CaseIterable {
    case metric, imperial
    var displayName: String {
        switch self {
        case .metric: return "Metric"
        case .imperial: return "Imperial"
        }
    }
}

enum AppLanguage: String, CaseIterable {
    case english, spanish, french
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
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
                    // Profile section
                    VStack(spacing: 16) {
                        ZStack(alignment: .bottom) {
                            Button(action: { showImagePicker = true }) {
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
                                            Text(user.initials)
                                                .font(.system(size: 36, weight: .bold))
                                                .foregroundColor(ColorTheme.accent)
                                        )
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .sheet(isPresented: $showImagePicker) {
                                ImagePicker(image: $profileImage)
                            }
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
                        
                        Text(user.fullName)
                            .font(.title2.bold())
                            .foregroundColor(ColorTheme.primaryText)
                            .padding(.top, 4)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)
                            .padding(.bottom, 8)
                    }



                    // Info cards
                    VStack(spacing: 24) {
                        HStack(spacing: 20) {
                            ProfileInfoCard(title: "Gender", value: user.genderString, icon: "person.fill")
                            ProfileInfoCard(title: "Age", value: user.age != nil ? "\(user.age!) Years" : "Not Set", icon: "calendar")
                        }
                        HStack(spacing: 20) {
                            ProfileInfoCard(title: "Weight", value: user.formattedWeight, icon: "scalemass")
                            ProfileInfoCard(title: "Height", value: user.formattedHeight, icon: "ruler")
                        }
                    }
                    .padding(.top, 8)

                    // Action rows
                    VStack(spacing: 12) {
                        Button(action: { showSettings = true }) {
                            ProfileActionRow(icon: "gearshape", title: "Settings")
                        }

                        Button(action: { showHealthData = true }) {
                            ProfileActionRow(icon: "heart", title: "Health Data Integration")
                        }
                        
                        Button(action: {
                            showReminder = true
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
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(settingsVM)
            }
            .sheet(isPresented: $showHealthData) {
                HealthDataIntegrationView()
            }
            .sheet(isPresented: $showReminder) {
                UserRemindersView()
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
