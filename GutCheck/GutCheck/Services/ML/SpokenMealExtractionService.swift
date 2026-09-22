//
//  SpokenMealExtractionService.swift
//  GutCheck
//
//  Turns a spoken description of a meal into structured foods, using the
//  on-device Apple foundation model.
//
//  Scope, deliberately narrow — read before extending:
//
//  The model READS the sentence. It does not weigh anything and it does not
//  produce nutrition. Everything downstream comes from a real lookup against
//  USDA or OpenFoodFacts, exactly as in FoodPhotoIdentificationService.
//
//  What speech changes, and it is the whole reason this is worth building:
//  a photo carries no absolute scale, so the photo flow forbids the model from
//  ever stating a quantity. Speech has no such limit. "Half a 20 ounce" is an
//  actual measurement a person gave, and ServingSize.swift notes portion size
//  is among the stronger predictors of a post-meal symptom. So this model IS
//  allowed to report a quantity — but only one that was said out loud.
//
//  The line it must not cross is inventing one. "A couple handfuls" is not a
//  quantity; it becomes a clarification the person answers, never a silently
//  chosen gram weight. That is the same rule the photo flow follows, applied to
//  a different failure mode.
//
//  Nothing leaves the device.
//

import Foundation
import FoundationModels

// MARK: - Model Output

/// Which kind of database record a spoken food should resolve against.
///
/// The same split as `PhotoFoodCandidate.NamePreference`, decided here because
/// the speaker's own words are the best evidence for it. "Lay's sour cream and
/// onion" names a product; "turkey" names an ingredient. Getting this wrong
/// does not merely reorder the matches, it searches the wrong catalogue.
@Generable
enum SpokenFoodKind: String, Codable, CaseIterable {

    /// A packaged or chain product, wanted under its brand.
    case brandedProduct

    /// A plain ingredient, wanted as the generic entry.
    case ingredient
}

/// How firmly the speaker pinned down the amount.
///
/// Drives whether a portion is applied or asked about. The three cases are not
/// degrees of confidence — they are different kinds of answer, and only the
/// first one is usable as a measurement.
@Generable
enum SpokenAmountCertainty: String, Codable, CaseIterable {

    /// A real measurement was spoken: "half a 20 ounce", "two slices".
    case stated

    /// Something was said, but it is not a unit: "a couple handfuls", "some".
    case vague

    /// The speaker did not mention the amount at all.
    case unstated
}

/// One food the speaker described.
@Generable
struct SpokenFood {

    @Guide(description: "The food's plain name, without brand and without any amount. For a component of a homemade dish use the shortest name a nutrition database would hold: 'bread', 'turkey', 'cheddar cheese', 'mayonnaise'.")
    var name: String

    @Guide(description: "The brand or restaurant, if the speaker named one. Leave empty otherwise.")
    var brand: String?

    @Guide(description: "Whether this is a branded product the speaker named, or a plain ingredient.")
    var kind: SpokenFoodKind

    @Guide(description: "True only if the speaker said which variety or type this is. 'sourdough bread' is specified; a bare 'bread' is not. 'Turkey' with no preparation named is not specified.")
    var varietyWasSpecified: Bool

    @Guide(description: "Whether the speaker gave a real measurement, said something vague, or said nothing about how much.")
    var amountCertainty: SpokenAmountCertainty

    @Guide(description: "The amount exactly as the speaker said it, e.g. 'half a 20oz' or 'a couple handfuls'. Copy their words; do not convert or tidy them. Leave empty if they said nothing about amount.")
    var statedAmount: String?

    @Guide(description: "The size of the whole container or package if one was named, e.g. '20 fl oz' or '1.5 oz bag'. Leave empty if no container size was said.")
    var containerSize: String?

    @Guide(description: "How much of the container or serving was actually consumed, as a number between 0 and 1. 'Half' is 0.5, 'a third' is about 0.33. Leave empty unless the speaker said what fraction they had.")
    var fractionConsumed: Double?

