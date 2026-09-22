//
//  PhotoFoodLoggingViewModel.swift
//  GutCheck
//
//  Drives the photo → identify → look up → confirm flow for logging a meal.
//
//  The model only ever contributes a name and a coarse portion impression.
//  Weights and nutrition come from a real lookup, and nothing is added to the
//  meal until the person confirms it. See FoodPhotoIdentificationService for
//  why the split is drawn there.
//

import Foundation
import SwiftUI

// MARK: - Candidate

/// One identified food, paired with whatever the database matched it to.
///
/// Kept as a distinct type rather than mutating a `FoodItem` in place so the
/// review screen can always show both halves: what the photo suggested, and
/// what is actually going to be logged.
@Observable final class PhotoFoodCandidate: Identifiable {

    /// Which kind of database entry this candidate is trying to resolve to.
    ///
    /// Now `FoodMatchRanker`'s type, shared with the voice flow — the two
    /// resolve against the same catalogue and must agree on which half of it
    /// to prefer. Kept as a nested alias so existing call sites and tests
    /// still read `PhotoFoodCandidate.NamePreference`.
    typealias NamePreference = FoodNamePreference

    let id = UUID()

    /// What the model called it. Retained after lookup so the row can show
    /// "identified as X, logging Y" when the two differ.
    let identifiedName: String

    /// The term actually searched for. Starts as `identifiedName` and can be
    /// corrected by the person.
    ///
    /// Needed because the match dropdown can only offer variations of
    /// whatever the model said. When it misreads an enchilada as "grilled
    /// chicken", every entry in that list is wrong, and picking a different
    /// chicken does not help — the name itself has to be fixable.
    var searchName: String

    /// The model's portion impression, used once to preselect a serving.
    let portionHint: PortionHint

    let confidence: FoodIdentificationConfidence

    /// Database matches for `identifiedName`, best first. Empty until lookup
    /// finishes, and still empty if nothing matched.
    var matches: [FoodSearchResult] = []

    /// The match the person has chosen, as a `FoodItem` ready for the meal.
    var selectedItem: FoodItem?

    /// Whether this candidate will be added when the person taps Add.
    var isIncluded: Bool = true

    var lookupState: LookupState = .pending

    enum LookupState: Equatable {
        case pending
        case searching
        case matched
        /// Looked up and found nothing. The person can search by hand instead.
        case noMatch
    }

    /// How this candidate should be ranked against search results.
    let preference: NamePreference

    /// The brand the model named, when it recognized one. Used to break ties
    /// toward the right company's version of a dish.
    let brandHint: String?

    init(food: IdentifiedFood) {
        self.identifiedName = food.name
        self.searchName = food.name
        self.portionHint = food.portionHint
        self.confidence = food.confidence
        self.preference = .genericIngredient
        self.brandHint = nil
    }

    /// Builds the candidate for a whole-plate dish.
    ///
    /// The brand goes into the search term rather than being kept aside: the
    /// food sources index chain items under the company name, so "taco bell
    /// mexican pizza" recalls the record that a bare "mexican pizza" misses.
    init(dish: IdentifiedDish) {
        let brand = dish.brand?.trimmingCharacters(in: .whitespacesAndNewlines)
        let brandPrefix = (brand?.isEmpty == false) ? "\(brand!) " : ""

        self.identifiedName = brandPrefix + dish.name
        self.searchName = brandPrefix + dish.name
        self.portionHint = dish.portionHint
        self.confidence = dish.confidence
        self.preference = .brandedDish
        self.brandHint = (brand?.isEmpty == false) ? brand : nil
    }

    /// True once the person has corrected the name the model produced.
    var nameWasCorrected: Bool {
        searchName.trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedCaseInsensitiveCompare(identifiedName) != .orderedSame
    }

    /// True when the chosen food is being logged under a different name than
    /// the photo suggested — worth surfacing so a bad match is visible.
    var matchDiffersFromIdentification: Bool {
        guard let selectedItem else { return false }
        return selectedItem.name.localizedCaseInsensitiveCompare(identifiedName) != .orderedSame
    }
}

// MARK: - View Model

@MainActor
@Observable final class PhotoFoodLoggingViewModel {

    // MARK: Phase

    enum Phase: Equatable {
        case choosingPhoto
        case analyzing
        case reviewing
        /// Identification did not produce anything usable. Carries the message
        /// to show before handing over to manual entry.
        case failed(message: String)
    }

    var phase: Phase = .choosingPhoto

    // MARK: State

    var image: UIImage?

    var candidates: [PhotoFoodCandidate] = []

    /// Set when the model saw seasoning it could not name. Photos rarely show
    /// enough to identify a spice, but spices are well represented in
    /// FoodCompoundDatabase, so asking beats dropping them.
    var needsSeasoningInput: Bool = false

    /// Free text the person types for those seasonings.
    var seasoningText: String = ""

    private let identificationService = FoodPhotoIdentificationService.shared
    private let searchService = FoodSearchService()

    /// Whether the camera option should be offered at all.
    var isIdentificationAvailable: Bool { identificationService.isAvailable }

    // MARK: - Analysis

    /// Identifies the foods in `image`, then looks each one up.
    func analyze(_ image: UIImage) async {
        self.image = image
        phase = .analyzing
        candidates = []
        needsSeasoningInput = false
        seasoningText = ""

        let result = await identificationService.identifyFoods(in: image)

        switch result {
        case .identified(let dish, let foods, let hasSeasoning):
            needsSeasoningInput = hasSeasoning
            phase = .reviewing
            await resolve(dish: dish, orFallBackTo: foods)

        case .couldNotIdentify, .unavailable:
            // `userMessage` is non-nil for both of these.
            phase = .failed(message: result.userMessage ?? "Couldn't identify this photo.")
        }
    }

