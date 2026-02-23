//
//  ColorTheme.swift
//  GutCheck
//
//  Created by Mark Conley on 7/11/25.
//

import SwiftUI

struct ColorTheme {
    // MARK: - Adaptive Primary Colors
    // These colors automatically adjust for light/dark mode
    
    /// Primary brand color - Calming teal that works in both modes
    /// Light: Rich teal for trust and health
    /// Dark: Softer teal for reduced eye strain
    static let primary = Color("PrimaryColor", bundle: nil)
    
    /// Accent color - Complementary color for highlights and CTAs
    /// Light: Warm coral for energy and action
    /// Dark: Softer coral for contrast
    static let accent = Color("AccentColor", bundle: nil)
    
    /// Secondary accent - Supporting color for variety
    /// Light: Soft purple for wellness
    /// Dark: Muted purple
    static let secondary = Color("SecondaryColor", bundle: nil)
    
    // MARK: - Background Colors (Adaptive)
    
    /// Main background - Adapts to system appearance
    static let background = Color("BackgroundColor", bundle: nil)
    
    /// Card background - Elevated surfaces
    static let cardBackground = Color("CardBackground", bundle: nil)
    
    /// Surface color - For subtle elevation differences
    static let surface = Color("SurfaceColor", bundle: nil)
    
    // MARK: - Text Colors (Adaptive)
    
    /// Primary text - High contrast, readable in both modes
    static let primaryText = Color("PrimaryText", bundle: nil)
    
    /// Secondary text - Slightly muted for hierarchy
    static let secondaryText = Color("SecondaryText", bundle: nil)
    
    /// Tertiary text - Even more muted for supporting info
    static let tertiaryText = Color("TertiaryText", bundle: nil)
    
    /// Light text - For use on dark backgrounds
    static let lightText = Color.white
    
    // MARK: - Semantic Colors
    // Health-specific meanings with accessibility in mind
    
    /// Success color - Positive health indicators (good scores, achievements)
    /// Uses green but carefully chosen shades for color-blind accessibility
    static let success = Color("SuccessColor", bundle: nil)
    
    /// Warning color - Caution indicators (moderate symptoms, attention needed)
    /// Amber/orange that works in both modes
    static let warning = Color("WarningColor", bundle: nil)
    
    /// Error/Alert color - Critical health concerns, errors
    /// Red that maintains readability and isn't too alarming
    static let error = Color("ErrorColor", bundle: nil)
    
    /// Info color - Informational messages, tips
    static let info = Color("InfoColor", bundle: nil)
    
    // MARK: - Interactive Elements
    
    /// Border color for inputs and dividers
    static let border = Color("BorderColor", bundle: nil)
    
    /// Active/focused border
    static let activeBorder = primary
    
    /// Disabled state
    static let disabled = Color("DisabledColor", bundle: nil)
    
    /// Shadow color
    static let shadowColor = Color.black.opacity(0.1)
    
    // MARK: - Feature-Specific Colors
    
    /// Meal logging indicator
    static let mealLogging = primary
    
    /// Bowel tracking indicator  
    static let bowelTracking = secondary
    
    /// Symptom tracking indicator
    static let symptomTracking = Color("SymptomColor", bundle: nil)
    
    // MARK: - Button Colors (using semantic colors)
    
    static let buttonPrimary = primary
    static let buttonSecondary = secondary
    
    // MARK: - Input Colors
    
    static let inputBackground = Color("InputBackground", bundle: nil)
    
    // MARK: - Legacy Support (for backward compatibility)
    
    static let mint = accent  // Alias
    static let text = primaryText  // Alias
}

// Extension to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
