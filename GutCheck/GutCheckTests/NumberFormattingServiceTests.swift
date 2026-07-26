import Testing
import Foundation
@testable import GutCheck

struct NumberFormattingServiceTests {

    // MARK: - Decimal formatting

    @Test("Formats double with specified decimal places")
    func formatsDecimal() {
        let result = NumberFormattingService.string(from: 3.14159, format: .decimal(places: 2))
        #expect(result == "3.14")
    }

    @Test("Formats double with zero decimal places")
    func formatsDecimalZeroPlaces() {
        let result = NumberFormattingService.string(from: 3.7, format: .decimal(places: 0))
        #expect(result == "4")
    }

    @Test("Formats integer with decimal format")
    func formatsIntWithDecimal() {
        let result = NumberFormattingService.string(from: 42, format: .decimal(places: 1))
        #expect(result == "42.0")
    }

    // MARK: - Percent formatting

    @Test("Formats double as percent")
    func formatsPercent() {
        let result = NumberFormattingService.string(from: 0.856, format: .percent)
        // NumberFormatter percent style multiplies by 100
        #expect(result.contains("85"))
    }

    @Test("Formats zero as percent")
    func formatsZeroPercent() {
        let result = NumberFormattingService.string(from: 0.0, format: .percent)
        #expect(result.contains("0"))
    }

    // MARK: - Calories formatting

    @Test("Formats calories with no decimal places")
    func formatsCalories() {
        let result = NumberFormattingService.string(from: 256, format: .calories)
        #expect(result == "256")
    }

    @Test("Formats large calorie count with grouping separator")
    func formatsLargeCalories() {
        let result = NumberFormattingService.string(from: 2500, format: .calories)
        // May include thousands separator depending on locale
        #expect(result.contains("2") && result.contains("500"))
    }

    // MARK: - Weight formatting

    @Test("Formats weight with one decimal place")
    func formatsWeight() {
        let result = NumberFormattingService.string(from: 75.5, format: .weight)
        #expect(result == "75.5")
    }

    @Test("Formats whole number weight with one decimal")
    func formatsWholeWeight() {
        let result = NumberFormattingService.string(from: 80.0, format: .weight)
        #expect(result == "80.0")
    }

    // MARK: - NumberFormat.formatter property

    @Test("Each NumberFormat produces a valid formatter")
    func eachFormatProducesFormatter() {
        let formats: [NumberFormat] = [
            .decimal(places: 2),
            .percent,
            .calories,
            .weight
        ]
        for format in formats {
            let formatter = format.formatter
            #expect(formatter.string(from: NSNumber(value: 1.0)) != nil)
        }
    }

    // MARK: - Double extension tests

    @Test("Double.formatted returns two decimal places")
    func doubleFormatted() {
        let value: Double = 3.14159
        #expect(value.formatted.contains("3.14"))
    }

    @Test("Double.formattedPercent returns percentage")
    func doubleFormattedPercent() {
        let value: Double = 0.5
        #expect(value.formattedPercent.contains("50"))
    }

    @Test("Double.formattedWeight returns one decimal")
    func doubleFormattedWeight() {
        let value: Double = 75.5
        #expect(value.formattedWeight == "75.5")
    }

    // MARK: - Int extension tests

    @Test("Int.formattedCalories returns formatted string")
    func intFormattedCalories() {
        let value: Int = 256
        #expect(value.formattedCalories == "256")
    }
}
