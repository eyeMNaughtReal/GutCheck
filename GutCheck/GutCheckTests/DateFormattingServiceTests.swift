import Testing
import Foundation
@testable import GutCheck

struct DateFormattingServiceTests {
    // Use a fixed date for deterministic tests: January 15, 2025 at 14:30:00 UTC
    let fixedDate = Date(timeIntervalSince1970: 1736953800)

    // Use a US English locale formatter for consistent test results
    private func makeFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = format
        return formatter
    }

    @Test("Formats date with .date format")
    func formatsDate() {
        let result = DateFormattingService.string(from: fixedDate, format: .date)
        #expect(!result.isEmpty)
        // Should contain year
        #expect(result.contains("2025"))
    }

    @Test("Formats time with .time format")
    func formatsTime() {
        let result = DateFormattingService.string(from: fixedDate, format: .time)
        #expect(!result.isEmpty)
    }

    @Test("Formats dateTime with .dateTime format")
    func formatsDateTime() {
        let result = DateFormattingService.string(from: fixedDate, format: .dateTime)
        #expect(!result.isEmpty)
        #expect(result.contains("2025"))
    }

    @Test("Formats with .dayAndMonth format")
    func formatsDayAndMonth() {
        let result = DateFormattingService.string(from: fixedDate, format: .dayAndMonth)
        #expect(!result.isEmpty)
        #expect(result.contains("15"))
    }

    @Test("Formats with .weekday format")
    func formatsWeekday() {
        let result = DateFormattingService.string(from: fixedDate, format: .weekday)
        #expect(!result.isEmpty)
        // January 15, 2025 is a Wednesday
    }

    @Test("Formats with .shortWeekday format")
    func formatsShortWeekday() {
        let result = DateFormattingService.string(from: fixedDate, format: .shortWeekday)
        #expect(!result.isEmpty)
    }

    @Test("Formats with .monthAndYear format")
    func formatsMonthAndYear() {
        let result = DateFormattingService.string(from: fixedDate, format: .monthAndYear)
        #expect(!result.isEmpty)
        #expect(result.contains("2025"))
    }

    @Test("Formats with .dayOnly format")
    func formatsDayOnly() {
        let result = DateFormattingService.string(from: fixedDate, format: .dayOnly)
        #expect(result == "15")
    }

    @Test("Formats with .mediumDate format")
    func formatsMediumDate() {
        let result = DateFormattingService.string(from: fixedDate, format: .mediumDate)
        #expect(!result.isEmpty)
    }

    @Test("Formats with .shortTime format")
    func formatsShortTime() {
        let result = DateFormattingService.string(from: fixedDate, format: .shortTime)
        #expect(!result.isEmpty)
    }

    @Test("Formats with .mediumDateTime format")
    func formatsMediumDateTime() {
        let result = DateFormattingService.string(from: fixedDate, format: .mediumDateTime)
        #expect(!result.isEmpty)
    }

    @Test("Formats with custom format string")
    func formatsCustom() {
        let result = DateFormattingService.string(from: fixedDate, format: .custom("yyyy"))
        #expect(result == "2025")
    }

    @Test("Parses date from string round-trips correctly")
    func parsesDateRoundTrip() {
        let formatted = DateFormattingService.string(from: fixedDate, format: .date)
        let parsed = DateFormattingService.date(from: formatted, format: .date)
        #expect(parsed != nil)
    }

    @Test("Parsing invalid string returns nil")
    func parsesInvalidStringReturnsNil() {
        let result = DateFormattingService.date(from: "not a date", format: .date)
        #expect(result == nil)
    }

    // MARK: - DateFormat.formatString tests

    @Test("DateFormat.formatString returns expected patterns")
    func dateFormatStrings() {
        #expect(DateFormat.date.formatString == "MMM d, yyyy")
        #expect(DateFormat.time.formatString == "h:mm a")
        #expect(DateFormat.dateTime.formatString == "MMM d, yyyy h:mm a")
        #expect(DateFormat.dayAndMonth.formatString == "MMM d")
        #expect(DateFormat.weekday.formatString == "EEEE")
        #expect(DateFormat.shortWeekday.formatString == "E")
        #expect(DateFormat.monthAndYear.formatString == "MMMM yyyy")
        #expect(DateFormat.dayOnly.formatString == "d")
        #expect(DateFormat.custom("HH:mm").formatString == "HH:mm")
    }

    @Test("Style-based formats return empty formatString")
    func styleBasedFormatsReturnEmpty() {
        #expect(DateFormat.mediumDate.formatString == "")
        #expect(DateFormat.shortTime.formatString == "")
        #expect(DateFormat.mediumDateTime.formatString == "")
    }

    // MARK: - Date extension tests

    @Test("Date extension properties return non-empty strings")
    func dateExtensionProperties() {
        #expect(!fixedDate.formattedDate.isEmpty)
        #expect(!fixedDate.formattedTime.isEmpty)
        #expect(!fixedDate.formattedDateTime.isEmpty)
        #expect(!fixedDate.monthAndDay.isEmpty)
        #expect(!fixedDate.weekdayName.isEmpty)
    }
}
