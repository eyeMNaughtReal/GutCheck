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
            .foregroundColor(provider.foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(provider.borderColor, lineWidth: 1)
            )
            .cornerRadius(12)
            .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
        }
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - Apple Sign In Button (Commented out for future integration)
/*
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
            print("\(logPrefix) Starting Apple Sign-In process...")
            NSLog("\(logPrefix) Starting Apple Sign-In process...")
            
            // Check if running on simulator
            #if targetEnvironment(simulator)
            print("\(logPrefix) Running on simulator - Apple Sign-In may not work properly")
            NSLog("\(logPrefix) Running on simulator - Apple Sign-In may not work properly")
            #endif
            
            // Check entitlements
            print("\(logPrefix) Checking entitlements...")
            NSLog("\(logPrefix) Checking entitlements...")
            
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            
            print("\(logPrefix) Created authorization request")
            NSLog("\(logPrefix) Created authorization request")
            
            // Configure request with additional scopes
            request.requestedScopes = [.fullName, .email]
            
            // Call the onRequest callback to set up the request with nonce
            parent.onRequest(request)
            
            print("\(logPrefix) Request configured with scopes: \(request.requestedScopes?.map(\.rawValue) ?? []), nonce: \(request.nonce?.prefix(10) ?? "nil")...")
            NSLog("\(logPrefix) Request configured with scopes: \(request.requestedScopes?.map(\.rawValue) ?? []), nonce: \(request.nonce?.prefix(10) ?? "nil")...")
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            print("🍎 [SocialSignInButton] Performing authorization request...")
            NSLog("🍎 [SocialSignInButton] Performing authorization request...")
            
            // Save the attempt time for debugging
            UserDefaults.standard.set(Date(), forKey: "lastAppleSignInRequestTime")
            
            controller.performRequests()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            print("🍎 [SocialSignInButton] Apple Sign-In succeeded")
            NSLog("🍎 [SocialSignInButton] Apple Sign-In succeeded")
            
            // Examine the authorization details
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                print("🍎 [SocialSignInButton] Apple user identifier: \(userID)")
                NSLog("🍎 [SocialSignInButton] Apple user identifier: \(userID)")
                
                if let identityToken = appleIDCredential.identityToken {
                    print("🍎 [SocialSignInButton] Identity token present, length: \(identityToken.count)")
                    NSLog("🍎 [SocialSignInButton] Identity token present, length: \(identityToken.count)")
                } else {
                    print("🍎 [SocialSignInButton] ⚠️ No identity token in credential!")
                    NSLog("🍎 [SocialSignInButton] ⚠️ No identity token in credential!")
                }
            }
            
            parent.onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            print("🍎 [SocialSignInButton] Apple Sign-In failed with error: \(error)")
            NSLog("🍎 [SocialSignInButton] Apple Sign-In failed with error: \(error)")
            
            if let authError = error as? ASAuthorizationError {
                print("🍎 [SocialSignInButton] ASAuthorizationError code: \(authError.code.rawValue)")
                NSLog("🍎 [SocialSignInButton] ASAuthorizationError code: \(authError.code.rawValue)")
                
                print("🍎 [SocialSignInButton] ASAuthorizationError description: \(authError.localizedDescription)")
                NSLog("🍎 [SocialSignInButton] ASAuthorizationError description: \(authError.localizedDescription)")
                
                // Store error for debugging
                UserDefaults.standard.set(authError.code.rawValue, forKey: "lastAppleSignInErrorCode")
                UserDefaults.standard.set(authError.localizedDescription, forKey: "lastAppleSignInErrorMessage")
                
                // Check specific error codes
                switch authError.code {
                case .canceled:
                    print("🍎 [SocialSignInButton] User canceled the authorization")
                    NSLog("🍎 [SocialSignInButton] User canceled the authorization")
                case .failed:
                    print("🍎 [SocialSignInButton] Authorization failed")
                    NSLog("🍎 [SocialSignInButton] Authorization failed")
                case .invalidResponse:
                    print("🍎 [SocialSignInButton] Invalid response received")
                    NSLog("🍎 [SocialSignInButton] Invalid response received")
                case .notHandled:
                    print("🍎 [SocialSignInButton] Authorization request not handled")
                    NSLog("🍎 [SocialSignInButton] Authorization request not handled")
                case .unknown:
                    print("🍎 [SocialSignInButton] Unknown authorization error")
                    NSLog("🍎 [SocialSignInButton] Unknown authorization error")
                default:
                    print("🍎 [SocialSignInButton] Other authorization error")
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
*/

#Preview {
    VStack(spacing: 16) {
        SocialSignInButton(provider: .apple, action: {})
        SocialSignInButton(provider: .phone, action: {})
        SocialSignInButton(provider: .apple, action: {}, isLoading: true)
    }
    .padding()
    .background(ColorTheme.background)
}
