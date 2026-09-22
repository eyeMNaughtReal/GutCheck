//
//  VoiceMealLoggingViewModel.swift
//  GutCheck
//
//  Drives the speak → transcribe → extract → look up → clarify → confirm flow.
//
//  The same shape as PhotoFoodLoggingViewModel, and for the same reasons: the
//  model only ever contributes names and what was said about amounts, the
//  weights and nutrition come from a real lookup, and nothing is added to the
//  meal until the person confirms it.
//
//  What differs is the clarification step. A photo leaves everything uncertain
//  in the same way, so the photo flow asks one blanket question about
//  seasoning. Speech leaves specific, nameable gaps — which bread, how much of
//  the bag — and those are answerable with a picker seeded from real database
//  matches. Asking them as spoken follow-up questions would be an
//  interrogation; asking them as four taps on a screen is not.
//

import Foundation
import SwiftUI

// MARK: - Candidate

/// One spoken food, paired with whatever the database matched it to.
///
/// Distinct from `PhotoFoodCandidate` because the gaps differ. A photo
/// candidate is uncertain about everything equally; a spoken one knows exactly
/// what the speaker left out, and that is what the review screen asks about.
@Observable final class SpokenFoodCandidate: Identifiable {

    let id = UUID()

    /// What the speaker was heard to say. Retained after lookup so the row can
    /// show "you said X, logging Y" when the two differ.
    let spokenName: String

    /// The term actually searched for. Starts as the spoken name, with the
    /// brand folded in for a branded product, and can be corrected.
    var searchName: String

    /// True when the speaker did not say which variety this was — a bare
    /// "bread" rather than "sourdough". Turns the match picker from a silent
    /// default into an explicit question.
    let varietyWasSpecified: Bool

    /// The amount exactly as spoken, e.g. "half a 20oz". Shown verbatim so the
    /// person can see what was heard rather than only its consequence.
    let statedAmount: String?

    let amountCertainty: SpokenAmountCertainty

    /// How much of one serving was eaten, when the speaker said. Applied to
    /// `FoodItem.servingCount`, which scales a portion the database published
    /// — never a weight invented here.
    let fractionConsumed: Double?

    let portionHint: PortionHint

    let preference: FoodNamePreference

    let brandHint: String?

    var matches: [FoodSearchResult] = []
    var selectedItem: FoodItem?
    var isIncluded: Bool = true
    var lookupState: LookupState = .pending

    enum LookupState: Equatable {
        case pending
        case searching
        case matched
        /// Looked up and found nothing. The person can rename and retry.
        case noMatch
    }

    init(food: SpokenFood) {
        let brand = food.brand?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasBrand = (brand?.isEmpty == false)

        // The brand goes into the search term for a product, matching what the
        // photo flow does for a dish: the sources index packaged items under
        // the company name, so "lay's sour cream and onion" recalls a record
        // that the bare flavour name misses.
        let brandPrefix = (hasBrand && food.kind == .brandedProduct) ? "\(brand!) " : ""

        self.spokenName = brandPrefix + food.name
        self.searchName = brandPrefix + food.name
        self.varietyWasSpecified = food.varietyWasSpecified
        self.statedAmount = food.statedAmount
        self.amountCertainty = food.amountCertainty
        self.fractionConsumed = food.fractionConsumed
        self.portionHint = food.portionHint
        self.preference = (food.kind == .brandedProduct) ? .brandedDish : .genericIngredient
        self.brandHint = hasBrand ? brand : nil
    }

    /// True when this row is still waiting on an answer from the person.
    ///
    /// Two separate gaps, deliberately not merged: not knowing *which* food
    /// was eaten and not knowing *how much* are answered by different controls
    /// and have different consequences if guessed.
    var needsClarification: Bool {
        needsVarietyChoice || needsAmountAnswer
    }

    /// The speaker named a category rather than a food, and the database
    /// offered more than one reading of it.
    var needsVarietyChoice: Bool {
        !varietyWasSpecified && matches.count > 1
    }