    @Guide(description: "How large this portion sounds relative to a typical serving of this food. Half of something is a small portion.")
    var portionHint: PortionHint
}

/// The model's reading of one spoken meal.
///
/// Property order is load-bearing — `@Generable` properties are generated in
/// declaration order. `mealType` is asked first because the phrase that names
/// it ("for lunch…") almost always opens the sentence, and asking for it after
/// the food list made the model rationalise a meal type from the foods instead
/// of reporting the one that was said.
@Generable(description: "A meal that someone described out loud")
struct SpokenMealAnalysis {

    @Guide(description: "The meal the speaker named, if they named one: breakfast, lunch, dinner, snack or drink. Leave empty if they did not say.")
    var mealType: SpokenMealType?

    @Guide(description: "True only if the speaker gave an actual clock time, like 'at half past noon'. Naming a meal such as 'for lunch' is NOT a time.")
    var timeWasStated: Bool

    @Guide(description: "Every distinct food and drink mentioned. Break a homemade dish into its parts; keep a branded product whole.", .maximumCount(12))
    var foods: [SpokenFood]
}

/// Meal types the speaker can name.
///
/// Mirrors `MealType` rather than reusing it: `@Generable` needs the cases
/// spelled out for the model, and the app's enum is persisted, so the two
/// should be free to move independently.
@Generable
enum SpokenMealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
    case drink

    var mealType: MealType {
        switch self {
        case .breakfast: .breakfast
        case .lunch: .lunch
        case .dinner: .dinner
        case .snack: .snack
        case .drink: .drink
        }
    }
}

// MARK: - Result

/// What the service could make of a transcript.
enum SpokenMealExtractionResult: Sendable {

    /// The sentence yielded at least one food.
    case extracted(SpokenMealAnalysis)

    /// The model ran but found nothing loggable — silence, or a sentence that
    /// was not about food.
    case noFoodsFound

    /// No model to run: ineligible hardware, Apple Intelligence off, or the
    /// weights still downloading.
    case unavailable(reason: SystemLanguageModel.Availability.UnavailableReason?)

    /// Message to show the person. Every branch ends at manual entry, so the
    /// wording says so rather than presenting a dead end.
    var userMessage: String? {
        switch self {
        case .extracted:
            nil
        case .noFoodsFound:
            "Couldn't pick out any foods from that. Try naming them one at a time, or add them yourself."
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                "Speaking a meal needs Apple Intelligence, which this device doesn't support. You can still add foods yourself."
            case .appleIntelligenceNotEnabled:
                "Turn on Apple Intelligence in Settings to log a meal by speaking it. You can still add foods yourself."
            case .modelNotReady:
                "Apple Intelligence is still getting set up. Try again shortly, or add the foods yourself."
            case .none:
                "Speaking a meal isn't available right now. You can still add foods yourself."
            }
        }
    }
}

// MARK: - Service

/// Reads a spoken meal description into structured foods.
@MainActor
@Observable final class SpokenMealExtractionService {

    static let shared = SpokenMealExtractionService()

    private let model = SystemLanguageModel.default

    private init() {}

    var isAvailable: Bool { model.availability == .available }

    var unavailableReason: SystemLanguageModel.Availability.UnavailableReason? {
        guard case .unavailable(let reason) = model.availability else { return nil }
        return reason
    }

