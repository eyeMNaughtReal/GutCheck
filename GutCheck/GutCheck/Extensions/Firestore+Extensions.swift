//
//  Firestore+Extensions.swift
//  GutCheck
//
//  Extensions to make models compatible with Firestore
//

import Foundation
import FirebaseFirestore

// MARK: - Meal Firestore Extension
extension Meal {
    init(from document: DocumentSnapshot) throws {
        let data = document.data()
        guard let data = data else {
            throw NSError(domain: "MealDecoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data found"])
        }
        
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let dateTimestamp = data["date"] as? Timestamp,
              let typeRaw = data["type"] as? String,
              let type = MealType(rawValue: typeRaw),
              let sourceRaw = data["source"] as? String,
              let source = MealSource(rawValue: sourceRaw),
              let createdBy = data["createdBy"] as? String else {
            throw NSError(domain: "MealDecoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid meal data"])
        }
        
        self.id = id
        self.name = name
        self.date = dateTimestamp.dateValue()
        self.type = type
        self.source = source
        self.createdBy = createdBy
        self.notes = data["notes"] as? String
        self.tags = data["tags"] as? [String] ?? []
        self.foodItems = [] // TODO: Decode food items when needed
    }
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
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
        
        // TODO: Add foodItems serialization when needed
        
        return data
    }
}

// MARK: - Symptom Firestore Extension
extension Symptom {
    init(from document: DocumentSnapshot) throws {
        let data = document.data()
        guard let data = data else {
            throw NSError(domain: "SymptomDecoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data found"])
        }
        
        guard let id = data["id"] as? String,
              let dateTimestamp = data["date"] as? Timestamp,
              let stoolTypeRaw = data["stoolType"] as? Int,
              let stoolType = StoolType(rawValue: stoolTypeRaw),
              let painLevelRaw = data["painLevel"] as? Int,
              let painLevel = PainLevel(rawValue: painLevelRaw),
              let urgencyLevelRaw = data["urgencyLevel"] as? Int,
              let urgencyLevel = UrgencyLevel(rawValue: urgencyLevelRaw),
              let createdBy = data["createdBy"] as? String else {
            throw NSError(domain: "SymptomDecoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid symptom data"])
        }
        
        self.id = id
        self.date = dateTimestamp.dateValue()
        self.stoolType = stoolType
        self.painLevel = painLevel
        self.urgencyLevel = urgencyLevel
        self.createdBy = createdBy
        self.notes = data["notes"] as? String
        self.tags = data["tags"] as? [String] ?? []
    }
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "date": Timestamp(date: date),
            "stoolType": stoolType.rawValue,
            "painLevel": painLevel.rawValue,
            "urgencyLevel": urgencyLevel.rawValue,
            "createdBy": createdBy,
            "tags": tags
        ]
        
        if let notes = notes {
            data["notes"] = notes
        }
        
        return data
    }
}
