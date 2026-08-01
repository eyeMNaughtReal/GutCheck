import SwiftUI

struct ProfileSetupView: View {
    @Environment(LocalUserService.self) var userService
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Set Up Your Profile")
                    .font(.title.bold())
                    .foregroundStyle(ColorTheme.primaryText)
                TextField("First Name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
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
                            .foregroundStyle(.white)
                            .clipShape(.rect(cornerRadius: 10))
                    }
                }
                .disabled(isSaving || firstName.isEmpty || lastName.isEmpty)
            }
            .padding()
        }
    }
    
    private func saveProfile() {
        // The profile already exists — it is created on first launch. This
        // screen only fills in the name, so it updates rather than creates.
        guard var user = userService.currentUser else { return }
        isSaving = true
        errorMessage = nil

        user.firstName = firstName
        user.lastName = lastName

        Task {
            do {
                try await userService.updateUserProfile(user)
                await MainActor.run {
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
