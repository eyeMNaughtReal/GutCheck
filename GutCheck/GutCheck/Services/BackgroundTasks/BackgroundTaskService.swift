import Foundation
import BackgroundTasks
import os.log

/// Manages background task scheduling and execution for pre-computing insights
/// while the app is suspended.
///
/// A second task used to run a Firestore sync. There is no remote store to sync
/// with any more — everything is written straight to the local SwiftData store
/// on save — so only the insights refresh remains.
final class BackgroundTaskService {
    static let shared = BackgroundTaskService()

    // MARK: - Task Identifiers

    static let insightsRefreshIdentifier = "com.gutcheck.insights-refresh"

    // MARK: - Cache Keys

    private enum CacheKey {
        static let cachedInsights = "backgroundTask.cachedInsights"
        static let lastInsightsRefresh = "backgroundTask.lastInsightsRefreshDate"
    }

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.gutcheck",
        category: "BackgroundTasks"
    )

    private init() {}

    // MARK: - Registration

    /// Register background task handlers. Must be called during app launch
    /// (in `application(_:didFinishLaunchingWithOptions:)`) before the app finishes launching.
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.insightsRefreshIdentifier,
            using: nil
        ) { task in
            self.handleInsightsRefresh(task: task as! BGProcessingTask)
        }

        logger.info("Registered background task handlers")
    }

    // MARK: - Scheduling

    /// Schedule all background tasks. Call when the app enters the background.
    func scheduleAllTasks() {
        scheduleInsightsRefresh()
    }

    /// Schedule the insights refresh processing task.
    /// Requires external power; targets overnight execution at 2 AM.
    func scheduleInsightsRefresh() {
        let request = BGProcessingTaskRequest(identifier: Self.insightsRefreshIdentifier)
        request.requiresExternalPower = true
        request.requiresNetworkConnectivity = false
        request.earliestBeginDate = nextScheduledDate(hour: 2)

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled insights refresh task")
        } catch {
            logger.error("Failed to schedule insights refresh: \(error.localizedDescription)")
        }
    }

    // MARK: - Task Handlers

    private func handleInsightsRefresh(task: BGProcessingTask) {
        logger.info("Starting insights refresh background task")

        // Schedule the next occurrence immediately
        scheduleInsightsRefresh()

        let computeTask = Task {
            await InsightsService.shared.generateRecentInsights()

            let insights = await MainActor.run {
                InsightsService.shared.recentInsights
            }

            cacheInsights(insights)
            logger.info("Insights refresh completed, cached \(insights.count) insights")
        }

        // Handle expiration — cancel the in-flight computation
        task.expirationHandler = { [weak self] in
            self?.logger.warning("Insights refresh task expired, cancelling")
            computeTask.cancel()
        }

        // Notify system when complete
        Task {
            _ = await computeTask.result
            task.setTaskCompleted(success: !computeTask.isCancelled)
        }
    }

    // MARK: - Cache Management

    private func cacheInsights(_ insights: [HealthInsight]) {
        do {
            let data = try JSONEncoder().encode(insights)
            UserDefaults.standard.set(data, forKey: CacheKey.cachedInsights)
            UserDefaults.standard.set(
                Date.now.timeIntervalSince1970,
                forKey: CacheKey.lastInsightsRefresh
            )
        } catch {
            logger.error("Failed to cache insights: \(error.localizedDescription)")
        }
    }

    /// Load previously cached insights from the background task.
    /// Returns `nil` if no cache exists or decoding fails.
    func loadCachedInsights() -> [HealthInsight]? {
        guard let data = UserDefaults.standard.data(forKey: CacheKey.cachedInsights) else {
            return nil
        }
        do {
            return try JSONDecoder().decode([HealthInsight].self, from: data)
        } catch {
            logger.error("Failed to decode cached insights: \(error.localizedDescription)")
            return nil
        }
    }

    /// The date when insights were last refreshed by a background task, if ever.
    var lastInsightsRefreshDate: Date? {
        let timestamp = UserDefaults.standard.double(forKey: CacheKey.lastInsightsRefresh)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    /// Clear all cached background task data.
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: CacheKey.cachedInsights)
        UserDefaults.standard.removeObject(forKey: CacheKey.lastInsightsRefresh)
    }

    // MARK: - Helpers

    /// Calculate the next occurrence of a specific hour (today if not yet passed, otherwise tomorrow).
    private func nextScheduledDate(hour: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date.now)
        components.hour = hour
        components.minute = 0

        if let date = calendar.date(from: components), date > Date.now {
            return date
        }

        // Past the target hour today — schedule for tomorrow
        components.day = (components.day ?? 0) + 1
        return calendar.date(from: components) ?? Date(timeIntervalSinceNow: 6 * 3600)
    }
}
