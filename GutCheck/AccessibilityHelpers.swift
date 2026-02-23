//
//  AccessibilityHelpers.swift
//  GutCheck
//
//  Reusable accessibility modifiers and helper functions
//  Created for accessibility compliance - February 23, 2026
//

import SwiftUI

// MARK: - View Extensions for Common Accessibility Patterns

extension View {
    
    // MARK: - Complete Accessibility Labels
    
    /// Adds comprehensive accessibility support to a view
    /// - Parameters:
    ///   - label: The accessibility label describing the element
    ///   - hint: Optional hint describing what happens when interacting
    ///   - value: Optional current value (for controls like sliders, pickers)
    ///   - traits: Additional accessibility traits
    /// - Returns: A view with complete accessibility support
    ///
    /// Example:
    /// ```swift
    /// Button("Save") { save() }
    ///     .accessible(
    ///         label: "Save Meal",
    ///         hint: "Saves the current meal to your history",
    ///         traits: .isButton
    ///     )
    /// ```
    func accessible(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .conditionally(hint != nil) {
                $0.accessibilityHint(hint!)
            }
            .conditionally(value != nil) {
                $0.accessibilityValue(value!)
            }
            .conditionally(traits != nil) {
                $0.accessibilityAddTraits(traits!)
            }
    }
    
    /// Marks a view as a header for better navigation
    func accessibleHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// Marks a view as a button with proper label and hint
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .conditionally(hint != nil) {
                $0.accessibilityHint(hint!)
            }
            .accessibilityAddTraits(.isButton)
    }
    
    /// Marks a view as selected/deselected with proper state announcement
    func accessibleSelectable(label: String, isSelected: Bool) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
            .conditionally(isSelected) {
                $0.accessibilityAddTraits(.isSelected)
            }
    }
    
    /// Marks an image as decorative (won't be read by VoiceOver)
    func accessibleDecorative() -> some View {
        self.accessibilityHidden(true)
    }
    
    /// Groups multiple elements into a single accessibility element
    /// Use for complex cards or controls that should be read as one unit
    func accessibleGroup(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .conditionally(hint != nil) {
                $0.accessibilityHint(hint!)
            }
    }
    
    // MARK: - Form Field Helpers
    
    /// Adds proper accessibility support to a form field
    /// - Parameters:
    ///   - label: Label describing the field
    ///   - value: Current value (if any)
    ///   - isRequired: Whether the field is required
    ///   - error: Optional error message
    func accessibleFormField(
        label: String,
        value: String? = nil,
        isRequired: Bool = false,
        error: String? = nil
    ) -> some View {
        let fullLabel = isRequired ? "\(label), required field" : label
        let fullValue = error != nil ? "Error: \(error!)" : value
        
        return self
            .accessibilityLabel(fullLabel)
            .conditionally(fullValue != nil) {
                $0.accessibilityValue(fullValue!)
            }
    }
    
    // MARK: - Custom Actions
    
    /// Adds a custom accessibility action (for swipe-to-delete, etc.)
    /// - Parameters:
    ///   - name: Name of the action
    ///   - action: Action to perform
    func accessibleAction(named name: String, _ action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: name, action)
    }
    
    /// Adds delete action that's accessible via VoiceOver
    func accessibleDeleteAction(_ action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: "Delete", action)
    }
    
    // MARK: - State Announcements
    
    /// Announces a state change to VoiceOver users
    /// - Parameter announcement: Text to announce
    ///
    /// Example:
    /// ```swift
    /// Button("Save") {
    ///     saveMeal()
    ///     announceToVoiceOver("Meal saved successfully")
    /// }
    /// ```
    func announceToVoiceOver(_ announcement: String) -> some View {
        self.onChange(of: announcement) { _, newValue in
            AccessibilityAnnouncement.announce(newValue)
        }
    }
    
    // MARK: - Conditional Modifiers
    
    /// Conditionally applies a modifier
    @ViewBuilder
    func conditionally<Content: View>(_ condition: Bool, modifier: (Self) -> Content) -> some View {
        if condition {
            modifier(self)
        } else {
            self
        }
    }
}

// MARK: - Accessibility Announcements

/// Helper class for making VoiceOver announcements
class AccessibilityAnnouncement {
    
    /// Announces a message to VoiceOver users
    /// - Parameters:
    ///   - message: The message to announce
    ///   - delay: Optional delay before announcement
    static func announce(_ message: String, after delay: TimeInterval = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    /// Announces that a screen has changed
    /// Use when navigating to a new screen or major layout change
    static func announceScreenChanged(to message: String) {
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }
    
    /// Announces that the layout has changed
    /// Use when content updates significantly but screen doesn't change
    static func announceLayoutChanged() {
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }
}

// MARK: - Common Accessibility Text Builders

struct AccessibilityText {
    
