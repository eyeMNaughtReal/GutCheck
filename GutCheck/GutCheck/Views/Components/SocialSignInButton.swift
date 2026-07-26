//
//  SocialSignInButton.swift
//  GutCheck
//
//  Created by Mark Conley on 7/11/25.
//

import SwiftUI
import AuthenticationServices

struct SocialSignInButton: View {
    let provider: SignInProvider
    let action: () -> Void
    var isLoading: Bool = false
    
    enum SignInProvider {
        case apple
        case phone
        
        var title: String {
            switch self {
            case .apple:
                return "Continue with Apple"
            case .phone:
                return "Continue with Phone"
            }
        }
        
        var icon: String {
            switch self {
            case .apple:
                return "applelogo"
            case .phone:
                return "phone.fill"
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .apple:
                return Color.black
            case .phone:
                return ColorTheme.accent
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .apple:
                return Color.white
            case .phone:
                return ColorTheme.text
            }
        }
        
        var borderColor: Color {
            switch self {
            case .apple:
                return Color.clear
            case .phone:
                return Color.clear
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: provider.foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: provider.icon)
                        .font(.system(size: 18, weight: .medium))
                }
                
                Text(provider.title)
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(provider.backgroundColor)
            .foregroundStyle(provider.foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(provider.borderColor, lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
        }
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - Apple Sign In Button

struct AppleSignInButtonView: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .continue, style: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleAppleSignIn), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let parent: AppleSignInButtonView
        
        init(_ parent: AppleSignInButtonView) {
            self.parent = parent
        }
        
        @objc func handleAppleSignIn() {
            let logPrefix = "🍎 [SocialSignInButton]"
            NSLog("\(logPrefix) Starting Apple Sign-In process...")
            
            // Check if running on simulator
            #if targetEnvironment(simulator)
            NSLog("\(logPrefix) Running on simulator - Apple Sign-In may not work properly")
            #endif
            
            // Check entitlements
            NSLog("\(logPrefix) Checking entitlements...")
            
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            
            NSLog("\(logPrefix) Created authorization request")
            
            // Configure request with additional scopes
            request.requestedScopes = [.fullName, .email]
            
            // Call the onRequest callback to set up the request with nonce
            parent.onRequest(request)
            
            NSLog("\(logPrefix) Request configured with scopes: \(request.requestedScopes?.map(\.rawValue) ?? []), nonce: \(request.nonce?.prefix(10) ?? "nil")...")
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            NSLog("🍎 [SocialSignInButton] Performing authorization request...")
            
            // Save the attempt time for debugging
            UserDefaults.standard.set(Date.now, forKey: "lastAppleSignInRequestTime")
            
            controller.performRequests()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            NSLog("🍎 [SocialSignInButton] Apple Sign-In succeeded")
            
            
            
            parent.onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            NSLog("🍎 [SocialSignInButton] Apple Sign-In failed with error: \(error)")
            
            if let authError = error as? ASAuthorizationError {
                NSLog("🍎 [SocialSignInButton] ASAuthorizationError code: \(authError.code.rawValue)")
                
                NSLog("🍎 [SocialSignInButton] ASAuthorizationError description: \(authError.localizedDescription)")
                
                // Store error for debugging
                UserDefaults.standard.set(authError.code.rawValue, forKey: "lastAppleSignInErrorCode")
                UserDefaults.standard.set(authError.localizedDescription, forKey: "lastAppleSignInErrorMessage")
                
                // Check specific error codes
                switch authError.code {
                case .canceled:
                    NSLog("🍎 [SocialSignInButton] User canceled the authorization")
                case .failed:
                    NSLog("🍎 [SocialSignInButton] Authorization failed")
                case .invalidResponse:
                    NSLog("🍎 [SocialSignInButton] Invalid response received")
                case .notHandled:
                    NSLog("🍎 [SocialSignInButton] Authorization request not handled")
                case .unknown:
                    NSLog("🍎 [SocialSignInButton] Unknown authorization error")
                default:
                    NSLog("🍎 [SocialSignInButton] Other authorization error")
                }
            }
            
            parent.onCompletion(.failure(error))
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return UIWindow()
            }
            return window
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SocialSignInButton(provider: .apple, action: {})
        SocialSignInButton(provider: .phone, action: {})
        SocialSignInButton(provider: .apple, action: {}, isLoading: true)
    }
    .padding()
    .background(ColorTheme.background)
}
