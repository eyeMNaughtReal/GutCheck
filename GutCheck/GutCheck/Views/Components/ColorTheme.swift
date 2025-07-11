//
//  ColorTheme.swift
//  GutCheck
//
//  Created by Mark Conley on 7/11/25.
//

import SwiftUI

struct ColorTheme {
    // Primary colors from README
    static let primary = Color(hex: "7D5BA6")        // Plum
    static let accent = Color(hex: "A1E3D8")         // Mint Green
    static let mint = Color(hex: "A1E3D8")           // Mint Green (alias for accent)
    static let background = Color(hex: "FFFDF6")     // Ivory
    static let text = Color(hex: "2D1B4E")           // Dark Plum
    static let secondary = Color(hex: "FFD6A5")      // Pale Orange
    
    // Additional UI colors
    static let success = Color.green
    static let error = Color.red
    static let warning = Color.orange
    static let disabled = Color.gray.opacity(0.6)
    
    // Background variations
    static let cardBackground = Color.white
    static let surface = Color.white.opacity(0.95)
    static let shadowColor = Color.black.opacity(0.1)
    
    // Border and outline colors
    static let border = Color.gray.opacity(0.3)
    static let activeBorder = primary
    
    // Text variations
    static let primaryText = text
    static let secondaryText = Color.gray
    static let lightText = Color.white
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