    /// Creates an accessibility label for a nutrition summary
    /// - Parameters:
    ///   - calories: Calories value
    ///   - protein: Protein in grams
    ///   - carbs: Carbohydrates in grams
    ///   - fat: Fat in grams
    /// - Returns: Formatted accessibility label
    static func nutritionSummary(calories: Int?, protein: Double?, carbs: Double?, fat: Double?) -> String {
        var parts: [String] = []
        
        if let calories = calories {
            parts.append("\(calories) calories")
        }
        if let protein = protein {
            parts.append("\(Int(protein)) grams protein")
        }
        if let carbs = carbs {
            parts.append("\(Int(carbs)) grams carbohydrates")
        }
        if let fat = fat {
            parts.append("\(Int(fat)) grams fat")
        }
        
        return parts.isEmpty ? "Nutrition information unavailable" : parts.joined(separator: ", ")
    }
    
    /// Creates an accessibility label for a meal item
    /// - Parameters:
    ///   - name: Food item name
    ///   - quantity: Quantity/serving size
    ///   - calories: Optional calories
    /// - Returns: Formatted accessibility label
    static func foodItem(name: String, quantity: String, calories: Int? = nil) -> String {
        if let calories = calories {
            return "\(name), \(quantity), \(calories) calories"
        } else {
            return "\(name), \(quantity)"
        }
    }
    
    /// Creates an accessibility label for a date/time
    /// - Parameter date: The date to format
    /// - Returns: Formatted accessibility label
    static func dateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Creates an accessibility label for a Bristol Scale type
    /// - Parameters:
    ///   - type: Bristol scale type (1-7)
    ///   - summary: Brief description
    ///   - isSelected: Whether it's currently selected
    /// - Returns: Formatted accessibility label
    static func bristolScale(type: Int, summary: String, isSelected: Bool) -> String {
        let selectedText = isSelected ? ", selected" : ""
        return "Type \(type): \(summary)\(selectedText)"
    }
    
    /// Creates an accessibility label for a pain level
    /// - Parameters:
    ///   - level: Pain level (0-4)
    ///   - description: Description of the level
    ///   - isSelected: Whether it's currently selected
    /// - Returns: Formatted accessibility label
    static func painLevel(level: Int, description: String, isSelected: Bool) -> String {
        let selectedText = isSelected ? ", selected" : ""
        return "Pain level \(level): \(description)\(selectedText)"
    }
}

// MARK: - Accessibility Environment Values

struct IsVoiceOverRunningKey: EnvironmentKey {
    static let defaultValue: Bool = UIAccessibility.isVoiceOverRunning
}

struct IsReduceMotionEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = UIAccessibility.isReduceMotionEnabled
}

struct IsBoldTextEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = UIAccessibility.isBoldTextEnabled
}

extension EnvironmentValues {
    var isVoiceOverRunning: Bool {
        get { self[IsVoiceOverRunningKey.self] }
        set { self[IsVoiceOverRunningKey.self] = newValue }
    }
    
    var isReduceMotionEnabled: Bool {
        get { self[IsReduceMotionEnabledKey.self] }
        set { self[IsReduceMotionEnabledKey.self] = newValue }
    }
    
    var isBoldTextEnabled: Bool {
        get { self[IsBoldTextEnabledKey.self] }
        set { self[IsBoldTextEnabledKey.self] = newValue }
    }
}

// MARK: - Usage Examples

/*
 
 USAGE EXAMPLES:
 
 1. Simple button with accessibility:
 ```swift
 Button("Save") { save() }
     .accessibleButton(label: "Save Meal", hint: "Saves the current meal")
 ```
 
 2. Selectable button (Bristol Scale, tags):
 ```swift
 Button(action: { toggle() }) {
     Text("Type 4")
 }
 .accessibleSelectable(label: "Bristol Type 4: Ideal", isSelected: isSelected)
 ```
 
 3. Complex card with grouped accessibility:
 ```swift
 VStack {
     Text(meal.name)
     Text(meal.time)
     nutritionSummary
 }
 .accessibleGroup(
     label: "\(meal.name), logged at \(meal.time), \(nutritionText)",
     hint: "Tap to view details"
 )
 ```
 
 4. Form field with validation:
 ```swift
 TextField("Meal Name", text: $name)
     .accessibleFormField(
         label: "Meal Name",
         value: name.isEmpty ? "Empty" : name,
         isRequired: true,
         error: nameError
     )
 ```
 
 5. Custom delete action:
 ```swift
 MealRow(meal: meal)
     .accessibleDeleteAction {
         deleteMeal(meal)
     }
 // This creates a "Delete" custom action accessible via VoiceOver
 ```
 
 6. Announce success:
 ```swift
 Button("Save") {
     saveMeal()
     AccessibilityAnnouncement.announce("Meal saved successfully")
 }
 ```
 
 7. Nutrition summary:
 ```swift
 NutritionCard(...)
     .accessible(
         label: AccessibilityText.nutritionSummary(
             calories: 450,
             protein: 25,
             carbs: 30,
             fat: 15
         )
     )
 ```
 
 8. Decorative image:
 ```swift
 Image("background")
     .accessibleDecorative()
 ```
 
 9. Section header:
 ```swift
 Text("Meals")
     .font(.headline)
     .accessibleHeader("Meals Section")
 ```
 
 10. Conditional VoiceOver layout:
 ```swift
 struct MyView: View {
     @Environment(\.isVoiceOverRunning) var isVoiceOverRunning
     
     var body: some View {
         if isVoiceOverRunning {
             // Simplified layout for VoiceOver
         } else {
             // Standard visual layout
         }
     }
 }
 ```
 
 */
