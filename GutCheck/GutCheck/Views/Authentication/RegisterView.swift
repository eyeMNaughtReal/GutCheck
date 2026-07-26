import SwiftUI
import FirebaseAuth

struct RegisterView: View {
    @Environment(AuthService.self) var authService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingPrivacyPolicy = false
    @State private var agreedToTerms = false
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        password == confirmPassword &&
        password.count >= 8 &&
        agreedToTerms
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo/Welcome Section
                    VStack(spacing: 12) {
                        Image("AppIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(.rect(cornerRadius: 20))
                        
                        Text("Create Your Account")
                            .typography(Typography.title2)
                            .bold()
                        
                        Text("Track your digestive health journey with GutCheck")
                            .typography(Typography.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Name Fields
                        HStack(spacing: 16) {
                            TextField("First Name", text: $firstName)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.givenName)
                            
                            TextField("Last Name", text: $lastName)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.familyName)
                        }
                        
                        // Email Field
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        // Password Fields
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                        
                        if !password.isEmpty && password.count < 8 {
                            Text("Password must be at least 8 characters")
                                .typography(Typography.caption)
                                .foregroundStyle(.red)
                        }
                        
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Passwords do not match")
                                .typography(Typography.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Terms and Privacy Policy
                    VStack(spacing: 12) {
                        Toggle(isOn: $agreedToTerms) {
                            Text("I agree to the Terms of Service and Privacy Policy")
                                .typography(Typography.subheadline)
                        }
                        
                        Button("View Privacy Policy") {
                            showingPrivacyPolicy = true
                        }
                        .typography(Typography.subheadline)
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .typography(Typography.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Register Button
                    Button(action: register) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create Account")
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? ColorTheme.primary : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 10))
                    .padding(.horizontal)
                    .disabled(!isFormValid || isLoading)
                    
                    // Sign In Link
                    Button("Already have an account? Sign In") {
                        dismiss()
                    }
                    .typography(Typography.subheadline)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
        }
    }
    
    private func register() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    privacyPolicyAccepted: agreedToTerms
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    RegisterView()
        .environment(AuthService())
}
