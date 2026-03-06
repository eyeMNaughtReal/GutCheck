//
//  GutCheckApp.swift
//  GutCheck
//
//  Created by Mark Conley on 7/9/25.
//

import SwiftUI
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseFirestore

// Configure Firebase before the app starts
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        #if DEBUG
        // Run diagnostics in debug mode to help identify configuration issues
        FirebaseDiagnostics.runDiagnostics()
        #endif

        // Configure Firebase - try automatic configuration first
        if FirebaseApp.app() == nil {
            // Check if GoogleService-Info.plist exists
            if let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
                print("✅ Found GoogleService-Info.plist at: \(plistPath)")
                FirebaseApp.configure()
            } else {
                // TEMPORARY: Manual configuration if plist is missing
                print("⚠️ GoogleService-Info.plist not found!")
                print("⚠️ Please add GoogleService-Info.plist to your project")
                print("⚠️ Download it from: https://console.firebase.google.com/")

                // You can add manual configuration here as a temporary workaround:
                // let options = FirebaseOptions(googleAppID: "1:123:ios:abc",
                //                               gcmSenderID: "123")
                // options.apiKey = "your-api-key"
                // options.projectID = "your-project-id"
                // FirebaseApp.configure(options: options)

                fatalError("GoogleService-Info.plist is required. Please download it from Firebase Console and add it to your project.")
            }
        }

        // Configure Firestore settings to prevent connection issues
        let db = Firestore.firestore()
        let settings = FirestoreSettings()

        // Use modern cache settings instead of deprecated properties.
        // Cap at 100 MB to prevent unbounded local disk growth.
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: 100 * 1024 * 1024))

        // Set a reasonable timeout
        settings.dispatchQueue = DispatchQueue.global(qos: .userInitiated)

        db.settings = settings

        print("🔥 Firebase configured with Firestore settings")

        // Register as the notification delegate so banners appear while the
        // app is in the foreground and taps can be routed to the right screen
        UNUserNotificationCenter.current().delegate = self

        // Test basic Firebase connectivity
        Task {
            await GutCheckApp.testFirebaseConnection()
        }

        return true
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show banner + play sound even when the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Deep-link to the appropriate screen when the user taps a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        let router = AppRouter.shared

        Task { @MainActor in
            switch true {
            case identifier == "breakfastReminder",
                 identifier == "lunchReminder",
                 identifier == "dinnerReminder":
                router.startMealLogging()

            case identifier == "symptomReminder",
                 identifier.hasPrefix("symptomReminder_"):   // covers "Remind Me Later"
                router.startSymptomLogging()

            case identifier == "medicationReminder":
                router.selectedTab = .medications

            case identifier == "weeklyInsight",
                 identifier == "newInsights",
                 identifier == "patternAlert":
                router.selectedTab = .insights

            default:
                break
            }
        }

        completionHandler()
    }
}

@main
struct GutCheckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = AuthService()
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var coreDataStack = CoreDataStack.shared
    @StateObject private var localStorage = CoreDataStorageService.shared
    @StateObject private var dataSyncService = DataSyncService.shared
    @Environment(\.scenePhase) private var scenePhase
    
    static func testFirebaseConnection() async {
        do {
            let testDoc = FirebaseManager.shared.testDocument("connection")
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
                if !authService.isAuthStateResolved {
                    // Show loading while Firebase restores auth session
                    ZStack {
                        ColorTheme.background
                            .ignoresSafeArea()
                        ProgressView()
                            .tint(ColorTheme.primary)
                    }
                } else if authService.isAuthenticated {
                    AppRoot()
                        .environmentObject(authService)
                        .environmentObject(settingsVM)
                        .environmentObject(TimeoutManager.shared)
                        .environmentObject(coreDataStack)
                        .environmentObject(localStorage)
                        .environmentObject(dataSyncService)
                } else if authService.isAwaitingEmailVerification {
                    EmailVerificationView(authService: authService)
                } else {
                    AuthenticationView(authService: authService)
                }
            }
            .onChange(of: TimeoutManager.shared.shouldResetToHome) { _, shouldReset in
                if shouldReset {
                    // Reset navigation state
                    AppRouter.shared.navigateToRoot()
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
                    Task { await HealthKitSyncManager.shared.syncIfNeeded() }
                default:
                    break
                }
            }
            .preferredColorScheme(settingsVM.preferredColorScheme)
        }
    }
}
