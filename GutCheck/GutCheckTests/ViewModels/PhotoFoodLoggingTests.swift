import Testing
import Foundation
@testable import GutCheck

/// Covers the two pieces of photo logging that are pure logic: how a portion
/// hint picks a serving, and how database matches are ranked against the name
/// the model produced.
///
/// Identification itself is not tested here — it needs the on-device model and
/// a real photo, so it is verified by running the app.
@MainActor
struct PhotoFoodLoggingTests {

    // MARK: - Helpers

    private func option(_ label: String, _ grams: Double) -> ServingOption {
        ServingOption(label: label, gramWeight: grams)!
    }

    // MARK: - Portion Hint

    @Test("Small steps one size down from the source's default")
    func smallStepsDownFromDefault() {
        let options = [option("1 large", 200), option("1 small", 60), option("1 medium", 120)]

        let picked = PortionHint.small.preferredServing(from: options, default: options[2])

        #expect(picked?.gramWeight == 60)
    }

    @Test("Small skips absurd outlier measures far below the default")
    func smallAvoidsOutlierMeasures() {
        // The real defect: a cooked green pepper carried "1 fl oz (with ice)"
        // at 23 g, and taking the absolute lightest option surfaced it.
        // Stepping one size down from the default lands on the sane measure.
        let outlier = option("1 fl oz (with ice)", 23)
        let chopped = option("1/2 cup chopped", 75)
        let cup = option("1 cup chopped", 150)

        let picked = PortionHint.small.preferredServing(
            from: [outlier, chopped, cup],
            default: cup
        )

        #expect(picked?.gramWeight == 75)
        #expect(picked?.label != "1 fl oz (with ice)")
    }

    @Test("Large steps one size up from the source's default")
    func largeStepsUpFromDefault() {
        let options = [option("1 large", 200), option("1 small", 60), option("1 medium", 120)]

        let picked = PortionHint.large.preferredServing(from: options, default: options[2])

        #expect(picked?.gramWeight == 200)
    }

    @Test("Small keeps the default when nothing smaller exists")
    func smallKeepsDefaultWhenNothingSmaller() {
        let smallest = option("1 cup", 150)
        let bigger = option("2 cups", 300)

        let picked = PortionHint.small.preferredServing(from: [smallest, bigger], default: smallest)

        #expect(picked == smallest)
    }

    @Test("Large keeps the default when nothing bigger exists")
    func largeKeepsDefaultWhenNothingBigger() {
        let smaller = option("1/2 cup", 75)
        let biggest = option("1 cup", 150)

        let picked = PortionHint.large.preferredServing(from: [smaller, biggest], default: biggest)

        #expect(picked == biggest)
    }

    @Test("Medium keeps the source's own default rather than the middle by weight")
    func mediumKeepsSourceDefault() {
        // The source's default already means "one normal portion of this
        // food", which is what medium is asking for.
        let options = [option("1 large", 200), option("1 small", 60), option("1 cup", 145)]
        let sourceDefault = options[2]

        let picked = PortionHint.medium.preferredServing(from: options, default: sourceDefault)

        #expect(picked == sourceDefault)
    }

    @Test("Medium falls back to the middle weight when the source named no default")
    func mediumFallsBackToMiddle() {
        let options = [option("1 large", 200), option("1 small", 60), option("1 medium", 120)]

        let picked = PortionHint.medium.preferredServing(from: options, default: nil)

        #expect(picked?.gramWeight == 120)
    }

    @Test("No options means no invented serving")
    func noOptionsYieldsDefault() {
        // The hint must never manufacture a weight. With nothing to choose
        // from it returns whatever the source gave, including nil.
        #expect(PortionHint.large.preferredServing(from: [], default: nil) == nil)
    }

    // MARK: - Match Ranking

    @Test("An exact generic match beats a branded product containing the word")
    func genericBeatsBranded() async {
        // The regression this ranking exists for: photographing a lemon and
        // defaulting to "T. Marzetti Company Lemon", a salad dressing.
        let dressing = FoodSearchResult(name: "Lemon", brand: "T. Marzetti Company")
        let fruit = FoodSearchResult(name: "Lemon", brand: nil)

        let ranked = PhotoFoodLoggingViewModel().rankedForTesting(
            [dressing, fruit],
            against: "lemon"
        )

        #expect(ranked.first?.brand == nil)
    }

    @Test("A USDA-qualified generic beats a branded product with the bare name")
    func qualifiedGenericBeatsBareBranded() async {
        // The real failure seen on device. USDA writes the fruit as
        // "Lemon, Raw"; the branded dressing is just "Lemon", so scoring whole
        // names handed the exact match to the dressing.
        let dressing = FoodSearchResult(name: "Lemon", brand: "T. Marzetti Company")
        let fruit = FoodSearchResult(name: "Lemon, Raw", brand: nil)

        let ranked = PhotoFoodLoggingViewModel().rankedForTesting(
            [dressing, fruit],
            against: "lemon"
        )

        #expect(ranked.first?.name == "Lemon, Raw")
    }

    @Test("A plural USDA head term still outranks unrelated preparations")
    func pluralHeadTermRanksAboveDerivatives() async {
        let juice = FoodSearchResult(name: "Lemon Juice, Raw", brand: nil)
        let whole = FoodSearchResult(name: "Lemons, Raw, Without Peel", brand: nil)

        let ranked = PhotoFoodLoggingViewModel().rankedForTesting(
            [juice, whole],
            against: "lemon"
        )

        #expect(ranked.first?.name == "Lemons, Raw, Without Peel")
    }

    @Test("An exact name beats one that merely contains the word")
    func exactBeatsContains() async {
        let pie = FoodSearchResult(name: "Lemon meringue pie", brand: nil)
        let fruit = FoodSearchResult(name: "Lemon", brand: nil)

        let ranked = PhotoFoodLoggingViewModel().rankedForTesting([pie, fruit], against: "lemon")

        #expect(ranked.first?.name == "Lemon")
    }

    @Test("All words present in any order scores above an unrelated entry")
    func allWordsPresentRanksUp() async {
        let unrelated = FoodSearchResult(name: "White rice", brand: nil)
        let reordered = FoodSearchResult(name: "Rice, brown, cooked", brand: nil)

        let ranked = PhotoFoodLoggingViewModel().rankedForTesting(
            [unrelated, reordered],
            against: "brown rice"
        )

        #expect(ranked.first?.name == "Rice, brown, cooked")
    }

    @Test("Equal scores keep the search service's original order")
    func tiesPreserveOriginalOrder() async {
        // Ties fall back to the service's ranking, which already reflects
        // nutrition completeness.
        let first = FoodSearchResult(name: "Grilled chicken breast", brand: nil)
        let second = FoodSearchResult(name: "Grilled chicken breast", brand: nil)

        let ranked = PhotoFoodLoggingViewModel().rankedForTesting(
            [first, second],
            against: "grilled chicken breast"
        )

        #expect(ranked.first?.id == first.id)
    }
}
