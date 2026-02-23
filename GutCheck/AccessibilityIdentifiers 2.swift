//
//  AccessibilityIdentifiers.swift
//  GutCheck
//
//  Centralized accessibility identifiers for UI testing and automation
//  Created for accessibility compliance - February 23, 2026
//

import Foundation
import SwiftUI

/// Centralized accessibility identifiers for consistent UI testing
/// Use these IDs with `.accessibilityIdentifier()` modifier
enum AccessibilityIdentifiers {
    
    // MARK: - Authentication
    enum Auth {
        static let emailField = "auth.email.field"
        static let passwordField = "auth.password.field"
        static let signInButton = "auth.signIn.button"
        static let signUpButton = "auth.signUp.button"
        static let forgotPasswordButton = "auth.forgotPassword.button"
        static let socialSignInGoogle = "auth.social.google"
        static let socialSignInApple = "auth.social.apple"
    }
    
    // MARK: - Dashboard
    enum Dashboard {
        static let view = "dashboard.view"
        static let greetingHeader = "dashboard.greeting"
        static let logMealButton = "dashboard.logMeal.button"
        static let logSymptomButton = "dashboard.logSymptom.button"
        static let profileButton = "dashboard.profile.button"
        static let healthScoreCard = "dashboard.healthScore.card"
        static let todaysFocusCard = "dashboard.todaysFocus.card"
        static let avoidanceTipCard = "dashboard.avoidanceTip.card"
        static let weekSelector = "dashboard.weekSelector"
        static let activitySummary = "dashboard.activitySummary"
    }
    
    // MARK: - Meal Builder
    enum MealBuilder {
        static let view = "mealBuilder.view"
        static let mealNameField = "mealBuilder.name.field"
        static let mealTypePicker = "mealBuilder.type.picker"
        static let dateTimeButton = "mealBuilder.dateTime.button"
        static let addFoodButton = "mealBuilder.addFood.button"
        static let notesField = "mealBuilder.notes.field"
        static let saveButton = "mealBuilder.save.button"
        static let cancelButton = "mealBuilder.cancel.button"
        static let saveTemplateButton = "mealBuilder.saveTemplate.button"
        static let nutritionSummary = "mealBuilder.nutrition.summary"
        static let foodItemsList = "mealBuilder.foodItems.list"
        static let emptyState = "mealBuilder.empty.state"
        
        // Individual food items
        static func foodItem(_ index: Int) -> String {
            "mealBuilder.foodItem.\(index)"
        }
        
        static func deleteFoodItem(_ index: Int) -> String {
            "mealBuilder.foodItem.\(index).delete"
        }
    }
    
    // MARK: - Food Search
    enum FoodSearch {
        static let view = "foodSearch.view"
        static let searchField = "foodSearch.search.field"
        static let searchButton = "foodSearch.search.button"
        static let clearButton = "foodSearch.clear.button"
        static let cancelButton = "foodSearch.cancel.button"
        static let createCustomButton = "foodSearch.createCustom.button"
        static let resultsList = "foodSearch.results.list"
        static let emptyState = "foodSearch.empty.state"
        static let loadingIndicator = "foodSearch.loading"
        
        // Categories
        static let categoriesSection = "foodSearch.categories"
        static func category(_ name: String) -> String {
            "foodSearch.category.\(name.lowercased())"
        }
        
        // Recent searches
        static let recentSearchesSection = "foodSearch.recentSearches"
        static func recentSearch(_ index: Int) -> String {
            "foodSearch.recentSearch.\(index)"
        }
        
        // Search results
        static func searchResult(_ index: Int) -> String {
            "foodSearch.result.\(index)"
        }
    }
    
    // MARK: - Symptom Logging
    enum SymptomLogger {
        static let view = "symptomLogger.view"
        static let dateTimeButton = "symptomLogger.dateTime.button"
        static let notesField = "symptomLogger.notes.field"
        static let saveButton = "symptomLogger.save.button"
        static let cancelButton = "symptomLogger.cancel.button"
        
        // Bristol Scale
        static let bristolScaleSection = "symptomLogger.bristolScale.section"
        static let bristolScaleInfoButton = "symptomLogger.bristolScale.info"
        static func bristolType(_ type: Int) -> String {
            "symptomLogger.bristol.type\(type)"
        }
        
        // Pain Level
        static let painLevelSection = "symptomLogger.painLevel.section"
        static let painLevelInfoButton = "symptomLogger.painLevel.info"
        static func painLevel(_ level: Int) -> String {
            "symptomLogger.painLevel.\(level)"
        }
        
        // Urgency Level
        static let urgencyLevelSection = "symptomLogger.urgencyLevel.section"
        static func urgencyLevel(_ level: String) -> String {
            "symptomLogger.urgency.\(level.lowercased())"
        }
        
        // Tags
        static let tagsSection = "symptomLogger.tags.section"
        static func tag(_ name: String) -> String {
            "symptomLogger.tag.\(name.lowercased())"
        }
        
