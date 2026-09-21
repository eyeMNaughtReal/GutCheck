//
//  FoodPhotoIdentificationService.swift
//  GutCheck
//
//  Identifies the foods on a plate from a photo using the on-device Apple
//  foundation model.
//
//  Scope, deliberately narrow — read before extending:
//
//  The model NAMES foods. It does not weigh them and it does not produce
//  nutrition. Everything downstream comes from a real lookup against USDA or
//  OpenFoodFacts, which is where gram weights and nutrition live.
//
//  A single photo carries no absolute scale: a child's portion and a
//  restaurant portion of the same pasta are the same image up to zoom. So the
//  model is never asked for grams or calories. It may offer a coarse
//  small/medium/large hint, which is used only to preselect one of the
//  portions the food source itself provided — never to invent a weight.
//  ServingSize.swift makes the stakes explicit: portion size is one of the
//  stronger predictors of a post-meal symptom, so a fabricated gram value
//  would corrupt trigger analysis, not just a displayed number.
//
//  Nothing leaves the device. When the on-device model cannot identify the
//  plate, the flow reports that and hands over to manual entry rather than
//  escalating to Private Cloud Compute.
//

import Foundation
import FoundationModels
import UIKit

// MARK: - Model Output

/// How sure the model is about a name it produced.
@Generable
enum FoodIdentificationConfidence: String, Codable, CaseIterable {
    case high
    case medium
    case low
}

/// A coarse portion impression.
///
/// Three buckets on purpose. Anything finer implies a measurement the photo
/// cannot support, and these map onto portions the food source already
/// published rather than to weights of their own.
@Generable
enum PortionHint: String, Codable, CaseIterable {
    case small
    case medium
    case large

    var label: String {
        switch self {
        case .small: "Looks like a small portion"
        case .medium: "Looks like a regular portion"
        case .large: "Looks like a large portion"
        }
    }
}

/// One food the model believes is on the plate.
@Generable
struct IdentifiedFood {
    @Guide(description: "Common name of the food, e.g. 'grilled chicken breast' or 'white rice'. No brand unless it is clearly legible in the photo.")
    var name: String

    @Guide(description: "How confident you are that this food is present and correctly named.")
    var confidence: FoodIdentificationConfidence

    @Guide(description: "How large this portion looks relative to a typical serving of this food.")
    var portionHint: PortionHint
}

/// A single named dish that accounts for the whole plate.
///
/// Distinct from `IdentifiedFood` because a dish resolves against the database
/// differently: the brand is wanted rather than avoided, and a hit returns the
/// composed nutrition of the entire item instead of one ingredient's.
@Generable
struct IdentifiedDish {
    @Guide(description: "The ordinary name of the dish, e.g. 'mexican pizza', 'pad thai', 'lasagna'. Two or three words at most.")
    var name: String

    @Guide(description: "The restaurant or company that makes this dish, if you can tell. Leave empty if you cannot.")
    var brand: String?

    @Guide(description: "How confident you are that the plate is this dish.")
    var confidence: FoodIdentificationConfidence

    @Guide(description: "How large this serving looks relative to a typical serving of this dish. A half portion is small.")
    var portionHint: PortionHint
}

/// The model's reading of one plate photo.
///
/// Property order is load-bearing. The model generates `@Generable` properties
/// in declaration order, so `dish` is asked first deliberately: when the array
/// of ingredients is generated first the model commits to a decomposition and
/// never reconsiders the plate as a whole. Photographing half a Taco Bell
/// Mexican Pizza returned "tortilla" and "tomato" for exactly that reason.
@Generable(description: "The food visible in a photograph of a meal")
struct PlateAnalysis {
    @Guide(description: "The single named dish this plate is, if it is a recognizable one. Leave empty if the plate is separate foods rather than one dish.")
    var dish: IdentifiedDish?

    @Guide(description: "Each distinct food you can see. Fill this in whether or not you named a dish. Omit anything you cannot name confidently.", .maximumCount(8))
    var foods: [IdentifiedFood]

