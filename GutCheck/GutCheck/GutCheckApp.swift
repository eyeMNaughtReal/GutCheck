//
//  GutCheckApp.swift
//  GutCheck
//
//  Created by Mark Conley on 7/9/25.
//

import SwiftUI
import FirebaseCore

@main
struct GutCheckApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var settingsVM = SettingsViewModel()
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                        .environmentObject(authService)
                        .environmentObject(settingsVM)
                } else {
                    AuthenticationView(authService: authService)
                }
            }
            .onAppear {
                // Any app startup logic
            }
            .preferredColorScheme(.light)
        }
    }
}