    /// Fixed at compile time and never built from user input.
    ///
    /// The transcript is passed as a prompt, not concatenated into these
    /// instructions, so nothing a person says can rewrite the task.
    private static let instructions = Instructions {
        """
        You read a sentence in which someone describes a meal they ate, and \
        list the foods so each one can be looked up in a nutrition database.

        DECOMPOSITION is the part that matters most.

        Break a homemade or assembled dish into the parts a database holds \
        separately. "A turkey and cheese sandwich with mayo" is four entries: \
        bread, turkey, cheese, mayonnaise. Never emit a combined name like \
        "turkey and cheese sandwich" — no nutrition database has a record \
        under that, so a combined name cannot be looked up at all.

        Keep a branded product whole, in the opposite way. "Lay's sour cream \
        and onion chips" is ONE entry, named "sour cream and onion chips" with \
        the brand "Lay's" — because the company's own record already accounts \
        for everything in the bag. Do not break a packaged product into \
        ingredients.

        The test is who assembled it. A person assembled a sandwich, so list \
        its parts. A company assembled a bag of chips, so keep it whole.

        AMOUNTS. Report only what was actually said.
        - If a real measurement was spoken, say so and copy their words \
        exactly: "half a 20oz", "two slices", "a tablespoon".
        - If they said something that sounds like an amount but is not a unit \
        — "a couple handfuls", "some", "a bit of" — mark it vague. Do NOT \
        convert it into a number of ounces, grams or cups. A guess here \
        corrupts the symptom analysis, which is worse than leaving it unknown.
        - If they said nothing about the amount, mark it unstated.
        - Never state a calorie count or any nutrition figure. Those come from \
        the database, not from you.

        VARIETY. Mark whether the speaker actually said which kind it was. \
        "Sourdough" is a specified bread; a bare "bread" is not. This decides \
        whether the app asks them which one they meant, so do not mark \
        something specified because the answer seems obvious to you.

        MEAL AND TIME. If they named a meal — "for lunch" — report it. That is \
        a meal, not a time: only mark the time as stated if they gave an \
        actual clock time.

        Omit anything you cannot name confidently. A short accurate list is \
        worth more than a long speculative one.
        """
    }

    /// Extracts the foods described in `transcript`.
    ///
    /// Never throws. Every failure resolves to `.noFoodsFound` or
    /// `.unavailable`, so the caller always has a path to manual entry.
    func extract(from transcript: String) async -> SpokenMealExtractionResult {
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { return .noFoodsFound }

        guard isAvailable else {
            return .unavailable(reason: unavailableReason)
        }

        let session = LanguageModelSession(instructions: Self.instructions)

        do {
            let response = try await session.respond(
                generating: SpokenMealAnalysis.self,
                // Greedy sampling: this is an extraction, so the most likely
                // reading of a fixed sentence is wanted every time rather than
                // a plausible variant that differs between runs on the same
                // words.
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                "Here is what the person said about their meal. List the foods."
                text
            }

            let analysis = response.content
            let usable = analysis.foods.filter {
                !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }

            guard !usable.isEmpty else { return .noFoodsFound }

            return .extracted(
                SpokenMealAnalysis(
                    mealType: analysis.mealType,
                    timeWasStated: analysis.timeWasStated,
                    foods: usable.map(Self.sanitized)
                )
            )
        } catch {
            // Guardrail violations, refusals, context overflow and unsupported
            // locales all mean the same thing here: nothing usable.
            return .noFoodsFound
        }
    }

    /// Enforces the rules the prompt asks for but cannot guarantee.
    ///
    /// The model is instructed never to invent a quantity, and mostly obeys.
    /// This makes it structural: a fraction that arrives alongside a vague or
    /// unstated amount is discarded rather than trusted, because there is no
    /// spoken measurement for it to be a fraction *of*. Leaving it in would
    /// scale a database serving by a number nobody said, which is precisely
    /// the fabricated portion the photo flow refuses to produce.
    private static func sanitized(_ food: SpokenFood) -> SpokenFood {
        var food = food

        if food.amountCertainty != .stated {
            food.fractionConsumed = nil
            food.containerSize = nil
        }

        // A fraction outside (0, 1] is not a fraction of anything. Zero would
        // mean they ate none of it, which is not something to log.
        if let fraction = food.fractionConsumed,
           !(fraction > 0 && fraction <= 1) || !fraction.isFinite {
            food.fractionConsumed = nil
        }

        food.brand = food.brand?.trimmingCharacters(in: .whitespacesAndNewlines)
        if food.brand?.isEmpty == true { food.brand = nil }

        return food
    }
}
