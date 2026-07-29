//
//  GutCheckIntents.swift
//  GutCheck
//
//  App Intents exposing GutCheck's core actions to Siri, the Shortcuts app and
//  Spotlight. Logging is voice-first by design: people frequently have their
//  hands full while cooking or eating.
//
//  App Intents requires iOS 16, so every type here carries an availability
//  guard even though the app's deployment target is higher.
//
//  Design note — which intents open the app:
//    • Meals and symptoms need detail the user can't reasonably dictate
//      (portions, Bristol type), so those intents open the relevant logging
//      screen pre-filled with whatever Siri captured.
//    • Water and the health score need no confirmation, so they complete
//      silently in the background and answer with a spoken dialog.
//

import AppIntents
import Foundation

// MARK: - Parameter Enums

@available(iOS 16.0, *)
enum MealTypeAppEnum: String, AppEnum {
    case breakfast
    case lunch
    case dinner
    case snack

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Meal Type")
    }

    static var caseDisplayRepresentations: [MealTypeAppEnum: DisplayRepresentation] {
        [
            .breakfast: DisplayRepresentation(title: "Breakfast"),
            .lunch: DisplayRepresentation(title: "Lunch"),
            .dinner: DisplayRepresentation(title: "Dinner"),
            .snack: DisplayRepresentation(title: "Snack")
        ]
    }

    /// The app's own meal model type.
    var mealType: MealType {
        switch self {
        case .breakfast: return .breakfast
        case .lunch: return .lunch
        case .dinner: return .dinner
        case .snack: return .snack
        }
    }

    var spokenName: String {
        rawValue
    }
}

@available(iOS 16.0, *)
enum SymptomTypeAppEnum: String, AppEnum {
    case bowelMovement
    case pain
    case bloating
    case nausea
    case urgency
    case other

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Symptom Type")
    }

    static var caseDisplayRepresentations: [SymptomTypeAppEnum: DisplayRepresentation] {
        [
            .bowelMovement: DisplayRepresentation(title: "Bowel Movement"),
            .pain: DisplayRepresentation(title: "Pain"),
            .bloating: DisplayRepresentation(title: "Bloating"),
            .nausea: DisplayRepresentation(title: "Nausea"),
            .urgency: DisplayRepresentation(title: "Urgency"),
            .other: DisplayRepresentation(title: "Other")
        ]
    }

    /// The app's own symptom model type.
    var symptomType: SymptomType {
        switch self {
        case .bowelMovement: return .bowelMovement
        case .pain: return .pain
        case .bloating: return .bloating
        case .nausea: return .nausea
        case .urgency: return .urgency
        case .other: return .other
        }
    }

    var spokenName: String {
        symptomType.rawValue.lowercased()
    }
}

/// Spoken description for a 0–3 severity value, matching `PainLevel` /
/// `UrgencyLevel` raw values.
enum SymptomSeverityWording {
    static func spokenName(for severity: Int) -> String {
        switch severity {
        case 0: return "no"
        case 1: return "mild"
        case 2: return "moderate"
        default: return "severe"
        }
    }
}

@available(iOS 16.0, *)
enum WaterUnitAppEnum: String, AppEnum {
    case ounces
    case milliliters

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Unit")
    }

    static var caseDisplayRepresentations: [WaterUnitAppEnum: DisplayRepresentation] {
        [
            .ounces: DisplayRepresentation(title: "fl oz"),
            .milliliters: DisplayRepresentation(title: "mL")
        ]
    }

    var abbreviation: String {
        switch self {
        case .ounces: return "fl oz"
        case .milliliters: return "mL"
        }
    }

    /// Convert an amount in this unit to millilitres, the unit HealthKit stores.
    func milliliters(from amount: Double) -> Double {
        switch self {
        case .ounces: return amount * 29.5735
        case .milliliters: return amount
        }
    }
}

// MARK: - Errors

@available(iOS 16.0, *)
enum GutCheckIntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case notSignedIn
    case saveFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notSignedIn:
            return "Open GutCheck and sign in first, then try again."
        case .saveFailed:
            return "GutCheck couldn't save that. Please try again."
        }
    }
}

// MARK: - Log Meal

@available(iOS 16.0, *)
struct LogMealIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a Meal"

    static var description = IntentDescription(
        "Opens GutCheck's meal builder, pre-filled with the meal type and food you mentioned.",
        categoryName: "Logging"
    )

    /// Portions, ingredients and time all need confirming, so this intent hands
    /// off to the meal builder rather than guessing.
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Meal Type", default: .lunch)
    var mealType: MealTypeAppEnum

    @Parameter(title: "Food")
    var foodName: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$foodName) as \(\.$mealType)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmedFood = foodName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let food = (trimmedFood?.isEmpty == false) ? trimmedFood : nil

        IntentNavigationCoordinator.shared.request(
            .logMeal(mealType: mealType.mealType.rawValue, foodName: food)
        )

        if let food {
            return .result(dialog: IntentDialog(
                stringLiteral: "Opening GutCheck to log \(food) as \(mealType.spokenName)."
            ))
        }

        return .result(dialog: IntentDialog(
            stringLiteral: "Opening GutCheck to log your \(mealType.spokenName)."
        ))
    }
}

// MARK: - Log Symptom

