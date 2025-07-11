# GutCheck iOS Project Structure 📁

This document outlines the organized folder structure for the GutCheck iOS application, following MVVM architecture and iOS development best practices.

---

## 📂 Root Structure

```
GutCheck/
├── .git/                       # Git repository (hidden)
├── .gitignore                  # Git ignore rules
├── FOLDER_STRUCTURE.md         # This documentation
├── LICENSE                     # MIT License
├── README.md                   # Project overview
│
└── GutCheck/                   # Xcode project folder
    ├── CONTRIBUTING.md         # Contribution guidelines
    ├── GutCheck.xcodeproj/     # Xcode project file
    │
    ├── GutCheck/               # Main app target
    │   ├── GutCheckApp.swift   # App entry point
    │   ├── ContentView.swift   # Root view (will be replaced)
    │   ├── GoogleService-Info.plist # Firebase config (gitignored)
    │   │
    │   ├── 📁 Models/          # Data models and entities
    │   ├── 📁 Views/           # SwiftUI views organized by feature
    │   ├── 📁 ViewModels/      # MVVM view models
    │   ├── 📁 Services/        # Business logic and external integrations
    │   ├── 📁 Utils/           # Utility functions and helpers
    │   ├── 📁 Extensions/      # Swift extensions
    │   ├── 📁 Resources/       # Fonts, colors, strings, etc.
    │   └── 📁 Assets.xcassets/ # Images, icons, colors
    │
    ├── GutCheckTests/          # Unit tests
    └── GutCheckUITests/        # UI tests
```

---

## 🏗️ Detailed Structure

### 📁 Models/
Data models and entities that represent the core business objects.

**Files to create:**
- `Meal.swift` - Meal logging data model
- `Food.swift` - Individual food item model
- `BowelMovement.swift` - Bowel tracking model
- `Symptom.swift` - Symptom tracking model
- `User.swift` - User profile model
- `NutritionInfo.swift` - Nutritional data model
- `TriggerAnalysis.swift` - AI analysis results model

### 📁 Views/
SwiftUI views organized by feature area.

#### 📁 Views/Meal/
Meal logging and food tracking views.
- `MealLogView.swift` - Main meal logging interface
- `FoodSearchView.swift` - Food search and selection
- `BarcodeScanerView.swift` - Barcode scanning interface
- `CameraFoodView.swift` - Camera-based food capture
- `ManualFoodEntryView.swift` - Manual food entry form
- `MealHistoryView.swift` - Past meals listing

#### 📁 Views/Bowel/
Bowel movement tracking views.
- `BowelLogView.swift` - Main bowel logging interface
- `BristolChartView.swift` - Bristol stool chart selector
- `SymptomEntryView.swift` - Symptom tracking form
- `BowelHistoryView.swift` - Past bowel movements

#### 📁 Views/Analytics/
Data visualization and analysis views.
- `DashboardView.swift` - Main analytics dashboard
- `TriggerAnalysisView.swift` - Food trigger insights
- `ChartsView.swift` - Data visualization charts
- `TrendsView.swift` - Long-term trend analysis
- `ReportsView.swift` - Generated reports

#### 📁 Views/Settings/
App configuration and user preferences.
- `SettingsView.swift` - Main settings screen
- `ProfileView.swift` - User profile management
- `ExportView.swift` - Data export options
- `HealthKitSettingsView.swift` - HealthKit integration
- `AboutView.swift` - App information

#### 📁 Views/Components/
Reusable UI components.
- `CustomButton.swift` - Styled app buttons
- `FoodItemCard.swift` - Food display component
- `SymptomRatingView.swift` - Symptom severity rating
- `DateTimePicker.swift` - Custom date/time picker
- `LoadingView.swift` - Loading state indicator
- `ColorTheme.swift` - App color definitions

### 📁 ViewModels/
MVVM view models for business logic.

