//
//  IngredientTextParser.swift
//  GutCheck
//
//  Splits a label's ingredient string into individual ingredients.
//
//  Splitting naively on "," shreds compound entries and leaves unbalanced
//  fragments behind. A Big Mac came back as 31 "ingredients" including
//  `Sauce (Eau`, `Épices (Dont Moutarde` and `Edta)` — the second of which hid
//  a mustard declaration inside a broken fragment.
//

import Foundation

enum IngredientTextParser {

    /// Placeholder values that upstream data uses in place of a real name.
    /// These reach the UI capitalized, so a null becomes a listed "Undefined".
    private static let placeholders: Set<String> = [
        "undefined", "null", "nil", "none", "n/a", "na", "unknown", "-", "--", "?"
    ]

    /// Phrases that introduce an allergen or trace declaration rather than more
    /// ingredients. Everything from here on is a "contains" statement, and the
    /// structured `allergens_tags` already carry it — leaving it in the text
    /// turns declarations like `Milk, Eggs, Mustard` into fake ingredients.
    private static let trailerMarkers = [
        "in unknown quantities:",
        "in unknown quantities",
        "allergens:",
        "allergen information",
        "contains:",
        "may contain",
        "traces of",
        "traces:"
    ]

    /// Splits an ingredient string into trimmed, non-empty ingredients.
    ///
    /// Commas inside brackets are treated as part of the ingredient rather than
    /// as separators, so `Sauce (water, rapeseed oil)` stays one entry instead
    /// of becoming three fragments and an orphaned bracket.
    static func split(_ text: String?) -> [String] {
        guard let text, !text.isEmpty else { return [] }

        let body = stripTrailer(text)
        guard !body.isEmpty else { return [] }

        let segments = splitRespectingBrackets(body)

        // Real label text is not reliably balanced. When a segment has an
        // unclosed bracket it has swallowed everything after it, so fall back
        // to a flat split for that segment rather than emitting a wall of text.
        return segments.flatMap { segment -> [String] in
            isBalanced(segment) ? [segment] : flatSplit(segment)
        }
        .map { clean($0) }
        .filter { isUsable($0) }
    }

    /// Drops the allergen declaration that many records append to the
    /// ingredient text.
    private static func stripTrailer(_ text: String) -> String {
        var earliest: String.Index?

        // Search the original string case-insensitively rather than indexing
        // into a lowercased copy by offset: case folding can change a string's
        // length, which would put the cut in the wrong place.
        for marker in trailerMarkers {
            if let range = text.range(of: marker, options: [.caseInsensitive]) {
                if earliest == nil || range.lowerBound < earliest! {
                    earliest = range.lowerBound
                }
            }
        }

        guard let cut = earliest else { return text }
        return String(text[text.startIndex..<cut])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ",;("))
    }

    private static func isBalanced(_ text: String) -> Bool {
        var depth = 0
        for character in text {
            if "([{".contains(character) { depth += 1 }
            if ")]}".contains(character) {
                depth -= 1
                if depth < 0 { return false }
            }
        }
        return depth == 0
    }

    /// Ignores brackets entirely — used only to rescue malformed input, where
    /// an unclosed bracket would otherwise swallow the rest of the list. Every
    /// bracket character is dropped, not just trimmed from the ends, because a
    /// fragment like `Sauce (Water` carries its orphan in the middle.
    private static func flatSplit(_ text: String) -> [String] {
        text.components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.filter { !"()[]{}".contains($0) } }
    }

    private static func splitRespectingBrackets(_ text: String) -> [String] {
        var ingredients: [String] = []
        var current = ""
        var depth = 0

        for character in text {
            switch character {
            case "(", "[", "{":
                depth += 1
                current.append(character)
            case ")", "]", "}":
                depth = max(0, depth - 1)
                current.append(character)
            case ",", ";":
                if depth == 0 {
                    ingredients.append(current)
                    current = ""
                } else {
                    current.append(character)
                }
            default:
                current.append(character)
            }
        }
        ingredients.append(current)

        return ingredients
    }

    /// Strips the percentage annotations and stray punctuation that labels carry
    /// (`"Beef 45%"`, `"* organic"`) without touching the ingredient name.
    private static func clean(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Leading list markers and footnote symbols.
        while let first = value.first, "*_•-–—".contains(first) {
            value.removeFirst()
            value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Trailing percentages: "Beef 45%" or "Beef (45%)".
        if let range = value.range(of: #"\s*\(?\d+([.,]\d+)?\s*%\)?$"#, options: .regularExpression) {
            value.removeSubrange(range)
        }

        return value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".:"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isUsable(_ value: String) -> Bool {
        guard !value.isEmpty else { return false }
        guard !placeholders.contains(value.lowercased()) else { return false }
        // A fragment of pure punctuation carries no information.
        return value.contains(where: { $0.isLetter || $0.isNumber })
    }
}
