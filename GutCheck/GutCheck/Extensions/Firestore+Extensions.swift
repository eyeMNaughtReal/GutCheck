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
// Note: FirestoreModel implementation moved to Meal.swift to avoid duplicates
// This extension was causing "Invalid redeclaration" errors

// MARK: - Symptom Firestore Extension
// Note: FirestoreModel implementation moved to Symptom.swift to avoid duplicates
// This extension was causing "Invalid redeclaration" errors

// MARK: - Enhanced MealRepository for Food Items
// Note: Disabled until meal functionality is ready
/*
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
*/

// MARK: - FoodItem Firestore Extension
// Note: Dictionary conversion methods moved to FoodItem.swift to avoid duplicates
// This extension was causing potential conflicts with the struct implementation
