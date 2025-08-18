import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var currentPage = 0
    
    private let pages = [
        WelcomePage(
            title: "Welcome to GutCheck",
            subtitle: "Track, Monitor, Understand",
            description: "Your comprehensive companion for tracking meals and monitoring gut health.",
            imageName: "welcome-intro"
        ),
        WelcomePage(
            title: "Smart Meal Logging",
            subtitle: "Powered by LiDAR & AI",
            description: "Use advanced scanning technology to log meals quickly and accurately.",
            imageName: "welcome-meal"
        ),
        WelcomePage(
            title: "Health Insights",
            subtitle: "Personalized Analysis",
            description: "Discover patterns and receive AI-powered insights about your gut health.",
            imageName: "welcome-insights"
        )
    ]
    
    var body: some View {
        ZStack {
            ColorTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        WelcomePageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                if currentPage == pages.count - 1 {
                    VStack(spacing: 16) {
                        Button(action: { authViewModel.isShowingSignUp = true }) {
                            Text("Get Started")
                                .frame(maxWidth: .infinity)
                        }
                        .primaryButton()
                        
                        Button(action: { authViewModel.isShowingPhoneAuth = true }) {
                            Text("I already have an account")
                                .frame(maxWidth: .infinity)
                        }
                        .secondaryButton()
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }
            }
            .padding(.vertical, 30)
        }
    }
}

private struct WelcomePage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
}

private struct WelcomePageView: View {
    let page: WelcomePage
    
    var body: some View {
        VStack(spacing: 20) {
            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 250)
            
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(ColorTheme.text)
                
                Text(page.subtitle)
                    .font(.title2)
                    .foregroundColor(ColorTheme.primary)
                
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.text)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthenticationViewModel(authService: AuthService()))
}

// MARK: - Preview Helpers

private class MockAuthService: AuthenticationProtocol {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isPhoneVerificationInProgress = false
    @Published var currentUser: User?
    
    func signIn(email: String, password: String) async throws {}
    func signUp(email: String, password: String, firstName: String, lastName: String, privacyPolicyAccepted: Bool) async throws {}
    func sendPasswordReset(email: String) async throws {}
    func verifyPhoneNumber(_ phoneNumber: String) async throws {}
    func signInWithPhone(verificationCode: String) async throws {}
    func signOut() throws {}
}
