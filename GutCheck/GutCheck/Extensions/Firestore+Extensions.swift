//
//  Firestore+Extensions.swift
//  GutCheck
//
//  Extensions to make models compatible with Firestore
//  Note: Protocol conformance is declared in the model files themselves
//

import Foundation
import FirebaseFirestore

// MARK: - Meal Firestore Extension
// Remove the ": FirestoreModel" since it's declared elsewhere
extension Meal {
    init(from document: DocumentSnapshot) throws {
        let data = document.data()
        guard let data = data else {
            throw RepositoryError.invalidData("No data found in document")
        }
        
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let dateTimestamp = data["date"] as? Timestamp,
              let typeRaw = data["type"] as? String,
              let type = MealType(rawValue: typeRaw),
              let sourceRaw = data["source"] as? String,
              let source = MealSource(rawValue: sourceRaw),
              let createdBy = data["createdBy"] as? String else {
            throw RepositoryError.invalidData("Invalid meal data structure")
        }
        
        self.id = id
        self.name = name
        self.date = dateTimestamp.dateValue()
        self.type = type
        self.source = source
        self.createdBy = createdBy
        self.notes = data["notes"] as? String
        self.tags = data["tags"] as? [String] ?? []
        
        // Handle food items - initialize as empty for now
        // Food items are loaded separately via subcollection
        self.foodItems = []
    }
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "name": name,
            "date": Timestamp(date: date),
            "type": type.rawValue,
            "source": source.rawValue,
            "createdBy": createdBy,
            "tags": tags,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let notes = notes {
            data["notes"] = notes
        }
        
        return data
    }
}

// MARK: - Symptom Firestore Extension
// Remove the ": FirestoreModel" since it's declared elsewhere
extension Symptom {
    init(from document: DocumentSnapshot) throws {
        let data = document.data()
        guard let data = data else {
            throw RepositoryError.invalidData("No data found in document")
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
            throw RepositoryError.invalidData("Invalid symptom data structure")
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
            "tags": tags,
            "createdAt": Timestamp(date: Date())
        ]
        
        if let notes = notes {
            data["notes"] = notes
        }
        
        return data
    }
}

// MARK: - Enhanced MealRepository for Food Items
extension MealRepository {
    /// Save a meal with its food items as subcollection
    func saveWithFoodItems(_ meal: Meal) async throws {
        // Save the main meal document
        try await save(meal)
        
        // Save food items as subcollection
        let mealRef = firestore.collection(collectionName).document(meal.id)
        let foodItemsRef = mealRef.collection("foodItems")
        
        // Clear existing food items
        let existingFoodItems = try await foodItemsRef.getDocuments()
        for document in existingFoodItems.documents {
            try await document.reference.delete()
        }
        
        // Save new food items
        for foodItem in meal.foodItems {
            let foodItemData = foodItem.toFirestoreData()
            try await foodItemsRef.document(foodItem.id).setData(foodItemData)
        }
    }
    
    /// Fetch a meal with its food items
    func fetchWithFoodItems(id: String) async throws -> Meal? {
        guard var meal = try await fetch(id: id) else {
            return nil
        }
        
        // Load food items from subcollection
        let foodItemsRef = firestore.collection(collectionName).document(id).collection("foodItems")
        let foodItemsSnapshot = try await foodItemsRef.getDocuments()
        
        meal.foodItems = try foodItemsSnapshot.documents.compactMap { document in
            try FoodItem(from: document)
        }
        
        return meal
    }
}

// MARK: - FoodItem Firestore Extension
extension FoodItem {
    init(from document: DocumentSnapshot) throws {
        let data = document.data()
        guard let data = data else {
            throw RepositoryError.invalidData("No data found in food item document")
        }
        
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let quantity = data["quantity"] as? String else {
            throw RepositoryError.invalidData("Invalid food item data structure")
        }
        
        self.id = id
        self.name = name
        self.quantity = quantity
        self.estimatedWeightInGrams = data["estimatedWeightInGrams"] as? Double
        self.ingredients = data["ingredients"] as? [String] ?? []
        self.allergens = data["allergens"] as? [String] ?? []
        self.barcodeValue = data["barcodeValue"] as? String
        self.isUserEdited = data["isUserEdited"] as? Bool ?? false
        self.nutritionDetails = data["nutritionDetails"] as? [String: String] ?? [:]
        
        // Parse nutrition info
        if let nutritionData = data["nutrition"] as? [String: Any] {
            self.nutrition = NutritionInfo(
                calories: nutritionData["calories"] as? Int,
                protein: nutritionData["protein"] as? Double,
                carbs: nutritionData["carbs"] as? Double,
                fat: nutritionData["fat"] as? Double,
                fiber: nutritionData["fiber"] as? Double,
                sugar: nutritionData["sugar"] as? Double,
                sodium: nutritionData["sodium"] as? Double
            )
        } else {
            self.nutrition = NutritionInfo()
        }
        
        // Parse source
        if let sourceRaw = data["source"] as? String,
           let source = FoodInputSource(rawValue: sourceRaw) {
            self.source = source
        } else {
            self.source = .manual
        }
    }
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "name": name,
            "quantity": quantity,
            "ingredients": ingredients,
            "allergens": allergens,
            "source": source.rawValue,
            "isUserEdited": isUserEdited,
            "nutritionDetails": nutritionDetails,
            "nutrition": [
                "calories": nutrition.calories as Any,
                "protein": nutrition.protein as Any,
                "carbs": nutrition.carbs as Any,
                "fat": nutrition.fat as Any,
                "fiber": nutrition.fiber as Any,
                "sugar": nutrition.sugar as Any,
                "sodium": nutrition.sodium as Any
            ]
        ]
        
        if let weight = estimatedWeightInGrams {
            data["estimatedWeightInGrams"] = weight
        }
        
        if let barcode = barcodeValue {
            data["barcodeValue"] = barcode
        }
        
        return data
    }
}
