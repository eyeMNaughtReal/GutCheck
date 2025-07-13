import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var authService: AuthService
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Set Up Your Profile")
                    .font(.title.bold())
                    .foregroundColor(ColorTheme.primaryText)
                TextField("First Name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
                Button(action: saveProfile) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save Profile")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(isSaving || firstName.isEmpty || lastName.isEmpty)
            }
            .padding()
        }
    }
    
    private func saveProfile() {
        guard let firebaseUser = authService.user else { return }
        isSaving = true
        errorMessage = nil
        Task {
            do {
                let newUser = try await authService.createUserProfile(
                    userId: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    firstName: firstName,
                    lastName: lastName,
                    signInMethod: .email // or .phone if needed
                )
                await MainActor.run {
                    authService.currentUser = newUser
                    isSaving = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}