    @Guide(description: "True if seasoning, spice, sauce or dressing appears to be present but you cannot identify what it is.")
    var hasUnidentifiedSeasoning: Bool
}

// MARK: - Result

/// What the service could tell the caller about a photo.
enum FoodPhotoIdentificationResult: Sendable {

    /// Something was named. `hasUnidentifiedSeasoning` asks the UI to offer a
    /// free-text field, because seasonings are usually invisible to a photo yet
    /// matter to trigger analysis — FoodCompoundDatabase carries cayenne,
    /// chili, cumin, garlic, paprika and cinnamon.
    ///
    /// `dish` and `foods` are alternatives, not additions: logging both would
    /// double-count the plate. The caller prefers the dish when it resolves to
    /// a database entry and falls back to the loose foods when it does not.
    case identified(
        dish: IdentifiedDish?,
        foods: [IdentifiedFood],
        hasUnidentifiedSeasoning: Bool
    )

    /// The model ran but named nothing usable. The caller should say so and
    /// fall back to manual entry.
    case couldNotIdentify

    /// No model to run: ineligible hardware, Apple Intelligence switched off,
    /// or the weights still downloading.
    case unavailable(reason: SystemLanguageModel.Availability.UnavailableReason?)

    /// Message to show the person. Every branch ends at manual entry, so the
    /// wording says that rather than presenting a dead end.
    var userMessage: String? {
        switch self {
        case .identified:
            nil
        case .couldNotIdentify:
            "Couldn't identify the food in this photo well enough to log it. Try a clearer photo, or add the items yourself."
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                "Photo identification needs Apple Intelligence, which this device doesn't support. You can still add items yourself."
            case .appleIntelligenceNotEnabled:
                "Turn on Apple Intelligence in Settings to identify food from a photo. You can still add items yourself."
            case .modelNotReady:
                "Apple Intelligence is still getting set up. Try again shortly, or add the items yourself."
            case .none:
                "Photo identification isn't available right now. You can still add items yourself."
            }
        }
    }
}

// MARK: - Service

/// Names the foods in a plate photo using the on-device model.
@MainActor
@Observable final class FoodPhotoIdentificationService {

    static let shared = FoodPhotoIdentificationService()

    private let model = SystemLanguageModel.default

    private init() {}

    /// Whether identification can run right now.
    ///
    /// Worth checking before showing the camera affordance at all: a supported
    /// OS is not enough, because the hardware may be ineligible or Apple
    /// Intelligence switched off.
    var isAvailable: Bool { model.availability == .available }

    /// Why identification is unavailable, for messaging.
    var unavailableReason: SystemLanguageModel.Availability.UnavailableReason? {
        guard case .unavailable(let reason) = model.availability else { return nil }
        return reason
    }

    /// Fixed at compile time and never built from user input, so nothing in a
    /// photo can rewrite the task.
    private static let instructions = Instructions {
        """
        You identify food in a photograph of a meal so it can be looked up in \
        a nutrition database.

        Answer in two passes, in this order.

        FIRST, the dish. Decide whether the whole plate is one recognizable \
        named dish — a lasagna, a pad thai, a mexican pizza, a cheeseburger. \
        If it is, give its ordinary name, and name the restaurant or company \
        if you can tell which one it is, either from visible packaging or \
        because the dish itself is distinctive to that chain. Give a brand \
        only when you actually recognize it; leave it empty otherwise.

        Naming the dish is the most useful thing you can do. The database \
        holds whole dishes, including the parts hidden inside that a photo \
        never shows, so one dish name is worth more than a list of the few \
        toppings visible on top of it.

        Leave the dish empty when the plate is genuinely separate foods, like \
        a chicken breast next to rice and broccoli. Do not force unrelated \
        foods into one dish name.

        SECOND, the visible foods. List them whether or not you named a dish.
        - Name only foods you can actually see. Do not guess at what a dish \
        probably contains, and do not list ingredients you cannot see.
        - One food per entry. Never combine two foods into a single name. \
        "chicken with peppers" is wrong — list "chicken" and "peppers" as \
        separate entries. A combined name cannot be looked up.
        - Use the shortest plain name a nutrition database would hold: \
        "chicken breast", "brown rice", "tomato". Leave out adjectives about \
        size or colour, and leave the brand off these — brands belong on the \
        dish, not on a plain ingredient.
        - Omit any food you cannot name confidently. A short accurate list is \
        worth more than a long speculative one.

        For both passes:
        - Never state a weight, a calorie count or any nutrition figure. \
        Portion is a coarse impression only. Half of something is a small \
        portion.
        - If seasoning, spice, sauce or dressing seems present but you cannot \
        tell what it is, say so with the seasoning flag rather than guessing a \
        name.
        """
    }