        // Bloating
        static let bloatingSection = "symptomLogger.bloating.section"
        static let bloatingSlider = "symptomLogger.bloating.slider"
    }
    
    // MARK: - Calendar
    enum Calendar {
        static let view = "calendar.view"
        static let weekSelector = "calendar.weekSelector"
        static let tabSegment = "calendar.tabSegment"
        static let mealsList = "calendar.meals.list"
        static let symptomsList = "calendar.symptoms.list"
        static let floatingActionButton = "calendar.fab"
        static let emptyState = "calendar.empty.state"
        
        // Week selector dates
        static func dateButton(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return "calendar.date.\(formatter.string(from: date))"
        }
        
        // List items
        static func mealItem(_ index: Int) -> String {
            "calendar.meal.\(index)"
        }
        
        static func symptomItem(_ index: Int) -> String {
            "calendar.symptom.\(index)"
        }
    }
    
    // MARK: - Settings
    enum Settings {
        static let view = "settings.view"
        static let closeButton = "settings.close.button"
        
        // Preferences
        static let languageRow = "settings.language"
        static let unitsRow = "settings.units"
        
        // Healthcare
        static let healthcareExportRow = "settings.healthcare.export"
        
        // Privacy & Security
        static let privacyPolicyRow = "settings.privacyPolicy"
        static let dataDeletionRow = "settings.dataDeletion"
        static let privacyAcceptedRow = "settings.privacyAccepted"
        
        // Data & Storage
        static let localStorageRow = "settings.localStorage"
        
        // Account
        static let deleteAccountRow = "settings.deleteAccount"
    }
    
    // MARK: - Insights
    enum Insights {
        static let view = "insights.view"
        static let chartSection = "insights.chart"
        static let timeRangeSelector = "insights.timeRange"
        static let filterButton = "insights.filter.button"
        static let insightCardsList = "insights.cards.list"
        
        static func insightCard(_ index: Int) -> String {
            "insights.card.\(index)"
        }
    }
    
    // MARK: - Tab Bar
    enum TabBar {
        static let dashboard = "tabBar.dashboard"
        static let meals = "tabBar.meals"
        static let symptoms = "tabBar.symptoms"
        static let insights = "tabBar.insights"
    }
    
    // MARK: - Profile
    enum Profile {
        static let view = "profile.view"
        static let avatarImage = "profile.avatar"
        static let nameLabel = "profile.name"
        static let emailLabel = "profile.email"
        static let editButton = "profile.edit.button"
        static let signOutButton = "profile.signOut.button"
    }
    
    // MARK: - Common Components
    enum Common {
        static let loadingIndicator = "common.loading"
        static let errorMessage = "common.error"
        static let successMessage = "common.success"
        static let confirmDialog = "common.confirm.dialog"
        static let cancelButton = "common.cancel.button"
        static let saveButton = "common.save.button"
        static let deleteButton = "common.delete.button"
        static let backButton = "common.back.button"
    }
    
    // MARK: - Alerts & Dialogs
    enum Alert {
        static let title = "alert.title"
        static let message = "alert.message"
        static let confirmButton = "alert.confirm.button"
        static let cancelButton = "alert.cancel.button"
        static let dismissButton = "alert.dismiss.button"
    }
}

// MARK: - SwiftUI Extension

extension View {
    /// Applies an accessibility identifier from the centralized system
    /// - Parameter identifier: The accessibility identifier
    /// - Returns: A view with the accessibility identifier applied
    func accessibilityId(_ identifier: String) -> some View {
        self.accessibilityIdentifier(identifier)
    }
}

// MARK: - Usage Examples

/*
 
 USAGE EXAMPLES:
 
 1. Dashboard buttons:
 ```swift
 Button("Log Meal") { ... }
     .accessibilityId(AccessibilityIdentifiers.Dashboard.logMealButton)
 ```
 
 2. Form fields:
 ```swift
 TextField("Meal Name", text: $name)
     .accessibilityId(AccessibilityIdentifiers.MealBuilder.mealNameField)
 ```
 
 3. Bristol Scale buttons:
 ```swift
 ForEach(1...7, id: \.self) { type in
     Button("Type \(type)") { ... }
         .accessibilityId(AccessibilityIdentifiers.SymptomLogger.bristolType(type))
 }
 ```
 
 4. List items with indices:
 ```swift
 ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
     MealRow(meal: meal)
         .accessibilityId(AccessibilityIdentifiers.Calendar.mealItem(index))
 }
 ```
 
 5. Tab bar items:
 ```swift
 .tabItem {
     Label("Dashboard", systemImage: "house.fill")
 }
 .accessibilityId(AccessibilityIdentifiers.TabBar.dashboard)
 ```
 
 6. UI Testing:
 ```swift
 // In UI Tests
 func testMealCreation() {
     let app = XCUIApplication()
     app.buttons[AccessibilityIdentifiers.Dashboard.logMealButton].tap()
     app.textFields[AccessibilityIdentifiers.MealBuilder.mealNameField].tap()
     // ...
 }
 ```
 
 */
