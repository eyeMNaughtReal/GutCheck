//
//  SpotlightIndexingService.swift
//  GutCheck
//
//  Indexes meals and symptoms in iOS Spotlight search for quick retrieval.
//

import CoreSpotlight
import MobileCoreServices
import UIKit

final class SpotlightIndexingService: Sendable {
    static let shared = SpotlightIndexingService()

    private let index = CSSearchableIndex.default()

    // Domain identifiers for batch operations
    private static let mealDomain = "com.gutcheck.meals"
    private static let symptomDomain = "com.gutcheck.symptoms"

    // Expiration: 6 months from indexing
    private static let expirationInterval: TimeInterval = 60 * 60 * 24 * 180

    private init() {}

    // MARK: - Identifier Helpers

    static func mealIdentifier(for id: String) -> String {
        "meal_\(id)"
    }

    static func symptomIdentifier(for id: String) -> String {
        "symptom_\(id)"
    }

    /// Parses a Spotlight identifier into a type ("meal" or "symptom") and entity ID.
    static func parseIdentifier(_ identifier: String) -> (type: String, id: String)? {
        if identifier.hasPrefix("meal_") {
            return ("meal", String(identifier.dropFirst(5)))
        } else if identifier.hasPrefix("symptom_") {
            return ("symptom", String(identifier.dropFirst(8)))
        }
        return nil
    }

    // MARK: - Meal Indexing

    func indexMeal(_ meal: Meal) {
        // Only index public data
        guard meal.privacyLevel == .public else { return }

        let identifier = Self.mealIdentifier(for: meal.id)

        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = meal.name
        attributes.displayName = meal.name

        // Build content description from food items and meal type — never include notes
        var descriptionParts: [String] = []
        descriptionParts.append(meal.type.rawValue.capitalized)

        let foodNames = meal.foodItems.prefix(5).map(\.name)
        if !foodNames.isEmpty {
            descriptionParts.append(foodNames.joined(separator: ", "))
        }

        attributes.contentDescription = descriptionParts.joined(separator: " — ")

        // Date
        attributes.contentCreationDate = meal.date

        // Keywords for better search
        var keywords = ["meal", meal.type.rawValue]
        keywords.append(contentsOf: meal.foodItems.map(\.name))
        keywords.append(contentsOf: meal.tags)
        attributes.keywords = keywords

        // Thumbnail via SF Symbol
        if let image = UIImage(systemName: "fork.knife.circle.fill") {
            attributes.thumbnailData = image.pngData()
        }

        let item = CSSearchableItem(
            uniqueIdentifier: identifier,
            domainIdentifier: Self.mealDomain,
            attributeSet: attributes
        )
        item.expirationDate = Date(timeIntervalSinceNow: Self.expirationInterval)

        index.indexSearchableItems([item])
    }

    // MARK: - Symptom Indexing

    func indexSymptom(_ symptom: Symptom) {
        // Only index public data
        guard symptom.privacyLevel == .public else { return }

        let identifier = Self.symptomIdentifier(for: symptom.id)

        let attributes = CSSearchableItemAttributeSet(contentType: .content)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: symptom.date)

        attributes.title = "Symptom Log — \(dateString)"
        attributes.displayName = "Symptom Log — \(dateString)"

        // Content description from stool type, pain, urgency — never include notes
        var parts: [String] = []
        parts.append("Bristol Type \(symptom.stoolType.rawValue)")
        parts.append("Pain: \(symptom.painLevel.rawValue)")
        parts.append("Urgency: \(symptom.urgencyLevel.rawValue)")
        attributes.contentDescription = parts.joined(separator: " · ")

        attributes.contentCreationDate = symptom.date

        // Keywords
        var keywords = ["symptom", "bowel", "gut"]
        keywords.append(contentsOf: symptom.tags)
        attributes.keywords = keywords

        // Thumbnail via SF Symbol
        if let image = UIImage(systemName: "heart.text.square.fill") {
            attributes.thumbnailData = image.pngData()
        }

        let item = CSSearchableItem(
            uniqueIdentifier: identifier,
            domainIdentifier: Self.symptomDomain,
            attributeSet: attributes
        )
        item.expirationDate = Date(timeIntervalSinceNow: Self.expirationInterval)

        index.indexSearchableItems([item])
    }

    // MARK: - Removal

    func removeMeal(id: String) {
        let identifier = Self.mealIdentifier(for: id)
        index.deleteSearchableItems(withIdentifiers: [identifier])
    }

    func removeSymptom(id: String) {
        let identifier = Self.symptomIdentifier(for: id)
        index.deleteSearchableItems(withIdentifiers: [identifier])
    }

    func removeAllItems() {
        index.deleteAllSearchableItems()
    }
}