- `MealLogViewModel.swift` - Meal logging logic
- `BowelLogViewModel.swift` - Bowel tracking logic
- `AnalyticsViewModel.swift` - Data analysis logic
- `SettingsViewModel.swift` - Settings management
- `CameraViewModel.swift` - Camera functionality
- `AuthenticationViewModel.swift` - User authentication

### 📁 Services/
External integrations and business services.

#### 📁 Services/Firebase/
Firebase integration services.
- `FirebaseManager.swift` - Main Firebase coordinator
- `AuthService.swift` - User authentication
- `FirestoreService.swift` - Database operations
- `StorageService.swift` - File storage (images)

#### 📁 Services/Camera/
Camera and image processing.
- `CameraManager.swift` - Camera capture management
- `ImageProcessor.swift` - Image processing utilities
- `BarcodeScanner.swift` - Barcode detection service

#### 📁 Services/LiDAR/
LiDAR depth sensing for portion estimation.
- `LiDARManager.swift` - LiDAR data capture
- `DepthProcessor.swift` - Depth data processing
- `PortionEstimator.swift` - Volume/portion calculations

#### 📁 Services/ML/
Machine learning and AI services.
- `FoodRecognitionService.swift` - Food identification AI
- `NutritionAPIService.swift` - Nutrition data lookup
- `TriggerAnalysisService.swift` - Pattern analysis AI

#### 📁 Services/HealthKit/
Apple HealthKit integration.
- `HealthKitManager.swift` - HealthKit data sync
- `HealthDataExporter.swift` - Export to Health app

### 📁 Utils/
Utility functions and helpers.

- `DateFormatter+Extensions.swift` - Date formatting utilities
- `NetworkMonitor.swift` - Network connectivity checking
- `CSVExporter.swift` - Data export functionality
- `Constants.swift` - App-wide constants
- `Validators.swift` - Input validation helpers

### 📁 Extensions/
Swift language extensions.

- `Color+Theme.swift` - Custom color extensions
- `View+Modifiers.swift` - Custom view modifiers
- `String+Validation.swift` - String validation helpers
- `Date+Helpers.swift` - Date manipulation helpers

### 📁 Resources/
App resources and configuration.

- `Localizable.strings` - Localization strings
- `Colors.xcassets` - Color assets
- `Fonts/` - Custom font files
- `Config.plist` - App configuration

---

## 🎯 Development Phases & File Priority

### Phase 2 (Current) - Meal Logging UI
**Priority files to create:**
1. `Models/Meal.swift`
2. `Models/Food.swift`
3. `Views/Meal/MealLogView.swift`
4. `Views/Components/CustomButton.swift`
5. `Views/Components/ColorTheme.swift`
6. `ViewModels/MealLogViewModel.swift`
7. `Services/Firebase/FirebaseManager.swift`

### Phase 3 - LiDAR Integration
1. `Services/LiDAR/LiDARManager.swift`
2. `Services/LiDAR/PortionEstimator.swift`
3. `Views/Meal/CameraFoodView.swift`

### Phase 4 - AI Recognition
1. `Services/ML/FoodRecognitionService.swift`
2. `Services/ML/NutritionAPIService.swift`

### Phase 5 - Bowel Logging
1. `Models/BowelMovement.swift`
2. `Views/Bowel/BowelLogView.swift`
3. `Views/Bowel/BristolChartView.swift`

---

## 🎨 UI Color Scheme Reference

```swift
// Primary: Plum #7D5BA6
// Accent: Mint Green #A1E3D8
// Background: Ivory #FFFDF6
// Text: Dark Plum #2D1B4E
// Secondary: Pale Orange #FFD6A5
```

---

## 📝 Notes

- Follow MVVM architecture pattern
- Use dependency injection for services
- Implement proper error handling
- Add comprehensive unit tests for ViewModels and Services
- Use SwiftUI best practices for views
- Ensure proper Firebase security rules
- Implement offline-first data strategy

---

**Last Updated:** July 11, 2025  
**Created by:** Mark Conley