    /// Something was said about the amount but it was not a measurement, or
    /// nothing was said at all. Either way the portion below is an assumption.
    var needsAmountAnswer: Bool {
        amountCertainty != .stated
    }

    /// The question to put at the top of the row.
    var clarificationPrompt: String? {
        if needsVarietyChoice {
            return "Which \(spokenName.lowercased())?"
        }
        if needsAmountAnswer {
            return amountCertainty == .vague
                ? "How much is “\(statedAmount ?? "that")”?"
                : "How much?"
        }
        return nil
    }

    var nameWasCorrected: Bool {
        searchName.trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedCaseInsensitiveCompare(spokenName) != .orderedSame
    }

    var matchDiffersFromSpeech: Bool {
        guard let selectedItem else { return false }
        return selectedItem.name.localizedCaseInsensitiveCompare(spokenName) != .orderedSame
    }
}

// MARK: - View Model

@MainActor
@Observable final class VoiceMealLoggingViewModel {

    // MARK: Phase

    enum Phase: Equatable {
        case ready
        case recording
        case extracting
        case reviewing
        /// Nothing usable came back. Carries the message to show before
        /// handing over to manual entry.
        case failed(message: String)
    }

    var phase: Phase = .ready

    // MARK: State

    /// What was heard. Editable on the review screen — a transcription slip is
    /// far easier to fix as text than by saying the whole meal again.
    var transcript: String = ""

    var candidates: [SpokenFoodCandidate] = []

    /// The meal the speaker named, if they named one.
    var mealType: MealType?

    /// True when a meal was named but no clock time was given, so the
    /// timestamp below is the app's assumption rather than the speaker's.
    var mealTimeWasAssumed: Bool = false

    /// When the meal is logged as having happened.
    ///
    /// Defaults to now and is shown on the review screen whenever it was
    /// assumed. "For lunch" implies a window, not an instant, and silently
    /// stamping it with the current time would put a meal eaten at noon into
    /// the evening — outside the window symptom correlation examines.
    var mealDate: Date = .now

    let capture = SpeechCaptureService()

    private let extractionService = SpokenMealExtractionService.shared
    private let searchService = FoodSearchService()

    /// Whether extraction can run at all. Checked before offering the
    /// affordance — the microphone working is not enough on its own.
    var isExtractionAvailable: Bool { extractionService.isAvailable }

    // MARK: - Recording

    func startRecording() async {
        transcript = ""
        candidates = []
        mealType = nil
        mealTimeWasAssumed = false

        if let reason = await capture.start() {
            phase = .failed(message: reason.message)
            return
        }

        phase = .recording
    }

    /// Ends recording and runs extraction on what was heard.
    func stopRecordingAndExtract() async {
        let heard = await capture.stop()
        transcript = heard

        guard !heard.isEmpty else {
            phase = .failed(message: "Didn't catch anything. Try again, or add the foods yourself.")
            return
        }

        await extract()
    }

    func cancelRecording() async {
        await capture.cancel()
        phase = .ready
    }

    // MARK: - Extraction

    /// Reads the current transcript into candidates and looks each one up.
    ///
    /// Separate from `stopRecordingAndExtract` so the review screen can re-run
    /// it after the person corrects a misheard word, without recording again.
    func extract() async {
        phase = .extracting

        let result = await extractionService.extract(from: transcript)

        switch result {
        case .extracted(let analysis):
            mealType = analysis.mealType?.mealType
            mealTimeWasAssumed = !analysis.timeWasStated
            candidates = analysis.foods.map(SpokenFoodCandidate.init(food:))
            phase = .reviewing
            await lookUpAllCandidates()

        case .noFoodsFound, .unavailable:
            // `userMessage` is non-nil for both of these.
            phase = .failed(message: result.userMessage ?? "Couldn't read that as a meal.")
        }
    }

