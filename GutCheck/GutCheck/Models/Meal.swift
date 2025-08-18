//
//  Meal.swift
//  GutCheck
//
//  Updated to include FirestoreModel conformance
//

import Foundation
import FirebaseFirestore

// Make sure we have access to RepositoryError and other Firebase types
// These should be automatically available in the same target

enum MealType: String, Codable, CaseIterable {
    case breakfast, lunch, dinner, snack, drink
}

enum MealSource: String, Codable {
    case manual, barcode, lidar, ai
}

struct Meal: Identifiable, Codable, Hashable, Equatable, FirestoreModel {
    var id: String = UUID().uuidString
    var name: String
    var date: Date
    var type: MealType
    var source: MealSource
    var foodItems: [FoodItem]
    var notes: String?
    var tags: [String] = []
    var createdBy: String = ""
    
    // MARK: - Privacy Classification
    
    /// Determines the privacy level of this meal data
    /// This affects where and how the data is stored
    var privacyLevel: DataPrivacyLevel {
        // Personal notes and detailed observations are private
        if let notes = notes, !notes.isEmpty {
            return .private
        }
        
        // Location-based meals are private
        if tags.contains("location") || tags.contains("personal") {
            return .private
        }
        
        // Basic meal structure and nutrition is non-private
        return .public
    }
    
    /// Whether this meal requires local encrypted storage
    var requiresLocalStorage: Bool {
        return privacyLevel == .private || privacyLevel == .confidential
    }
    
    /// Whether this meal can be synced to the cloud
    var allowsCloudSync: Bool {
        return privacyLevel == .public
    }
    
    // MARK: - Initializers
    
    init(id: String = UUID().uuidString,
         name: String,
         date: Date,
         type: MealType,
         source: MealSource,
         foodItems: [FoodItem],
         notes: String? = nil,
         tags: [String] = [],
         createdBy: String = "") {
        self.id = id
        self.name = name
        self.date = date
        self.type = type
        self.source = source
        self.foodItems = foodItems
        self.notes = notes
        self.tags = tags
        self.createdBy = createdBy
    }
    
    // MARK: - FirestoreModel Conformance
    
    init(from document: DocumentSnapshot) throws {
        guard let data = document.data() else {
            throw RepositoryError.invalidData("Document has no data")
        }
        
        self.id = document.documentID
        self.name = data["name"] as? String ?? ""
        self.createdBy = data["createdBy"] as? String ?? ""
        self.notes = data["notes"] as? String
        self.tags = data["tags"] as? [String] ?? []
        
        // Handle date conversion
        if let timestamp = data["date"] as? Timestamp {
            self.date = timestamp.dateValue()
        } else {
            self.date = Date()
        }
        
        // Handle enum types
        if let typeString = data["type"] as? String {
            self.type = MealType(rawValue: typeString) ?? .lunch
        } else {
            self.type = .lunch
        }
        
        if let sourceString = data["source"] as? String {
            self.source = MealSource(rawValue: sourceString) ?? .manual
        } else {
            self.source = .manual
        }
        
        // Handle food items array
        if let foodItemsData = data["foodItems"] as? [[String: Any]] {
            self.foodItems = foodItemsData.compactMap { itemData in
                try? FoodItem.fromDictionary(itemData)
            }
        } else {
            self.foodItems = []
        }
    }
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "name": name,
            "date": Timestamp(date: date),
            "type": type.rawValue,
            "source": source.rawValue,
            "createdBy": createdBy,
            "tags": tags
        ]
        
        if let notes = notes {
            data["notes"] = notes
        }
        
        // Convert food items to dictionaries
        data["foodItems"] = foodItems.map { $0.toDictionary() }
        
        return data
    }
}

// MARK: - Meal Template for Reusable Meals

struct MealTemplate: Identifiable, Codable, Hashable, Equatable, FirestoreModel {
    var id: String = UUID().uuidString
    var name: String
    var type: MealType
    var foodItems: [FoodItem]
    var notes: String?
    var tags: [String] = []
    var createdBy: String = ""
    var usageCount: Int = 0
    var lastUsed: Date?
    var createdAt: Date = Date()
    
    // MARK: - Privacy Classification
    
    /// Determines the privacy level of this meal template
    var privacyLevel: DataPrivacyLevel {
        // Personal notes are private
        if let notes = notes, !notes.isEmpty {
            return .private
        }
        
        // Location-based templates are private
        if tags.contains("location") || tags.contains("personal") {
            return .private
        }
        
        // Basic meal structure and nutrition is non-private
        return .public
    }
    
    /// Whether this template requires local encrypted storage
    var requiresLocalStorage: Bool {
        return privacyLevel == .private || privacyLevel == .confidential
    }
    
    /// Whether this template can be synced to the cloud
    var allowsCloudSync: Bool {
        return privacyLevel == .public
    }
    