    /// Identifies the foods in `image`.
    ///
    /// Never throws. Every failure resolves to `.couldNotIdentify` or
    /// `.unavailable` so the caller always has a path to manual entry.
    func identifyFoods(in image: UIImage) async -> FoodPhotoIdentificationResult {
        guard isAvailable else {
            return .unavailable(reason: unavailableReason)
        }

        let session = LanguageModelSession(instructions: Self.instructions)

        do {
            let response = try await session.respond(
                generating: PlateAnalysis.self,
                // Greedy sampling: this is a classification, so the most
                // likely reading is wanted every time rather than a plausible
                // near-miss that varies between runs on the same photo.
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                "Identify the foods in this photograph of a meal."
                Attachment(image)
            }

            let analysis = response.content
            let usable = analysis.foods.filter { food in
                !food.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && food.confidence != .low
            }

            // Held to the same confidence bar as the foods. A low-confidence
            // dish name is worse than none: it would suppress the ingredient
            // list that the fallback depends on.
            let dish = analysis.dish.flatMap { dish -> IdentifiedDish? in
                let name = dish.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, dish.confidence != .low else { return nil }
                return dish
            }

            // Low-confidence-only output is a failure to identify, not a
            // result. Presenting it would put guesses in front of someone who
            // cannot tell them apart from recognitions.
            guard dish != nil || !usable.isEmpty else {
                return .couldNotIdentify
            }

            return .identified(
                dish: dish,
                foods: usable,
                hasUnidentifiedSeasoning: analysis.hasUnidentifiedSeasoning
            )
        } catch {
            // Guardrail violations, refusals, context overflow and unsupported
            // locales all mean the same thing here: no usable identification.
            return .couldNotIdentify
        }
    }
}

// MARK: - Applying a Portion Hint

extension PortionHint {

    /// Picks one of the portions the food source published, guided by the hint.
    ///
    /// This is the whole of the hint's influence. It reorders a choice the
    /// source already made; it never produces a gram weight of its own, and it
    /// returns nil when the source offered nothing to choose from.
    ///
    /// The hint moves one step from the source's default rather than jumping
    /// to the extremes of the list. Taking the absolute lightest option put
    /// "1 fl oz (with ice) · 23 g" on a cooked green pepper: USDA carries
    /// measures that make no sense for a given food, and they cluster at the
    /// ends. One step from the default stays near what the source itself
    /// considers a normal portion.
    ///
    /// `.medium` keeps the default outright — it already encodes "one normal
    /// portion of this food", which is exactly what medium means.
    func preferredServing(
        from options: [ServingOption],
        default defaultServing: ServingOption?
    ) -> ServingOption? {
        guard !options.isEmpty else { return defaultServing }

        let byWeight = options.sorted { $0.gramWeight < $1.gramWeight }

        // With no default there is no reference point to step from, so fall
        // back to the middle of the list and let the person adjust.
        guard let reference = defaultServing else {
            switch self {
            case .small: return byWeight.first
            case .large: return byWeight.last
            case .medium: return byWeight[byWeight.count / 2]
            }
        }

        switch self {
        case .medium:
            return reference
        case .small:
            // Heaviest option still lighter than the default: the next size
            // down, not the smallest thing in the list.
            return byWeight.last { $0.gramWeight < reference.gramWeight } ?? reference
        case .large:
            return byWeight.first { $0.gramWeight > reference.gramWeight } ?? reference
        }
    }
}
