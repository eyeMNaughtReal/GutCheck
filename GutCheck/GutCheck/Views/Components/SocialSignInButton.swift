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

// MARK: - Apple Sign In Button Wrapper

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
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            parent.onRequest(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            parent.onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
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