    // MARK: - Initializers
    
    init(id: String = UUID().uuidString,
         name: String,
         type: MealType,
         foodItems: [FoodItem],
         notes: String? = nil,
         tags: [String] = [],
         createdBy: String = "",
         usageCount: Int = 0,
         lastUsed: Date? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.type = type
        self.foodItems = foodItems
        self.notes = notes
        self.tags = tags
        self.createdBy = createdBy
        self.usageCount = usageCount
        self.lastUsed = lastUsed
        self.createdAt = createdAt
    }
    
    // MARK: - FirestoreModel Conformance
    
    init(from document: DocumentSnapshot) throws {
        guard let data = document.data() else {
            throw RepositoryError.invalidData("Document has no data")
        }
        
        self.id = document.documentID
        self.name = data["name"] as? String ?? ""
        self.createdBy = data["createdBy"] as? String ?? ""
        self.notes = data["notes"] as? String
        self.tags = data["tags"] as? [String] ?? []
        self.usageCount = data["usageCount"] as? Int ?? 0
        
        // Handle date conversions
        if let timestamp = data["lastUsed"] as? Timestamp {
            self.lastUsed = timestamp.dateValue()
        }
        
        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        }
        
        // Handle enum types
        if let typeString = data["type"] as? String {
            self.type = MealType(rawValue: typeString) ?? .lunch
        } else {
            self.type = .lunch
        }
        
        // Handle food items array
        if let foodItemsData = data["foodItems"] as? [[String: Any]] {
            self.foodItems = foodItemsData.compactMap { itemData in
                try? FoodItem.fromDictionary(itemData)
            }
        } else {
            self.foodItems = []
        }
    }
    
    // MARK: - Helper Methods
    
    /// Creates a new Meal instance from this template
    func createMeal(date: Date = Date(), source: MealSource = .manual) -> Meal {
        return Meal(
            name: name,
            date: date,
            type: type,
            source: source,
            foodItems: foodItems,
            notes: notes,
            tags: tags,
            createdBy: createdBy
        )
    }
    
    /// Increments usage count and updates last used date
    mutating func markAsUsed() {
        usageCount += 1
        lastUsed = Date()
    }
    
    // MARK: - FirestoreModel Conformance
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "name": name,
            "type": type.rawValue,
            "foodItems": foodItems.map { $0.toFirestoreData() },
            "tags": tags,
            "createdBy": createdBy,
            "usageCount": usageCount,
            "createdAt": Timestamp(date: createdAt)
        ]
        
        if let notes = notes {
            data["notes"] = notes
        }
        
        if let lastUsed = lastUsed {
            data["lastUsed"] = Timestamp(date: lastUsed)
        }
        
        return data
    }
}

// MARK: - Meal Template Repository

class MealTemplateRepository: BaseFirebaseRepository<MealTemplate> {
    static let shared = MealTemplateRepository()
    
    private init() {
        super.init(collectionName: "mealTemplates")
    }
    
    // MARK: - Template-Specific Methods
    
    /// Fetch all templates for a user
    func fetchTemplates(for userId: String) async throws -> [MealTemplate] {
        return try await query { query in
            query.whereField("createdBy", isEqualTo: userId)
        }
    }
    
    /// Fetch templates by meal type
    func fetchTemplates(for userId: String, mealType: MealType) async throws -> [MealTemplate] {
        return try await query { query in
            query.whereField("createdBy", isEqualTo: userId)
                .whereField("type", isEqualTo: mealType.rawValue)
        }
    }
    
    /// Fetch most frequently used templates
    func fetchPopularTemplates(for userId: String, limit: Int = 10) async throws -> [MealTemplate] {
        let templates = try await fetchTemplates(for: userId)
        return templates.sorted { $0.usageCount > $1.usageCount }.prefix(limit).map { $0 }
    }
    
    /// Fetch recently used templates
    func fetchRecentTemplates(for userId: String, limit: Int = 10) async throws -> [MealTemplate] {
        let templates = try await fetchTemplates(for: userId)
        return templates.sorted { ($0.lastUsed ?? $0.createdAt) > ($1.lastUsed ?? $1.createdAt) }.prefix(limit).map { $0 }
    }
    
    /// Increment usage count for a template
    func incrementUsage(for templateId: String) async throws {
        guard let template = try await fetch(id: templateId) else { return }
        var updatedTemplate = template
        updatedTemplate.markAsUsed()
        try await save(updatedTemplate)
    }
    
    /// Search templates by name
    func searchTemplates(for userId: String, query: String) async throws -> [MealTemplate] {
        let templates = try await fetchTemplates(for: userId)
        return templates.filter { template in
            template.name.localizedCaseInsensitiveContains(query) ||
            template.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}