    /// Looks up every candidate against the food database.
    ///
    /// Sequential rather than concurrent: `FoodSearchService` holds its results
    /// in an instance property, so parallel searches would overwrite each
    /// other's output.
    private func lookUpAllCandidates() async {
        for candidate in candidates {
            await lookUp(candidate)
        }
    }

    /// Resolves one candidate's `searchName` to database matches.
    ///
    /// Safe to call again after the person edits the name, which is the
    /// recovery path when a word was misheard.
    func lookUp(_ candidate: SpokenFoodCandidate) async {
        let query = candidate.searchName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            candidate.lookupState = .noMatch
            return
        }

        candidate.lookupState = .searching
        candidate.matches = []
        candidate.selectedItem = nil

        await searchService.searchFoods(query: query)
        let results = searchService.results

        guard !results.isEmpty else {
            candidate.lookupState = .noMatch
            return
        }

        candidate.matches = FoodMatchRanker.rank(
            results,
            against: query,
            preference: candidate.preference,
            brandHint: candidate.brandHint
        )
        candidate.selectedItem = foodItem(for: candidate.matches[0], candidate: candidate)
        candidate.lookupState = .matched
    }

    /// Switches a candidate to a different database match, keeping the spoken
    /// portion applied.
    func select(_ result: FoodSearchResult, for candidate: SpokenFoodCandidate) {
        candidate.selectedItem = foodItem(for: result, candidate: candidate)
    }

    /// Sets how many servings of the chosen match were eaten.
    ///
    /// This is the answer to "how much?" for a vague or unstated amount. It
    /// multiplies a serving the database published, so the result is still
    /// the source's own weight arithmetic rather than a number from here.
    func setServingCount(_ count: Double, for candidate: SpokenFoodCandidate) {
        guard var item = candidate.selectedItem, let serving = item.selectedServing else { return }
        item.servingCount = count
        item.quantity = serving.quantityDescription(count: count)
        candidate.selectedItem = item
    }

    /// Builds the `FoodItem` for a match, with the spoken portion applied.
    ///
    /// Two steps, in this order. The portion hint picks *which* of the
    /// source's servings to start from — see
    /// `PortionHint.preferredServing(from:default:)`. A spoken fraction then
    /// scales that serving. Neither step produces a gram weight of its own:
    /// the first chooses among weights the source published, and the second
    /// multiplies one of them by a number the person actually said.
    private func foodItem(for result: FoodSearchResult, candidate: SpokenFoodCandidate) -> FoodItem {
        var item = result.toFoodItem()

        guard let serving = candidate.portionHint.preferredServing(
            from: result.servingOptions,
            default: result.defaultServing
        ) else {
            return item
        }

        let count = candidate.fractionConsumed ?? 1

        item.selectedServing = serving
        item.servingCount = count
        item.quantity = serving.quantityDescription(count: count)
        return item
    }

    // MARK: - Committing

    var itemsToAdd: [FoodItem] {
        candidates
            .filter(\.isIncluded)
            .compactMap(\.selectedItem)
    }

    var canAddToMeal: Bool { !itemsToAdd.isEmpty }

    /// How many rows are still waiting on an answer.
    ///
    /// Surfaced rather than enforced: an unanswered row still logs, using the
    /// database's own default portion. Blocking the save would make an
    /// optional question mandatory, and someone who does not remember how much
    /// they ate should still be able to record that they ate it.
    var unresolvedCount: Int {
        candidates.filter { $0.isIncluded && $0.needsClarification }.count
    }

    /// Adds everything to the meal builder, along with the meal type and time.
    func addToMeal() {
        let builder = MealBuilderService.shared

        if let mealType {
            builder.mealType = mealType
        }
        builder.mealDate = mealDate

        for item in itemsToAdd {
            builder.addFoodItem(item)
        }
    }

    // MARK: - Reset

    func reset() {
        phase = .ready
        transcript = ""
        candidates = []
        mealType = nil
        mealTimeWasAssumed = false
        mealDate = .now
    }
}
