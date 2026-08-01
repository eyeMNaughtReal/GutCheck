//
//  GutCheckApp.swift
//  GutCheck
//
//  Created by Mark Conley on 7/9/25.
//

import SwiftUI
import SwiftData
import UIKit
import UserNotifications
import BackgroundTasks
import CoreSpotlight

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Register as the notification delegate so banners appear while the
        // app is in the foreground and taps can be routed to the right screen
        UNUserNotificationCenter.current().delegate = self

        // Register background task handlers for pre-computed insights
        BackgroundTaskService.shared.registerBackgroundTasks()

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
    @State private var userService = LocalUserService.shared
    @State private var settingsVM = SettingsViewModel()
    @State private var swiftDataStack = SwiftDataStack.shared

    /// False until the one-time import of pre-SwiftData data has finished.
    ///
    /// There is no sign-in to wait behind any more, but showing the dashboard
    /// before the import lands would flash an empty history at an upgrading
    /// user. On a fresh install the import returns immediately.
    @State private var isMigrationComplete = false

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if isMigrationComplete {
                    AppRoot()
                        .environment(userService)
                        .environment(settingsVM)
                        .environment(TimeoutManager.shared)
                        .environment(swiftDataStack)
                } else {
                    ZStack {
                        ColorTheme.background
                            .ignoresSafeArea()
                        ProgressView()
                            .tint(ColorTheme.primary)
                    }
                }
            }
            .task {
                await LegacyStoreMigrator.shared.migrateIfNeeded()
                isMigrationComplete = true
            }
            .onChange(of: TimeoutManager.shared.shouldResetToHome) { _, shouldReset in
                if shouldReset {
                    // Reset navigation state and return to Dashboard tab
                    AppRouter.shared.resetToHome()
                    // Reset the timeout state
                    TimeoutManager.shared.resetTimeoutState()
                }
            }
            .onContinueUserActivity(CSSearchableItemActionType) { activity in
                guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
                      let parsed = SpotlightIndexingService.parseIdentifier(identifier) else {
                    return
                }
                switch parsed.type {
                case "meal":
                    AppRouter.shared.viewMealDetails(id: parsed.id)
                case "symptom":
                    AppRouter.shared.viewSymptomDetails(id: parsed.id)
                default:
                    break
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background:
                    TimeoutManager.shared.applicationDidEnterBackground()
                    BackgroundTaskService.shared.scheduleAllTasks()
                case .active:
                    TimeoutManager.shared.applicationWillEnterForeground()
                    Task { await HealthKitSyncManager.shared.syncIfNeeded() }
                    // Re-evaluate notifications in case Focus Filter state changed
                    Task { await ReminderSettingsService.shared.rescheduleNotificationsForFocusChange() }
                default:
                    break
                }
            }
            .preferredColorScheme(settingsVM.preferredColorScheme)
        }
        .modelContainer(swiftDataStack.container)
    }
}
