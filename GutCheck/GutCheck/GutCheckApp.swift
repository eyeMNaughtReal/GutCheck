//
//  GutCheckApp.swift
//  GutCheck
//
//  Created by Mark Conley on 7/9/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct GutCheckApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var settingsVM = SettingsViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        FirebaseApp.configure()
        
        // Configure Firestore settings to prevent connection issues
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        
        // Use modern cache settings instead of deprecated properties
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
        
        // Set a reasonable timeout
        settings.dispatchQueue = DispatchQueue.global(qos: .userInitiated)
        
        db.settings = settings
        
        print("🔥 Firebase configured with Firestore settings")
        
        // Test basic Firebase connectivity
        Task {
            await Self.testFirebaseConnection()
        }
    }
    
    static private func testFirebaseConnection() async {
        do {
            let db = Firestore.firestore()
            let testDoc = db.collection("test").document("connection")
            let _ = try await testDoc.getDocument()
            print("✅ Firebase connection test successful")
        } catch {
            print("❌ Firebase connection test failed: \(error)")
            print("❌ This suggests a configuration issue with GoogleService-Info.plist")
        }
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
