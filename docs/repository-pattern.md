# Repository Pattern Documentation

## Overview

The GutCheck app uses a standardized repository pattern for all data persistence operations. This provides a clean separation between business logic and data access, making the code more testable and maintainable.

Repositories are the only part of the app that touch SwiftData. Everything above them — view models, services, views — works with plain `Codable` value types.

## Architecture

### Base Components

#### `LocalRecord` Protocol
Required for all domain models that repositories persist:
- Must be `Codable` and `Identifiable`
- Must have `id` and `createdBy` properties

`createdBy` holds the local profile id. There are no accounts, so it never varies in practice; it is retained so records stay attributable across a profile reset, and so a future multi-profile mode has somewhere to hang.

#### Per-entity repositories

There is no generic base class. `#Predicate` has to be built against a concrete `@Model` type, so a shared base could not express any of the filters the app needs and every useful method would end up overridden anyway. Each repository is written out against its own entity in `Services/Repository/SwiftDataRepository.swift`.

They share a small `Store` helper that wraps fetch and save, turning any SwiftData failure into a `RepositoryError`.

Every repository is `@MainActor`. The store is a modestly sized personal dataset and every consumer is already on the main actor, so a single `ModelContext` keeps object identity consistent without cross-context merge handling.

#### `@Model` entities

Each domain struct has a matching SwiftData entity in `Models/Persistence/` — `StoredMeal`, `StoredSymptom`, `StoredMedication`, and so on. Each entity provides:
- `init(_ domainModel:)` to create a row
- `apply(_ domainModel:)` to update one in place, preserving `createdAt`
- `domainModel` to read one back out

Entities store enum **raw values** rather than the enums themselves, so `#Predicate` can filter on them and an unrecognised value from an older build degrades to a default instead of failing to load the row.

Nested `Codable` values (a meal's food items, a medication's dosage) are stored as JSON blobs rather than modelled as relationships. Nothing queries *into* those values — food items are always loaded as part of their meal — so a relationship would buy nothing and cost a join plus a second entity to keep in step with the struct.

`id` carries `@Attribute(.unique)`, which is what makes `save` an upsert: saving an edited record updates the existing row rather than inserting a duplicate.

## Current Implementations

### `MealRepository`
- `fetchMealsForDate(_ date: Date, userId: String)` — meals for a specific day
- `fetchMealsForDateRange(startDate:endDate:userId:)` — meals in a window
- `fetchRecentMeals(userId: String, limit: Int)` — most recent meals
- `fetchMealsPage(userId: String, offset: Int, limit: Int)` — one page, newest first
- `fetchAll(userId: String)` — full history, for trigger analysis
- `deleteAll(userId: String)` — used by data deletion

### `SymptomRepository`
Same shape as `MealRepository`, plus:
- `getSymptoms(for date: Date)` — convenience that resolves the profile itself

### `MedicationRepository` / `MedicationDoseRepository`
- `fetchActiveMedications(userId:)`, `fetchAllMedications(userId:)`
- `fetchByHealthKitUUID(_:userId:)` — so a repeat HealthKit sync updates rather than duplicates
- `fetchDosesForDate(_:userId:)`, `fetchRecentDoses(userId:limit:)`, `fetchDoses(medicationId:userId:)`

### `ReminderSettingsRepository`
One settings row per profile, keyed on `createdBy`.

### `DataDeletionRequestRepository`
Stores the record of what the user asked to erase and when it was carried out.

## Date range conventions

Single-day queries use a half-open range `[startOfDay, nextDay)`. A closed upper bound double-counts a record landing exactly on midnight, putting it in both adjacent days.

Explicit date-range queries (`fetchMealsForDateRange`) are inclusive at both ends, matching how callers pass a user-selected window.

## Usage Examples

### Basic CRUD Operations

```swift
// Save a meal — inserts, or updates in place if the id already exists
let meal = Meal(...)
try await MealRepository.shared.save(meal)

// Fetch a specific meal
if let meal = try await MealRepository.shared.fetch(id: "meal-123") {
    print("Found meal: \(meal.name)")
}

// Delete a meal
try await MealRepository.shared.delete(id: "meal-123")
```

### Filtering

There is no generic `query` entry point any more. Filters that the store can express live on the repository as named methods; anything more specific is applied in memory by the caller:

```swift
// Breakfasts from the last 30 days
let recent = try await MealRepository.shared.fetchMealsForDateRange(
    startDate: thirtyDaysAgo,
    endDate: .now,
    userId: LocalUserService.currentProfileId
)
let breakfasts = recent.filter { $0.type == .breakfast }
```

If a filter runs over the whole history and starts to matter for performance, add a method with a `#Predicate` rather than filtering in the view model.

### Pagination

Paged reads use `fetchOffset`/`fetchLimit` rather than a cursor. A local store has no concurrent writer to skew the window, so an offset is stable between calls in a way it would not have been against a shared backend:

```swift
let page = try await MealRepository.shared.fetchMealsPage(
    userId: LocalUserService.currentProfileId,
    offset: loadedCount,
    limit: 20
)
```

### In ViewModels

Inject the protocol, not the concrete type, so tests can substitute a mock:

```swift
@MainActor
@Observable class MealDetailViewModel {
    private let repository: any MealRepositoryProtocol

    init(meal: Meal, repository: any MealRepositoryProtocol = MealRepository.shared) {
        self.repository = repository
        // ...
    }
}
```

## Adding New Repositories

1. **Add the `@Model` entity** in `Models/Persistence/`, with `@Attribute(.unique) var id` and the three mapping members (`init(_:)`, `apply(_:)`, `domainModel`).

2. **Register it in the schema** — `SwiftDataStack.schema`. If old Core Data rows need to carry over, also handle it in `LegacyStoreMigrator`.

3. **Conform the domain model to `LocalRecord`**:
```swift
struct MyModel: Identifiable, Codable, LocalRecord {
    var id: String
    var createdBy: String
    // ...
}
```

4. **Declare a protocol** in `RepositoryProtocols.swift` so view models can be tested against a mock.

5. **Write the repository**:
```swift
@MainActor
final class MyModelRepository: MyModelRepositoryProtocol {
    static let shared = MyModelRepository()

    private init() {}

    func save(_ item: MyModel) async throws {
        var model = item
        if model.createdBy.isEmpty {
            model.createdBy = LocalUserService.currentProfileId
        }
        if let existing = try Store.first(Self.descriptor(id: model.id)) {
            existing.apply(model)
        } else {
            Store.context.insert(StoredMyModel(model))
        }
        try Store.save()
    }

    private static func descriptor(id: String) -> FetchDescriptor<StoredMyModel> {
        FetchDescriptor<StoredMyModel>(predicate: #Predicate { $0.id == id })
    }
}
```

6. **Add to `RepositoryManager`** (optional, for dependency injection).

## Error Handling

### `RepositoryError` Types
- `.noActiveProfile` — no local profile is available
- `.recordNotFound(String)` — record doesn't exist
- `.invalidData(String)` — data format issues
- `.storageError(Error)` — underlying SwiftData failure

`ErrorHandlingService.handle(_:)` maps these to a user-facing title and message.

There is no retry logic and no network-awareness layer: reads and writes are local, so they either succeed or fail for a reason retrying will not fix.

This standardized approach ensures all data operations in GutCheck are reliable, consistent, and maintainable.
