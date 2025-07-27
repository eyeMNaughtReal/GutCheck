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
    @Environment(\.scenePhase) private var scenePhase
    
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
                        .environmentObject(TimeoutManager.shared)
                } else {
                    AuthenticationView(authService: authService)
                }
            }
            .onChange(of: TimeoutManager.shared.shouldResetToHome) { _, shouldReset in
                if shouldReset {
                    // Reset navigation state
                    NavigationCoordinator.shared.resetToRoot()
                    // Reset the timeout state
                    TimeoutManager.shared.resetTimeoutState()
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                switch newPhase {
                case .background:
                    TimeoutManager.shared.applicationDidEnterBackground()
                case .active:
                    TimeoutManager.shared.applicationWillEnterForeground()
                default:
                    break
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