@available(iOS 16.0, *)
struct LogSymptomIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a Symptom"

    static var description = IntentDescription(
        "Opens GutCheck's symptom logger, pre-filled with the symptom and severity you mentioned.",
        categoryName: "Logging"
    )

    /// A symptom record needs a Bristol type, which isn't something people can
    /// sensibly dictate, so the logger opens for confirmation.
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Symptom", default: .pain)
    var symptomType: SymptomTypeAppEnum

    /// 0 = none, 3 = severe — matching `PainLevel` / `UrgencyLevel` raw values.
    @Parameter(title: "Severity", default: 2, inclusiveRange: (0, 3))
    var severity: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$symptomType) with severity \(\.$severity)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let clampedSeverity = max(0, min(3, severity))

        IntentNavigationCoordinator.shared.request(
            .logSymptom(
                symptomType: symptomType.symptomType.rawValue,
                severity: clampedSeverity
            )
        )

        let wording = SymptomSeverityWording.spokenName(for: clampedSeverity)
        return .result(dialog: IntentDialog(
            stringLiteral: "Opening GutCheck to log \(wording) \(symptomType.spokenName)."
        ))
    }
}

// MARK: - Health Score

@available(iOS 16.0, *)
struct GetHealthScoreIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Today's Health Score"

    static var description = IntentDescription(
        "Reports today's GutCheck health score out of 10.",
        categoryName: "Insights"
    )

    /// Answers out loud without interrupting whatever the user is doing.
    static var openAppWhenRun: Bool = false

    /// A snapshot written this recently is treated as current, which keeps the
    /// spoken answer fast instead of waiting on a round trip to Firestore.
    private static let freshnessWindow: TimeInterval = 15 * 60

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let answer = await Self.currentScoreDescription()
        return .result(value: answer, dialog: IntentDialog(stringLiteral: answer))
    }

    /// Prefer a recent widget snapshot, fall back to a live calculation, and
    /// fall back again to the stale snapshot if the network is unavailable.
    @MainActor
    private static func currentScoreDescription() async -> String {
        let cached = WidgetDataStore.shared.load()

        if let cached, Date.now.timeIntervalSince(cached.updatedAt) < freshnessWindow {
            return phrase(score: cached.healthScore, trend: cached.trend)
        }

        do {
            let summary = try await HealthScoreService.shared.summary()
            WidgetSyncService.shared.scheduleRefresh()

            let trend: WidgetScoreTrend
            if let previous = summary.previousScore {
                trend = summary.score > previous ? .up : (summary.score < previous ? .down : .steady)
            } else {
                trend = .steady
            }
            return phrase(score: summary.score, trend: trend)
        } catch {
            if let cached {
                return phrase(score: cached.healthScore, trend: cached.trend)
            }
            return "GutCheck doesn't have enough data for a score yet. Log a meal or a symptom to get started."
        }
    }

    private static func phrase(score: Int, trend: WidgetScoreTrend) -> String {
        let descriptor = HealthScoreCalculator.descriptor(for: score)
        switch trend {
        case .up:
            return "Your gut health score today is \(score) out of 10 — \(descriptor), and up from yesterday."
        case .down:
            return "Your gut health score today is \(score) out of 10 — \(descriptor), and down from yesterday."
        case .steady:
            return "Your gut health score today is \(score) out of 10 — \(descriptor)."
        }
    }
}

// MARK: - Log Water

@available(iOS 16.0, *)
struct LogWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Water"

    static var description = IntentDescription(
        "Logs water intake in GutCheck and writes it to Apple Health.",
        categoryName: "Logging"
    )

    /// Nothing to confirm — this completes without pulling the user out of
    /// whatever they were doing.
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Amount", default: 8.0)
    var amount: Double

    @Parameter(title: "Unit", default: .ounces)
    var unit: WaterUnitAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) \(\.$unit) of water")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount > 0 else {
            return .result(dialog: "Tell me how much water to log, for example eight ounces.")
        }

        guard let userId = AuthenticationManager.shared.currentUserId else {
            throw GutCheckIntentError.notSignedIn
        }

        let milliliters = unit.milliliters(from: amount)
        let formattedAmount = amount.formatted(.number.precision(.fractionLength(0...1)))

        let waterItem = FoodItem(
            name: "Water",
            quantity: "\(formattedAmount) \(unit.abbreviation)",
            estimatedWeightInGrams: milliliters,
            nutrition: NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0),
            source: .manual
        )

        let meal = Meal(
            name: "Water",
            date: Date.now,
            type: .drink,
            source: .manual,
            foodItems: [waterItem],
            tags: ["water", "hydration"],
            createdBy: userId
        )

        do {
            try await MealRepository.shared.save(meal)
        } catch {
            throw GutCheckIntentError.saveFailed
        }

        // Mirror the app's own save flow: index for Spotlight, push to Apple
        // Health, refresh dependent UI and republish the widget snapshot.
        SpotlightIndexingService.shared.indexMeal(meal)

        HealthKitManager.shared.writeWaterIntakeToHealthKit(amount: milliliters) { _, _ in }

        DataSyncManager.shared.triggerRefreshAfterSave(operation: "Siri water log", dataType: .meals)
        WidgetSyncService.shared.scheduleRefresh()

        return .result(dialog: IntentDialog(
            stringLiteral: "Logged \(formattedAmount) \(unit.abbreviation) of water."
        ))
    }
}