    /// Logs the plate as one dish when the database holds it, and as the
    /// individual visible foods when it does not.
    ///
    /// The dish is tried first and kept only if it actually resolves. A dish
    /// name no food source has heard of would otherwise strand the review
    /// screen on a single unmatched row, having discarded the ingredient list
    /// that could at least log something.
    ///
    /// Only one of the two ever survives. Logging the dish *and* its visible
    /// parts would count the plate twice, which matters here beyond the
    /// calorie total — a duplicated ingredient distorts the trigger analysis.
    private func resolve(
        dish: IdentifiedDish?,
        orFallBackTo foods: [IdentifiedFood]
    ) async {
        if let dish {
            let dishCandidate = PhotoFoodCandidate(dish: dish)
            candidates = [dishCandidate]
            await lookUp(dishCandidate)

            // Keep the dish when it matched — and also when there is nothing
            // to fall back to, since an unmatched row with an editable name is
            // a recovery path and an empty review screen is not.
            if dishCandidate.lookupState == .matched || foods.isEmpty {
                return
            }
        }

        candidates = foods.map(PhotoFoodCandidate.init(food:))
        await lookUpAllCandidates()
    }

    /// Looks up every candidate against the food database.
    ///
    /// Sequential rather than concurrent: `FoodSearchService` holds its results
    /// in an instance property, so parallel searches would overwrite each
    /// other's output. A handful of lookups is quick enough that the ordering
    /// cost is not worth a second service instance per candidate.
    private func lookUpAllCandidates() async {
        for candidate in candidates {
            await lookUp(candidate)
        }
    }

    /// Resolves one candidate's `searchName` to database matches.
    ///
    /// Safe to call again after the person edits the name, which is the
    /// recovery path when identification got the food wrong.
    func lookUp(_ candidate: PhotoFoodCandidate) async {
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

        // Rank by how well the name fits what was identified, not by the
        // search service's own order — it sorts on nutrition completeness,
        // which puts branded products above generic ones. Photographing a
        // lemon and defaulting to "T. Marzetti Company Lemon" (a dressing,
        // 2 Tbsp) is the failure that motivated this.
        candidate.matches = FoodMatchRanker.rank(
            results,
            against: query,
            preference: candidate.preference,
            brandHint: candidate.brandHint
        )
        candidate.selectedItem = foodItem(for: candidate.matches[0], hint: candidate.portionHint)
        candidate.lookupState = .matched
    }

    /// Switches a candidate to a different database match, keeping the portion
    /// hint applied.
    func select(_ result: FoodSearchResult, for candidate: PhotoFoodCandidate) {
        candidate.selectedItem = foodItem(for: result, hint: candidate.portionHint)
    }

    /// Builds the `FoodItem` for a match, with the hinted serving preselected.
    ///
    /// The hint only chooses among portions the source published — see
    /// `PortionHint.preferredServing(from:default:)`. When the source offered
    /// no portions, `toFoodItem()` is left exactly as it came.
    private func foodItem(for result: FoodSearchResult, hint: PortionHint) -> FoodItem {
        var item = result.toFoodItem()

        guard let hinted = hint.preferredServing(
            from: result.servingOptions,
            default: result.defaultServing
        ) else {
            return item
        }

        item.selectedServing = hinted
        item.servingCount = 1
        item.quantity = hinted.quantityDescription(count: 1)
        return item
    }

    // MARK: - Committing

    /// Items that will be added: every included candidate that resolved to a
    /// match, plus one entry for the seasonings if any were typed.
    var itemsToAdd: [FoodItem] {
        var items = candidates
            .filter { $0.isIncluded }
            .compactMap(\.selectedItem)

        if let seasoning = seasoningItem() {
            items.append(seasoning)
        }

        return items
    }

    var canAddToMeal: Bool { !itemsToAdd.isEmpty }

    /// Adds everything to the meal builder.
    func addToMeal() {
        for item in itemsToAdd {
            MealBuilderService.shared.addFoodItem(item)
        }
    }

    /// Turns the typed seasonings into a food item.
    ///
    /// Logged with no nutrition on purpose: a pinch of cayenne contributes
    /// nothing measurable to macros, but it is exactly the kind of thing the
    /// trigger analysis wants to see, and FoodCompoundDatabase recognises
    /// common spices by name.
    private func seasoningItem() -> FoodItem? {
        let trimmed = seasoningText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        return FoodItem(
            name: trimmed,
            quantity: "to taste",
            ingredients: IngredientTextParser.split(trimmed),
            source: .manual,
            isUserEdited: true
        )
    }

    // MARK: - Testing

    /// Exposes match ranking so it can be tested without a network lookup or
    /// the on-device model. The ranking is the part most likely to regress
    /// quietly — a bad default is easy to miss in review.
    func rankedForTesting(
        _ results: [FoodSearchResult],
        against identifiedName: String,
        preference: PhotoFoodCandidate.NamePreference = .genericIngredient,
        brandHint: String? = nil
    ) -> [FoodSearchResult] {
        FoodMatchRanker.rank(
            results,
            against: identifiedName,
            preference: preference,
            brandHint: brandHint
        )
    }

    // MARK: - Reset

    func reset() {
        phase = .choosingPhoto
        image = nil
        candidates = []
        needsSeasoningInput = false
        seasoningText = ""
    }
}
