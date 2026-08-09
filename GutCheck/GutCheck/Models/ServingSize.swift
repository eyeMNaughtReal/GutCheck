//
//  ServingSize.swift
//  GutCheck
//
//  Portions a food can be logged as, and the rules for picking a sensible
//  default from what a search source offers.
//
//  Both food sources report nutrition against 100 g and describe real portions
//  separately — USDA in `foodMeasures` ("1 McDonald's Big Mac", 205 g),
//  OpenFoodFacts in `serving_size`/`product_quantity`. Logging everything at
//  100 g recorded 46% of a Big Mac (#359). Portion size is one of the stronger
//  predictors of a post-meal symptom, so the correlation engine cares about
//  this at least as much as the calorie count does.
//

import Foundation

// MARK: - Serving Option

/// A portion a food can be logged as, together with what it weighs.
///
/// Both halves matter. The label is what a person recognises ("1 medium fast
/// food order"); the weight is what the nutrition maths and any later trigger
/// analysis actually use. Showing them together keeps the choice auditable —
/// a user can see that "1 medium" meant 145 g and disagree with it.
struct ServingOption: Codable, Hashable, Identifiable {

    /// How the source names this portion, e.g. "1 McDonald's Big Mac".
    let label: String

    /// What that portion weighs. Always greater than zero.
    let gramWeight: Double

    /// Stable across a rebuild of the same list, so SwiftUI selection survives
    /// a redraw. Two options with the same name and weight *are* the same
    /// option as far as picking goes.
    var id: String { "\(label)|\(gramWeight)" }

    /// Fails rather than storing a portion that cannot be used: an empty label
    /// gives the user nothing to choose, and a zero or negative weight would
    /// divide the nutrition maths by zero.
    init?(label: String, gramWeight: Double) {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, gramWeight > 0, gramWeight.isFinite else { return nil }
        self.label = trimmed
        self.gramWeight = gramWeight
    }

    /// A plain weight portion — the fallback offered when a source describes no
    /// household measures at all.
    static func grams(_ grams: Double) -> ServingOption? {
        ServingOption(label: "\(formattedWeight(grams)) g", gramWeight: grams)
    }

    /// "1 McDonald's Big Mac · 205 g", but just "100 g" when the label is
    /// already a weight — repeating it as "100 g · 100 g" reads as a bug.
    ///
    /// The same suppression covers volumes: an OpenFoodFacts serving of
    /// "25 ml" is stored with a gram weight because that is what the nutrition
    /// scaling needs, but printing "25 ml · 25 g" would assert a density the
    /// source never gave.
    var displayName: String {
        labelIsAQuantity ? label : "\(label) · \(Self.formattedWeight(gramWeight)) g"
    }

    /// How this portion reads on a food row: "2 × 1 medium fast food order · 290 g".
    ///
    /// The count is folded into the printed weight so the row always states the
    /// total actually being logged, not the weight of one unit.
    func quantityDescription(count: Double) -> String {
        let total = gramWeight * count
        let weight = "\(Self.formattedWeight(total)) g"

        guard count != 1 else {
            return labelIsAQuantity ? label : "\(label) · \(weight)"
        }

        let countText = count.formatted(.number.precision(.fractionLength(0...2)))
        return "\(countText) × \(label) · \(weight)"
    }

    /// True when the label is nothing but a number and a unit ("100 g", "25 ml").
    private var labelIsAQuantity: Bool {
        label.range(
            of: #"^\d+(\.\d+)?\s*(g|kg|mg|ml|cl|l|oz|fl oz|lb)$"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    /// Whole grams for anything a kitchen scale would show whole, one decimal
    /// for the small stuff (a single shoestring fry is 2 g).
    static func formattedWeight(_ grams: Double) -> String {
        let digits = grams < 10 ? 0...1 : 0...0
        return grams.formatted(.number.precision(.fractionLength(digits)).grouping(.never))
    }
}

// MARK: - Resolver

/// Turns the raw portions a source hands over into a list worth showing, and
/// picks which one to start on.
enum ServingSizeResolver {

    /// Portion words that appear in both food names and measure names.
    /// "McDonald's, French Fries, Medium" and "1 medium fast food order" are
    /// the same portion said twice, and the issue is explicit that restaurant
    /// sizes must map to their real weights rather than a 100 g baseline.
    private static let sizeWords: Set<String> = [
        "small", "medium", "large", "regular", "kids", "child", "junior", "jumbo"
    ]

    /// Words that carry no identity, so matching on them would pair a food with
    /// an unrelated measure.
    private static let ignoredWords: Set<String> = [
        "the", "and", "with", "raw", "nfs", "yields", "quantity", "not",
        "specified", "shape", "cut", "any", "each", "serving", "servings",
        "prepared", "cooked", "included"
    ]

    /// Deduplicates and orders the portions for display.
    ///
    /// Ascending weight rather than source order: sources rank measures by
    /// their own internal conventions (USDA's `rank` puts "1 fry" first), and a
    /// list that runs small to large is the one a person can scan.
    static func normalize(_ options: [ServingOption]) -> [ServingOption] {
        var seen = Set<String>()
        return options
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.gramWeight < $1.gramWeight }
    }

    /// Picks the portion to start on.
    ///
    /// - Parameters:
    ///   - name: the food's own name, which often states the portion.
    ///   - options: the normalized list the user can choose from.
    ///   - preferredGrams: a weight the source itself treats as one portion
    ///     when it names no portion — USDA's "Quantity not specified" measure.
    /// - Returns: the default, or `nil` when nothing in the list is a better
    ///   guess than the source's own baseline.
    static func defaultOption(
        forFoodNamed name: String,
        from options: [ServingOption],
        preferredGrams: Double? = nil
    ) -> ServingOption? {
        guard !options.isEmpty else { return nil }

        let nameWords = words(in: name)

        // 1. The name already states a size. "Medium" in the name and
        //    "1 medium fast food order" in the measures are the same thing, and
        //    nothing else in the list should outrank that.
        if let sized = options.first(where: { option in
            !sizeWords.isDisjoint(with: words(in: option.label).intersection(nameWords))
        }) {
            return sized
        }

        // 2. Otherwise prefer the measure that names this food. A Big Mac's
        //    measures also list a Mac Jr and a Grand Mac; only one of the three
        //    is what was searched for.
        let named = options
            .map { (option: $0, score: words(in: $0.label).intersection(nameWords).count) }
            .filter { $0.score > 0 }
        if let best = named.max(by: { left, right in
            if left.score != right.score { return left.score < right.score }
            // Same amount of name in both: side with whatever weight the source
            // itself calls one portion.
            return distance(left.option, from: preferredGrams) > distance(right.option, from: preferredGrams)
        }) {
            return best.option
        }

        // 3. Nothing matched by name, so fall back to the measure that weighs
        //    what the source treats as one portion. Exact match only — a
        //    "nearest weight" rule would happily return a single fry.
        if let preferredGrams {
            return options.first { abs($0.gramWeight - preferredGrams) < 0.5 }
        }

        return nil
    }

    private static func distance(_ option: ServingOption, from grams: Double?) -> Double {
        guard let grams else { return 0 }
        return abs(option.gramWeight - grams)
    }

    /// Lowercased words of three or more letters, minus the ones that say
    /// nothing about which food this is.
    private static func words(in text: String) -> Set<String> {
        let parts = text.lowercased().split { !$0.isLetter && !$0.isNumber }
        return Set(parts.map(String.init).filter { $0.count >= 3 && !ignoredWords.contains($0) })
    }
}
