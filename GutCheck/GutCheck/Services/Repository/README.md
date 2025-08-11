# Repository Pattern Documentation

## Overview

The GutCheck app uses a standardized repository pattern for all data persistence operations. This provides a clean separation between business logic and data access, making the code more testable and maintainable.

## Architecture

### Base Components

#### `FirebaseRepository` Protocol
Defines the standard interface that all repositories must implement:
- `save(_ item: Model) async throws`
- `fetch(id: String) async throws -> Model?`
- `fetchAll(for userId: String) async throws -> [Model]`
- `delete(id: String) async throws`
- `query(_ queryBuilder: (Query) -> Query) async throws -> [Model]`

#### `FirestoreModel` Protocol
Required for all data models used with repositories:
- Must be `Codable` and `Identifiable`
- Must have `id` and `createdBy` properties
- Must implement `init(from document: DocumentSnapshot)`
- Must implement `toFirestoreData() -> [String: Any]`

#### `BaseFirebaseRepository<T>`
Generic base class that provides:
- ✅ **CRUD Operations**: Standard create, read, update, delete
- ✅ **Network Monitoring**: Automatic offline/online detection
- ✅ **Retry Logic**: Exponential backoff for transient failures
- ✅ **Error Handling**: Comprehensive Firestore error mapping
- ✅ **User Scoping**: All data automatically scoped to authenticated user
- ✅ **Logging**: Detailed operation logging for debugging

## Current Implementations

### `MealRepository`
Handles all meal-related data operations:
- `fetchMealsForDate(_ date: Date, userId: String)` - Get meals for specific date
- `fetchRecentMeals(userId: String, limit: Int)` - Get recent meals

### `SymptomRepository`
Handles all symptom-related data operations:
- `fetchSymptomsForDate(_ date: Date, userId: String)` - Get symptoms for specific date
- `getSymptoms(for date: Date)` - Convenience method with auto user ID
- `fetchSymptomsByPainLevel(_ painLevel: PainLevel, userId: String)` - Filter by pain level
- `fetchRecentSymptoms(userId: String, limit: Int)` - Get recent symptoms

### `ReminderSettingsRepository`
Handles reminder settings persistence (defined in `ReminderSettingsService.swift`)

## Usage Examples

### Basic CRUD Operations

```swift
// Save a meal
let meal = Meal(...)
try await MealRepository.shared.save(meal)

// Fetch a specific meal
if let meal = try await MealRepository.shared.fetch(id: "meal-123") {
    print("Found meal: \(meal.name)")
}

// Delete a meal
try await MealRepository.shared.delete(id: "meal-123")
```

### Custom Queries

```swift
// Find all breakfast meals
let breakfastMeals = try await MealRepository.shared.query { query in
    query
        .whereField("createdBy", isEqualTo: userId)
        .whereField("type", isEqualTo: "breakfast")
        .order(by: "date", descending: true)
}
```

### In ViewModels

```swift
class MealDetailViewModel: DetailViewModel<Meal> {
    private let repository: MealRepository
    
    init(meal: Meal, repository: MealRepository = MealRepository.shared) {
        self.repository = repository
        super.init(entity: meal)
    }
    
    override func saveEntity() async {
        await executeWithSaving {
            try await repository.save(self.entity)
        }
    }
}
```

## Benefits Achieved

### ✅ **Consistency**
- All repositories follow the same patterns
- Identical error handling across the app
- Standardized logging and monitoring

### ✅ **Testability**
- Easy to mock repositories for unit tests
- Dependency injection ready
- Clear separation of concerns

### ✅ **Reliability**
- Automatic retry logic for network issues
- Comprehensive error handling
- Offline/online state management

### ✅ **Maintainability**
- Changes to data layer affect only repository implementations
- Easy to add new repositories following the same pattern
- Clear documentation and examples

## Adding New Repositories

To add a new repository:

1. **Ensure your model implements `FirestoreModel`**:
```swift
extension MyModel: FirestoreModel {
    init(from document: DocumentSnapshot) throws {
        // Implementation
    }
    
    func toFirestoreData() -> [String: Any] {
        // Implementation
    }
}
```

2. **Create the repository class**:
```swift
class MyModelRepository: BaseFirebaseRepository<MyModel> {
    static let shared = MyModelRepository()
    
    private init() {
        super.init(collectionName: "myModels")
    }
    
    // Add custom query methods here
}
```

3. **Add to RepositoryManager** (optional for dependency injection):
```swift
class RepositoryManager {
    // ...
    lazy var myModelRepository: MyModelRepository = MyModelRepository.shared
}
```

## Error Handling

The repository pattern provides comprehensive error handling:

### `RepositoryError` Types
- `.noAuthenticatedUser` - User not signed in
- `.documentNotFound(String)` - Document doesn't exist
- `.invalidData(String)` - Data format issues
- `.firebaseError(Error)` - Underlying Firebase errors

### Automatic Retry
- Exponential backoff for transient failures
- No retry for authentication/permission errors
- Configurable retry attempts (default: 3)

### Network Awareness
- Automatic detection of offline/online state
- Operations work with Firestore's offline cache
- Clear logging of network status

This standardized approach ensures all data operations in GutCheck are reliable, consistent, and maintainable.

