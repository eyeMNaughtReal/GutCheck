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
                // Convert dictionary back to FoodItem
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
