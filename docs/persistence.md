# Persistence (SwiftData)

## Overview

GutCheck stores everything on-device in a single SwiftData store. There is no backend, no cloud account, and no sync layer — a record is durable the moment it is saved.

This replaced a hybrid arrangement in which private data was written to encrypted files on disk, non-private data was written to Firestore, and a Core Data store acted as an offline queue between them. See [Legacy migration](#legacy-migration) for how existing data is carried over.

## The stack

### `SwiftDataStack`

Owns the app's one `ModelContainer`.

- **Schema**: declared in `SwiftDataStack.schema`. Anything added there must also be considered in `LegacyStoreMigrator`.
- **Location**: `Application Support/GutCheck/GutCheck.store`, kept out of the Documents directory so it is not exposed via file sharing.
- **Context**: a single main-actor context. Every repository is `@MainActor`, so one context keeps object identity consistent without cross-context merge handling. The dataset is one person's health log, not a shared corpus.
- **Failure mode**: a container that cannot open traps. Continuing would silently discard every entry the user makes.

The container is injected into the view hierarchy via `.modelContainer(...)` in `GutCheckApp`, and exposed as an environment object for the few screens that want to inspect it.

### Data Protection

The store holds PII and health data — date of birth, weight, height, meals, symptoms — so its file protection is set explicitly rather than left at the iOS default:

```swift
.protectionKey: FileProtectionType.completeUnlessOpen
```

The default for app container files is `completeUntilFirstUserAuthentication`, which leaves the file readable from the first unlock after boot until power off.

`.completeUnlessOpen` rather than `.complete` is deliberate, carried over from the Core Data stack this replaced: `.complete` makes the file unreadable whenever the device is locked, which breaks the `BGProcessingTask` insight refresh, since background tasks typically run while locked. `.completeUnlessOpen` protects the file at rest but lets a handle opened before locking keep working.

Protection is applied to the store **and** its SQLite journal files (`-wal`, `-shm`). Protecting only the store would leave recent writes readable.

## Entities

Persistence entities live in `Models/Persistence/` and are separate from the domain structs the rest of the app uses:

| Entity | Domain model |
|---|---|
| `StoredMeal` | `Meal` |
| `StoredSymptom` | `Symptom` |
| `StoredMedication` | `MedicationRecord` |
| `StoredMedicationDose` | `MedicationDoseLog` |
| `StoredReminderSettings` | `ReminderSettings` |
| `StoredUserProfile` | `User` |
| `StoredDataDeletionRequest` | `DataDeletionRequest` |

Keeping the two layers separate means view models and views keep their value semantics — no `@Model` reference type leaks into a struct-shaped codebase — and the store schema can change without rippling through every screen.

Each entity provides `init(_:)`, `apply(_:)` and `domainModel`. `apply` deliberately does not overwrite `createdAt`: it records when a record was first logged, and an edit should not rewrite that.

### Conventions

- **Enums are stored as raw values** so `#Predicate` can filter on them, and an unrecognised value from an older build degrades to a default instead of failing to load the row.
- **Nested `Codable` values are stored as JSON blobs** (`foodItemsData`, `dosageData`) rather than modelled as relationships. Nothing queries into them, so a relationship would buy nothing and cost a join. `StoredMeal.foodItemsData` uses `@Attribute(.externalStorage)` because a long ingredient breakdown can run to several kilobytes.
- **`id` is `@Attribute(.unique)`**, which is what makes repository `save` an upsert.

## Ownership

There are no accounts. `LocalUserService` creates one profile on first launch, and every record's `createdBy` points at that profile's id.

`LocalUserService.currentProfileId` is `nonisolated` and backed by `UserDefaults` rather than by the loaded profile. Repositories, background insight generation and several SwiftUI helpers all need the owning id on paths that are not on the main actor, and forcing an actor hop for a value that never changes during a launch would push `await` into a dozen call sites for nothing. It is written whenever the profile is loaded or created, which happens during `init` — before any repository can run a query.

## Legacy migration

`LegacyStoreMigrator` runs once, on first launch after upgrading, before the UI appears. It is gated on a versioned `UserDefaults` flag so a later migration can be added without re-running this one.

It reads two sources, in this order:

1. **Encrypted files** written by `LocalStorageService` (`Documents/PrivateData/*.encrypted`). These hold complete `Codable` copies.
2. **The Core Data store** (`GutCheck.sqlite`), opened read-only. These rows dropped tags and most food-item detail, so when the same id appears in both, the file version wins.

Two things are worth knowing about it:

- **Nothing is deleted.** If the import goes wrong the original data is still where it was, and the flag is left unset so the next launch retries rather than stranding the user's history.
- **Every imported record is re-owned by the local profile.** `createdBy` used to hold a Firebase UID; the local profile id is a freshly generated UUID, and every repository query filters on it. Carrying the old UID across would import the whole history into a store where nothing could ever find it.

The legacy Core Data model (`GutCheck.xcdatamodeld`) is still in the target because the migrator needs its generated `NSManagedObject` subclasses to read the old store. It can be removed once enough releases have passed that no installed build predates the migration.

## Testing

`SwiftDataStack.inMemoryContainer()` returns a container with the same schema backed by memory, for tests that need a real store. Tests that only exercise view-model logic should inject a mock through the repository protocols instead — see `GutCheckTests/Mocks/`.

## See also

- [repository-pattern.md](repository-pattern.md) — the data access layer over this store
- [compliance.md](compliance.md) — what this means for GDPR/CCPA/HIPAA posture
