# GutCheck Developer Guide

This guide provides a comprehensive overview of the GutCheck iOS app's architecture, development processes, and best practices. It is intended for contributors, maintainers, and anyone onboarding to the project.

---

## 1. Project Overview
GutCheck is a SwiftUI-based iOS app for gastrointestinal symptom tracking, meal logging, and AI-powered analysis. It leverages Firebase, Core Data, and HealthKit for data management and analytics.

---

## 2. File & Folder Structure

- **GutCheck/**: Main app entry, configuration, and resources.
- **Models/**: Core data structures (Meal, Symptom, UserProfile, FoodItem).
- **Views/**: UI screens, organized by feature (Dashboard, MealLogging, SymptomLogging, Calendar, Analysis, Settings, Authentication).
- **ViewModels/**: Logic and bindings for each view.
- **Services/**: Utilities and shared logic (AI, Firebase, Sync, Local Storage, Barcode, HealthKit, Mock Data).
- **Resources/**: Assets, localization, privacy policy, Firebase config.
- **Tests/**: Unit and integration tests for all major features.

---

## 3. App Flow & User Journey

- **Authentication**: Users sign in via Google, Apple, or Email. (Apple Sign In is currently commented out; see AuthService.swift.)
- **Dashboard**: Central hub showing today's logs and quick actions.
- **Meal Logging**: Users log meals via text, barcode, or LiDAR. AI provides nutrition breakdowns.
- **Symptom Logging**: Users log symptoms with scales and explanations.
- **Calendar**: Unified view of meals and symptoms by date.
- **Analysis**: AI-driven insights, trigger alerts, and deep dives.
- **Settings**: Preferences, export, privacy, and debug tools.

---

## 4. Key Processes

### Authentication
- Uses Firebase Auth (Google, Email). Apple Sign In code is present but disabled due to developer account limitations.
- Auth state is observed in `GutCheckApp.swift`.

### Meal Logging
- Users can log meals manually, via barcode, or LiDAR scanning.
- Nutrition breakdown and confirmation screens guide the process.
- Data is stored in Firestore and/or Core Data.

### Symptom Logging
- Users log symptoms with severity, type, and notes.
- Symptom history and explanations are available.

### AI Analysis
- `AIAnalysisService.swift` processes meal and symptom data to find correlations and trends.
- Insights and trigger alerts are surfaced in the Analysis section.

### Data Sync & Offline Support
- `SyncQueueManager.swift` handles offline data and syncs with Firebase when online.
- `LocalStorageService.swift` manages Core Data for local persistence.

### Testing
- Unit tests for all major features in `Tests/`.
- UI tests for authentication and core flows.

### CI/CD
- GitHub Actions workflow (`.github/workflows/ci.yml`) runs tests, builds, and checks code coverage on PRs.
- Caching and code coverage are enabled for efficient CI.

---

## 5. Development & Contribution Guidelines

- Follow the Swift file structure outlined in `GutCheck_Architecture_Plan.md`.
- Use feature branches and submit PRs for review.
- Write unit and UI tests for new features.
- Keep Apple Sign In code commented out unless you have a paid developer account.
- Use the DebugView for development-only tools; remove before production.

---

## 6. Troubleshooting & Best Practices

- **Build Issues**: If you encounter build errors, try deleting DerivedData and resetting Swift Package dependencies.
- **Simulator Issues**: Reset the simulator or clean the build folder if UI tests fail to launch.
- **Firebase**: Ensure `GoogleService-Info.plist` is present (not checked into git).
- **CI Failures**: Check the GitHub Actions logs for dependency or test failures.

---

## 7. Resources
- [GutCheck_Architecture_Plan.md](GutCheck_Architecture_Plan.md): Detailed file structure and flow diagrams.
- [CONTRIBUTING.md](CONTRIBUTING.md): Contribution process and code style.
- [README.md](README.md): Project introduction and setup instructions.

---

_Last Updated: August 2025_
