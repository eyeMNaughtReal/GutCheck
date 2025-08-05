//
//  FirebaseCollectionManager.swift
//  GutCheck
//
//  Centralized manager for Firebase Firestore collection references
//

@preconcurrency import FirebaseFirestore

class FirebaseCollectionManager {
    static let shared = FirebaseCollectionManager()
    
    private let firestore = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Collection Names
    private enum CollectionName {
        static let users = "users"
        static let meals = "meals"
        static let symptoms = "symptoms"
        static let activities = "activities"
        static let reminders = "reminders"
        static let reminderSettings = "reminderSettings"
        static let test = "test"
        static let foodItems = "foodItems"
    }
    
    // MARK: - Storage Paths
    private enum StoragePath {
        static let profileImages = "profile_images"
        static let users = "users"
    }
    
    // MARK: - User Collection
    func usersCollection() -> CollectionReference {
        return firestore.collection(CollectionName.users)
    }
    
    func userDocument(_ userId: String) -> DocumentReference {
        return usersCollection().document(userId)
    }
    
    func userMealsCollection(_ userId: String) -> CollectionReference {
        return userDocument(userId).collection(CollectionName.meals)
    }
    
    func userMealDocument(_ userId: String, mealId: String) -> DocumentReference {
        return userMealsCollection(userId).document(mealId)
    }
    
    // MARK: - Symptoms Collection
    func userSymptomsCollection(_ userId: String) -> CollectionReference {
        return userDocument(userId).collection(CollectionName.symptoms)
    }
    
    func userSymptomDocument(_ userId: String, symptomId: String) -> DocumentReference {
        return userSymptomsCollection(userId).document(symptomId)
    }
    
    // MARK: - Activities Collection
    func userActivitiesCollection(_ userId: String) -> CollectionReference {
        return userDocument(userId).collection(CollectionName.activities)
    }
    
    func userActivityDocument(_ userId: String, activityId: String) -> DocumentReference {
        return userActivitiesCollection(userId).document(activityId)
    }
    
    // MARK: - Reminders Collection
    func userRemindersCollection(_ userId: String) -> CollectionReference {
        return userDocument(userId).collection(CollectionName.reminders)
    }
    
    func userReminderDocument(_ userId: String, reminderId: String) -> DocumentReference {
        return userRemindersCollection(userId).document(reminderId)
    }
    
    // MARK: - Global Collections (if needed)
    func globalMealsCollection() -> CollectionReference {
        return firestore.collection(CollectionName.meals)
    }
    
    func globalSymptomsCollection() -> CollectionReference {
        return firestore.collection(CollectionName.symptoms)
    }
    
    // MARK: - Batch Operations
    func batch() -> WriteBatch {
        return firestore.batch()
    }
    
    // MARK: - Additional Collections
    func reminderSettingsCollection() -> CollectionReference {
        return firestore.collection(CollectionName.reminderSettings)
    }
    
    func testCollection() -> CollectionReference {
        return firestore.collection(CollectionName.test)
    }
    
    func testDocument(_ documentId: String) -> DocumentReference {
        return testCollection().document(documentId)
    }
    
    // MARK: - Food Items Subcollection
    func mealFoodItemsCollection(_ userId: String, mealId: String) -> CollectionReference {
        return userMealDocument(userId, mealId: mealId).collection(CollectionName.foodItems)
    }
    
    // MARK: - Storage Path Helpers
    func profileImagesStoragePath() -> String {
        return StoragePath.profileImages
    }
    
    func userStoragePath() -> String {
        return StoragePath.users
    }
    
    // MARK: - Query Helpers
    func createUserQuery(_ userId: String, collection: String) -> Query {
        return firestore.collection(CollectionName.users)
            .document(userId)
            .collection(collection)
    }
    
    func queryMealsByUser(_ userId: String) -> Query {
        return firestore.collection(CollectionName.meals).whereField("userId", isEqualTo: userId)
    }
    
    func querySymptomsByUser(_ userId: String) -> Query {
        return firestore.collection(CollectionName.symptoms).whereField("userId", isEqualTo: userId)
    }
}