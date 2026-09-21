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
    /// The two pull in opposite directions, so ranking cannot have one fixed
    /// rule. A plain ingredient wants the generic entry — photograph a lemon
    /// and you mean the fruit, not a branded lemon dressing. A named dish
    /// wants the branded entry — "mexican pizza" means Taco Bell's, whose
    /// database record already accounts for the beef, beans and cheese that
    /// no photo of it can show.
    enum NamePreference: Equatable {
        case genericIngredient
        case brandedDish
    }

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
        candidate.matches = rankMatches(
            results,
            against: query,
            preference: candidate.preference,
            brandHint: candidate.brandHint
        )
        candidate.selectedItem = foodItem(for: candidate.matches[0], hint: candidate.portionHint)
        candidate.lookupState = .matched
    }

    /// Orders search results by closeness to the identified food name.
    ///
    /// The photo said "lemon", so a result actually called "lemon" beats one
    /// that merely contains the word. Generic entries outrank branded ones at
    /// equal closeness: a brand in the name is nearly always a prepared
    /// product rather than the ingredient that was photographed.
    private func rankMatches(
        _ results: [FoodSearchResult],
        against identifiedName: String,
        preference: PhotoFoodCandidate.NamePreference,
        brandHint: String?
    ) -> [FoodSearchResult] {
        let target = identifiedName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let brand = brandHint?.lowercased()

        return results.enumerated()
            .sorted { lhs, rhs in
                let lhsScore = matchScore(lhs.element, target: target, preference: preference, brand: brand)
                let rhsScore = matchScore(rhs.element, target: target, preference: preference, brand: brand)
                guard lhsScore == rhsScore else { return lhsScore > rhsScore }
                // Ties keep the service's original order, which already
                // reflects nutrition completeness.
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    /// Higher is a better fit. Deliberately coarse — this picks a default the
    /// person can override, not a definitive answer.
    ///
    /// Scoring runs against the head term rather than the whole name. USDA
    /// writes generic foods as "PrimaryName, qualifier, qualifier" — the
    /// lemon you photograph is "Lemon, Raw" — while branded products get clean
    /// short names. Comparing whole names therefore hands every exact match to
    /// the branded entry: "Lemon" by T. Marzetti (a dressing) beat "Lemon, Raw"
    /// on the first version of this.
    private func matchScore(
        _ result: FoodSearchResult,
        target: String,
        preference: PhotoFoodCandidate.NamePreference,
        brand: String?
    ) -> Int {
        let name = result.name.lowercased()
        let head = name.split(separator: ",").first.map(String.init)?
            .trimmingCharacters(in: .whitespaces) ?? name
        let isGeneric = result.brand == nil

        // A dish search carries the brand in the target ("taco bell mexican
        // pizza"), but the sources disagree on where the brand lives: some put
        // it in a separate field, some fold it into the name. Matching against
        // both joined covers either layout.
        let searchable: String = {
            guard preference == .brandedDish, let resultBrand = result.brand else { return name }
            return "\(resultBrand.lowercased()) \(name)"
        }()

        var score = 0

        let targetWords = target.split(separator: " ").map(String.init)
        let headWords = head.split(separator: " ").map(String.init)

        if head == target {
            score += 100
        } else if head.hasPrefix(target), headWords.count == targetWords.count {
            // The plural USDA sometimes uses: "Lemons, Raw, Without Peel".
            //
            // The word-count guard matters. Without it "lemon juice" also
            // passes hasPrefix("lemon") and scores as a plural of lemon,
            // which tied juice with the whole fruit. An extra word means a
            // different food, not a different spelling.
            score += 60
        } else if searchable.contains(target) {
            score += 30
        }

        // Every word of the identified name present, in any order: catches
        // "rice, brown, cooked" for "brown rice", and a record named "Mexican
        // Pizza" under brand "Taco Bell" for "taco bell mexican pizza".
        if targetWords.count > 1, targetWords.allSatisfy(searchable.contains) {
            score += 20
        }

        switch preference {
        case .genericIngredient:
            // A brand in the name is nearly always a prepared product rather
            // than the ingredient that was photographed.
            if isGeneric { score += 25 }

        case .brandedDish:
            // Inverted on purpose. For a chain item the branded record is the
            // accurate one: it accounts for the beef, beans and cheese inside
            // a Mexican Pizza that the photo only shows a tortilla of.
            if !isGeneric { score += 25 }

            if let brand, result.brand?.lowercased().contains(brand) == true {
                score += 40
            }
        }

        return score
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
        rankMatches(
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
