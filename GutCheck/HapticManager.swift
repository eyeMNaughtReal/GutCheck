//
//  HapticManager.swift
//  GutCheck
//
//  Centralized haptic feedback system that respects user accessibility settings
//  Created for accessibility compliance - February 23, 2026
//

import UIKit
import SwiftUI

/// Manages haptic feedback throughout the app with accessibility support
/// Automatically respects user's Reduce Motion setting
class HapticManager {
    
    /// Shared singleton instance
    static let shared = HapticManager()
    
    /// Whether haptics are currently enabled (respects Reduce Motion)
    private var isHapticsEnabled: Bool {
        !UIAccessibility.isReduceMotionEnabled
    }
    
    private init() {
        // Private initializer for singleton
    }
    
    // MARK: - Impact Feedback
    
    /// Light impact - Use for: Toggle switches, selections in lists
    func light() {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Medium impact - Use for: Button presses, adding items
    func medium() {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Heavy impact - Use for: Significant actions, important alerts
    func heavy() {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Soft impact (iOS 13+) - Use for: Gentle interactions
    @available(iOS 13.0, *)
    func soft() {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Rigid impact (iOS 13+) - Use for: Precise selections
    @available(iOS 13.0, *)
    func rigid() {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback - Use for: Picker changes, Bristol Scale selection, slider adjustments
    func selection() {
        guard isHapticsEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Notification Feedback
    
    /// Success notification - Use for: Meal saved, symptom logged successfully
    func success() {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Warning notification - Use for: Deletions, clearing data, potentially destructive actions
    func warning() {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Error notification - Use for: Failed operations, validation errors
    func error() {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Convenience Methods
    
    /// Tab bar selection haptic
    func tabChanged() {
        selection()
    }
    
    /// Button tap haptic
    func buttonTapped() {
        light()
    }
    
    /// Item added to list haptic
    func itemAdded() {
        medium()
    }
    
    /// Item removed from list haptic
    func itemRemoved() {
        warning()
    }
    
    /// Meal/symptom saved successfully haptic
    func dataSaved() {
        success()
    }
    
    /// Form validation error haptic
    func validationError() {
        error()
    }
    
    /// Bristol Scale type selected haptic
    func bristolScaleSelected() {
        selection()
    }
    
    /// Pain level adjusted haptic
    func painLevelChanged() {
        selection()
    }
    
    /// Date picker changed haptic
    func dateChanged() {
        selection()
    }
}

// MARK: - SwiftUI Integration

/// View modifier to add haptic feedback to any view
struct HapticFeedbackModifier: ViewModifier {
    let hapticType: HapticType
    
    enum HapticType {
        case light, medium, heavy, soft, rigid
        case selection
        case success, warning, error
        
        func trigger() {
            switch self {
            case .light: HapticManager.shared.light()
            case .medium: HapticManager.shared.medium()
            case .heavy: HapticManager.shared.heavy()
            case .soft: HapticManager.shared.soft()
            case .rigid: HapticManager.shared.rigid()
            case .selection: HapticManager.shared.selection()
            case .success: HapticManager.shared.success()
            case .warning: HapticManager.shared.warning()
            case .error: HapticManager.shared.error()
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        hapticType.trigger()
                    }
            )
    }
}

extension View {
    /// Adds haptic feedback when the view is tapped
    /// - Parameter type: The type of haptic feedback to provide
    /// - Returns: A view that triggers haptic feedback on tap
    ///
    /// Example usage:
    /// ```swift
    /// Button("Save") { save() }
    ///     .hapticFeedback(.medium)
    /// ```
    func hapticFeedback(_ type: HapticFeedbackModifier.HapticType) -> some View {
        modifier(HapticFeedbackModifier(hapticType: type))
    }
    
    /// Adds haptic feedback when a value changes
    /// - Parameters:
    ///   - value: The value to observe
    ///   - type: The type of haptic feedback
    /// - Returns: A view that triggers haptic feedback on value change
    ///
    /// Example usage:
    /// ```swift
    /// Picker("Pain Level", selection: $painLevel) { ... }
    ///     .hapticOnChange(of: painLevel, type: .selection)
    /// ```
    func hapticOnChange<V: Equatable>(of value: V, type: HapticFeedbackModifier.HapticType) -> some View {
        onChange(of: value) { _, _ in
            type.trigger()
        }
    }
}

// MARK: - Usage Examples

/*
 
 USAGE EXAMPLES:
 
 1. Simple button press:
 ```swift
 Button("Log Meal") {
     HapticManager.shared.buttonTapped()
     logMeal()
 }
 ```
 
 2. With SwiftUI modifier:
 ```swift
 Button("Log Meal") {
     logMeal()
 }
 .hapticFeedback(.medium)
 ```
 
 3. Bristol Scale selection:
 ```swift
 Button(action: {
     selectedStoolType = type
     HapticManager.shared.bristolScaleSelected()
 }) {
     BristolScaleButton(type: type)
 }
 ```
 
 4. Save with success feedback:
 ```swift
 Button("Save Meal") {
     Task {
         do {
             try await saveMeal()
             HapticManager.shared.dataSaved()
         } catch {
             HapticManager.shared.validationError()
         }
     }
 }
 ```
 
 5. Tab bar selection:
 ```swift
 func handleTabSelection(_ tab: Tab) {
     HapticManager.shared.tabChanged()
     selectedTab = tab
 }
 ```
 
 6. Slider/Picker changes:
 ```swift
 Picker("Pain Level", selection: $painLevel) {
     // options
 }
 .hapticOnChange(of: painLevel, type: .selection)
 ```
 
 7. Delete action:
 ```swift
 Button("Delete") {
     HapticManager.shared.itemRemoved()
     deleteItem()
 }
 ```
 
 RECOMMENDED HAPTIC MAPPING:
 
 - Tab switches → .selection()
 - Bristol Scale selection → .selection()
 - Pain/Urgency level changes → .selection()
 - Toggle switches → .light()
 - Regular buttons → .light() or .medium()
 - Add food item → .medium()
 - Save meal/symptom → .success()
 - Delete actions → .warning()
 - Validation errors → .error()
 - Network errors → .error()
 
 */
