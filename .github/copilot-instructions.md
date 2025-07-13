# Copilot Instructions for GutCheck

## Project Overview
GutCheck is a SwiftUI iOS app for tracking meals, symptoms, and AI-powered health insights. It integrates with Firebase, HealthKit, Core Data, and uses LiDAR/ARKit for food portion estimation. The app is modular, privacy-focused, and designed for extensibility.

## Architecture & Key Patterns
- **Views/**: Organized by feature (Dashboard, Calendar, Meal, Bowel, Profile, etc.). Each feature has its own folder.
- **Models/**: Data structures (e.g., `Meal`, `Symptom`, `UserProfile`) are in `Models/`.
- **ViewModels/**: State and logic for each feature, using `@StateObject` and `@ObservedObject`.
- **Services/**: External integrations (Firebase, HealthKit, AI, Sync, Local Storage) are in `Services/`.
- **Extensions/**: Utility extensions (e.g., `Date+Extensions.swift`) are in `Extensions/`.
- **Components/**: Reusable UI elements (e.g., `ProfileAvatarButton`) are in `Views/Components/`.

## Data Flow & Integration
- **Firebase**: Used for authentication and cloud data sync. User data is scoped to the authenticated user.
- **HealthKit**: Optional sync for health data.
- **Core Data**: Local persistence for offline support.
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
- **Secrets**: `GoogleService-Info.plist` is required for Firebase but not checked into git.

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
- `Services/` — Integrations (Firebase, HealthKit, AI, etc.)
- `Extensions/` — Utility extensions
- `GutCheck.xcodeproj` — Xcode project
- `.github/workflows/ci.yml` — CI/CD pipeline

---

For more, see `README.md` and `GutCheck_Developer_Guide.md`.
