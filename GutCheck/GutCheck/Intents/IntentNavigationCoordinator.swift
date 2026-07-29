//
//  IntentNavigationCoordinator.swift
//  GutCheck
//
//  Bridges App Intents (Siri, Shortcuts, Spotlight) to in-app navigation.
//
//  An intent that needs confirmation or extra detail records the screen it wants
//  here, then the app root drains the request once the UI is on screen. The
//  request is persisted so it survives a cold launch: Siri can start the app
//  from scratch, and `perform()` may run before the window group exists.
//

import Foundation

// MARK: - Activity Types

/// `NSUserActivity` types used for Siri-initiated continuation into the app.
enum GutCheckActivityType {
    static let logMeal = "com.gutcheck.intent.logMeal"
    static let logSymptom = "com.gutcheck.intent.logSymptom"
    static let healthScore = "com.gutcheck.intent.healthScore"

    static let all = [logMeal, logSymptom, healthScore]
}

// MARK: - Routes

/// A screen an intent asked the app to open.
///
/// Stored as raw strings rather than app enums so the persisted payload stays
/// decodable across releases even if the underlying enums gain cases.
enum IntentRoute: Codable, Equatable, Sendable {
    /// Open the meal builder, optionally pre-loaded with a spoken food item.
    case logMeal(mealType: String, foodName: String?)
    /// Open the symptom logger, pre-filled with a spoken type and severity.
    case logSymptom(symptomType: String, severity: Int)
    /// Bring the user back to the dashboard, where the score lives.
    case dashboard
}

/// Values an intent captured for the symptom logger to adopt when it opens.
struct SymptomIntentPrefill: Equatable, Sendable {
    /// Raw value of a `SymptomType`.
    let symptomType: String
    /// 0–3, matching `PainLevel` / `UrgencyLevel` raw values.
    let severity: Int
}

// MARK: - Coordinator

@MainActor
@Observable final class IntentNavigationCoordinator {
    static let shared = IntentNavigationCoordinator()

    private enum Key {
        static let pendingRoute = "intents.pendingRoute"
    }

    /// Values the symptom logger picks up the next time it appears.
    /// In-memory only: it is consumed within the same launch that set it.
    private(set) var pendingSymptomPrefill: SymptomIntentPrefill?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Requesting

    /// Record a route for the app root to apply.
    ///
    /// Also retries shortly afterwards so an already-running app reacts
    /// immediately rather than waiting for the next scene activation.
    func request(_ route: IntentRoute) {
        if let data = try? JSONEncoder().encode(route) {
            defaults.set(data, forKey: Key.pendingRoute)
        }

        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            self?.applyPendingRoute()
        }
    }

    /// Handle a Siri-initiated `NSUserActivity` continuation.
    /// - Returns: `true` when the activity was recognised and routed.
    @discardableResult
    func handle(userActivity: NSUserActivity) -> Bool {
        switch userActivity.activityType {
        case GutCheckActivityType.logMeal:
            let mealType = userActivity.userInfo?["mealType"] as? String ?? MealType.lunch.rawValue
            let foodName = userActivity.userInfo?["foodName"] as? String
            request(.logMeal(mealType: mealType, foodName: foodName))
            return true

        case GutCheckActivityType.logSymptom:
            let symptomType = userActivity.userInfo?["symptomType"] as? String ?? SymptomType.other.rawValue
            let severity = userActivity.userInfo?["severity"] as? Int ?? 0
            request(.logSymptom(symptomType: symptomType, severity: severity))
            return true

        case GutCheckActivityType.healthScore:
            request(.dashboard)
            return true

        default:
            return false
        }
    }

    // MARK: - Applying

    /// Apply and clear any pending route. Safe to call repeatedly — the route is
    /// consumed before it is acted on, so duplicate calls are no-ops.
    func applyPendingRoute() {
        guard let route = consumePendingRoute() else { return }

        let router = AppRouter.shared

        switch route {
        case .logMeal(let mealTypeRaw, let foodName):
            let mealType = MealType(rawValue: mealTypeRaw) ?? .lunch
            let builder = MealBuilderService.shared
            builder.startNewMeal(type: mealType)

            if let foodName, !foodName.isEmpty {
                builder.mealName = foodName
                builder.setFoodItems([
                    FoodItem(name: foodName, quantity: "1 serving", source: .manual)
                ])
            }

            router.startMealLogging()

        case .logSymptom(let symptomTypeRaw, let severity):
            pendingSymptomPrefill = SymptomIntentPrefill(
                symptomType: symptomTypeRaw,
                severity: max(0, min(3, severity))
            )
            router.startSymptomLogging()

        case .dashboard:
            router.selectedTab = .dashboard
        }
    }

    /// Take ownership of the stored route, removing it from persistence.
    private func consumePendingRoute() -> IntentRoute? {
        guard let data = defaults.data(forKey: Key.pendingRoute) else { return nil }
        defaults.removeObject(forKey: Key.pendingRoute)
        return try? JSONDecoder().decode(IntentRoute.self, from: data)
    }

    /// Read and clear the symptom prefill. The logger calls this as it appears.
    func consumeSymptomPrefill() -> SymptomIntentPrefill? {
        defer { pendingSymptomPrefill = nil }
        return pendingSymptomPrefill
    }

    /// Drop anything queued — used on sign-out so a pending voice request never
    /// lands in the next user's session.
    func clear() {
        defaults.removeObject(forKey: Key.pendingRoute)
        pendingSymptomPrefill = nil
    }
}
