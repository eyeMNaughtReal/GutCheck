# Copilot Instructions for GutCheck

## Project Overview
GutCheck is a SwiftUI iOS app for tracking meals, symptoms, and AI-powered health insights. It stores everything on-device with SwiftData, integrates with HealthKit, and uses LiDAR/ARKit for food portion estimation. There is no backend and no user accounts. The app is modular, privacy-focused, and designed for extensibility.

## Architecture & Key Patterns
- **Views/**: Organized by feature (Dashboard, Calendar, Meal, Bowel, Profile, etc.). Each feature has its own folder.
- **Models/**: Data structures (e.g., `Meal`, `Symptom`, `UserProfile`) are in `Models/`.
- **ViewModels/**: State and logic for each feature, using `@StateObject` and `@ObservedObject`.
- **Services/**: Integrations and infrastructure (SwiftData store, HealthKit, AI, Local Storage) are in `Services/`.
- **Extensions/**: Utility extensions (e.g., `Date+Extensions.swift`) are in `Extensions/`.
- **Components/**: Reusable UI elements (e.g., `ProfileAvatarButton`) are in `Views/Components/`.

## Data Flow & Integration
- **SwiftData**: The single source of truth. `SwiftDataStack` owns the `ModelContainer`; repositories in `Services/Repository/` map between `@Model` rows and the value-type domain models the rest of the app uses. Nothing above the repository layer touches SwiftData.
- **Local profile**: There are no accounts. `LocalUserService` owns one device-local profile, and its id is what every record's `createdBy` points at.
- **HealthKit**: Optional sync for health data.
- **AI/ML**: Used for food recognition and insights (see `AIAnalysisService.swift`).
- **Notifications**: Local reminders are managed via `UNUserNotificationCenter` (see `UserRemindersView`).

## UI/UX Conventions
- **ColorTheme**: All colors are defined in `Views/Components/ColorTheme.swift` and used throughout the app for consistency.
- **Navigation**: Use `NavigationStack` (iOS 16+) or `NavigationView` for all views with navigation. `NavigationLink` only works inside these contexts.
- **Profile/Reminders**: Access the profile and reminders via the avatar button in the top right of main views. Profile actions use custom `ProfileActionRow` components.
- **Sheets/Modals**: When presenting views modally (e.g., profile), wrap in a `NavigationStack` to enable navigation links.

## Developer Workflows
- **Build**: Open `GutCheck.xcodeproj` in Xcode and build/run as a standard SwiftUI app.
- **Test**: Unit and UI tests are in `GutCheckTests/` and `GutCheckUITests/`.
- **CI/CD**: GitHub Actions workflow in `.github/workflows/ci.yml` runs tests and checks code coverage on PRs.
- **Secrets**: `Secrets.swift` holds the USDA FoodData Central API key and is not checked into git. CI generates a stub.

## Project-Specific Patterns
- **Feature Folders**: Group files by feature, not by type, for scalability.
- **State Management**: Use `@StateObject` for view models at the feature root, pass via `@ObservedObject` or bindings.
- **Extensions**: Centralize all extensions in `Extensions/` and import as needed.
- **Preview**: Always wrap views in `NavigationStack` for previews if they use navigation.

## Example: Adding a New Feature
1. Create a new folder in `Views/` (e.g., `Views/Analysis/`).
2. Add view, view model, and any supporting files to that folder.
3. Register new models in `Models/` if needed.
4. Use `ColorTheme` for all colors.
5. Add navigation via `NavigationStack` and `NavigationLink`.

## Key Files & Directories
- `Views/` — All UI, grouped by feature
- `Models/` — Data models
- `ViewModels/` — State and logic
- `Services/` — Integrations and infrastructure (SwiftData, HealthKit, AI, etc.)
- `Extensions/` — Utility extensions
- `GutCheck.xcodeproj` — Xcode project
- `.github/workflows/ci.yml` — CI/CD pipeline

---

For more, see `README.md` and `GutCheck_Developer_Guide.md`.
