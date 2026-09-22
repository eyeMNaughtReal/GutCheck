//
//  FoodMatchRanker.swift
//  GutCheck
//
//  Orders database search results by how well they fit a food that was
//  identified from a photo or heard in a sentence.
//
//  Extracted from PhotoFoodLoggingViewModel unchanged so the voice flow can
//  share it. Worth keeping in one place: every rule here exists because of a
//  specific wrong default that shipped, and the rules are not guessable from
//  first principles. Two flows drifting apart on this would mean the same
//  spoken and photographed lemon resolving to different records.
//

import Foundation

/// Which kind of database entry a candidate is trying to resolve to.
///
/// The two pull in opposite directions, so ranking cannot have one fixed rule.
/// A plain ingredient wants the generic entry — a lemon is the fruit, not a
/// branded lemon dressing. A named dish wants the branded entry — "mexican
/// pizza" means Taco Bell's, whose record already accounts for the beef, beans
/// and cheese that no photo of it shows and no speaker lists.
enum FoodNamePreference: Equatable {
    case genericIngredient
    case brandedDish
}

/// Ranks search results against the name a food was identified by.
enum FoodMatchRanker {

    /// Orders search results by closeness to the identified food name.
    ///
    /// The photo said "lemon", so a result actually called "lemon" beats one
    /// that merely contains the word. Generic entries outrank branded ones at
    /// equal closeness: a brand in the name is nearly always a prepared
    /// product rather than the ingredient that was named.
    static func rank(
        _ results: [FoodSearchResult],
        against identifiedName: String,
        preference: FoodNamePreference,
        brandHint: String?
    ) -> [FoodSearchResult] {
        let target = identifiedName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let brand = brandHint?.lowercased()

        return results.enumerated()
            .sorted { lhs, rhs in
                let lhsScore = score(lhs.element, target: target, preference: preference, brand: brand)
                let rhsScore = score(rhs.element, target: target, preference: preference, brand: brand)
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
    /// writes generic foods as "PrimaryName, qualifier, qualifier" — the lemon
    /// you photograph is "Lemon, Raw" — while branded products get clean short
    /// names. Comparing whole names therefore hands every exact match to the
    /// branded entry: "Lemon" by T. Marzetti (a dressing) beat "Lemon, Raw" on
    /// the first version of this.
    private static func score(
        _ result: FoodSearchResult,
        target: String,
        preference: FoodNamePreference,
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
            // passes hasPrefix("lemon") and scores as a plural of lemon, which
            // tied juice with the whole fruit. An extra word means a different
            // food, not a different spelling.
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
            // than the ingredient that was named.
            if isGeneric { score += 25 }

        case .brandedDish:
            // Inverted on purpose. For a chain or packaged item the branded
            // record is the accurate one: it accounts for the beef, beans and
            // cheese inside a Mexican Pizza that the photo only shows a
            // tortilla of, and for everything in a bag of chips that a speaker
            // will never list.
            if !isGeneric { score += 25 }

            if let brand, result.brand?.lowercased().contains(brand) == true {
                score += 40
            }
        }

        return score
    }
}
