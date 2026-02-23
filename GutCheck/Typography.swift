//
//  Typography.swift
//  GutCheck
//
//  Dynamic Type support system for accessibility
//  Created for accessibility compliance - February 23, 2026
//

import SwiftUI

/// Typography system with Dynamic Type support
/// All text in the app should use these styles to support accessibility
struct Typography {
    
    // MARK: - Text Styles with Dynamic Type
    
    /// Large title - Use for main screen titles
    static let largeTitle = DynamicFont(textStyle: .largeTitle, defaultSize: 34, weight: .bold)
    
    /// Title - Use for section titles
    static let title = DynamicFont(textStyle: .title, defaultSize: 28, weight: .bold)
    
    /// Title 2 - Use for subsection titles
    static let title2 = DynamicFont(textStyle: .title2, defaultSize: 22, weight: .bold)
    
    /// Title 3 - Use for card titles
    static let title3 = DynamicFont(textStyle: .title3, defaultSize: 20, weight: .semibold)
    
    /// Headline - Use for prominent text
    static let headline = DynamicFont(textStyle: .headline, defaultSize: 17, weight: .semibold)
    
    /// Body - Use for standard body text
    static let body = DynamicFont(textStyle: .body, defaultSize: 17, weight: .regular)
    
    /// Callout - Use for emphasized body text
    static let callout = DynamicFont(textStyle: .callout, defaultSize: 16, weight: .regular)
    
    /// Subheadline - Use for secondary text
    static let subheadline = DynamicFont(textStyle: .subheadline, defaultSize: 15, weight: .regular)
    
    /// Footnote - Use for supplementary information
    static let footnote = DynamicFont(textStyle: .footnote, defaultSize: 13, weight: .regular)
    
    /// Caption - Use for image captions, labels
    static let caption = DynamicFont(textStyle: .caption, defaultSize: 12, weight: .regular)
    
    /// Caption 2 - Use for smallest text
    static let caption2 = DynamicFont(textStyle: .caption2, defaultSize: 11, weight: .regular)
    
    // MARK: - Custom Styles for GutCheck
    
    /// Nutrition value - Large numbers in nutrition cards
    static let nutritionValue = DynamicFont(textStyle: .title, defaultSize: 28, weight: .bold)
    
    /// Nutrition label - Small labels in nutrition cards
    static let nutritionLabel = DynamicFont(textStyle: .caption2, defaultSize: 11, weight: .medium)
    
    /// Bristol Scale number - Large type numbers in Bristol Scale
    static let bristolNumber = DynamicFont(textStyle: .title, defaultSize: 28, weight: .bold)
    
    /// Pain level number - Numbers in pain level selector
    static let painLevelNumber = DynamicFont(textStyle: .title2, defaultSize: 22, weight: .semibold)
    
    /// Button text - Standard button text
    static let button = DynamicFont(textStyle: .body, defaultSize: 17, weight: .semibold)
    
    /// Small button text - Secondary button text
    static let smallButton = DynamicFont(textStyle: .callout, defaultSize: 16, weight: .medium)
}

// MARK: - Dynamic Font Structure

/// A font that scales with Dynamic Type
struct DynamicFont {
    let textStyle: Font.TextStyle
    let defaultSize: CGFloat
    let weight: Font.Weight
    
    /// Returns a SwiftUI Font that scales with Dynamic Type
    var font: Font {
        .system(textStyle, design: .default)
            .weight(weight)
    }
    
    /// Returns a UIFont for use in UIKit contexts
    var uiFont: UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle.uiTextStyle)
        return UIFont.systemFont(ofSize: descriptor.pointSize, weight: weight.uiFontWeight)
    }
}

// MARK: - View Extension for Easy Usage

extension View {
    /// Applies a typography style with Dynamic Type support
    /// - Parameter style: The typography style to apply
    /// - Returns: A view with the typography applied
    ///
    /// Example:
    /// ```swift
    /// Text("Hello World")
    ///     .typography(.headline)
    /// ```
    func typography(_ style: DynamicFont) -> some View {
        self.font(style.font)
    }
}

// MARK: - Text Style Extensions

extension Font.TextStyle {
    /// Converts SwiftUI TextStyle to UIKit UIFont.TextStyle
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .body: return .body
        case .callout: return .callout
        case .subheadline: return .subheadline
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}

extension Font.Weight {
    /// Converts SwiftUI Font.Weight to UIKit UIFont.Weight
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}

// MARK: - Dynamic Type Size Limits

extension View {
    /// Limits the maximum Dynamic Type size for layouts that break at very large sizes
    /// Use sparingly - prefer flexible layouts that work at all sizes
    /// - Parameters:
    ///   - min: Minimum dynamic type size
    ///   - max: Maximum dynamic type size
    /// - Returns: A view with limited dynamic type scaling
    ///
    /// Example:
    /// ```swift
    /// ComplexLayoutView()
    ///     .dynamicTypeLimit(min: .large, max: .xxxLarge)
    /// ```
    func dynamicTypeLimit(min: DynamicTypeSize = .xSmall, max: DynamicTypeSize = .accessibility5) -> some View {
        self.dynamicTypeSize(min...max)
    }
}

// MARK: - Scaled Metrics

/// A property wrapper for values that scale with Dynamic Type
/// Use for spacing, sizes, and other values that should scale
///
/// Example:
/// ```swift
/// struct MyView: View {
///     @ScaledMetric var iconSize: CGFloat = 24
///
///     var body: some View {
///         Image(systemName: "heart")
///             .font(.system(size: iconSize))
///     }
/// }
/// ```

// MARK: - Typography Previews

#if DEBUG
struct TypographyPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Large Title")
                        .typography(Typography.largeTitle)
                    
                    Text("Title")
                        .typography(Typography.title)
                    
                    Text("Title 2")
                        .typography(Typography.title2)
                    
                    Text("Title 3")
                        .typography(Typography.title3)
                    
                    Text("Headline Text")
                        .typography(Typography.headline)
                    
                    Text("Body Text - This is the standard body text that most content will use.")
                        .typography(Typography.body)
                    
                    Text("Callout Text")
                        .typography(Typography.callout)
                    
                    Text("Subheadline Text")
                        .typography(Typography.subheadline)
                }
                
                Group {
                    Text("Footnote Text")
                        .typography(Typography.footnote)
                    
                    Text("Caption Text")
                        .typography(Typography.caption)
                    
                    Text("Caption 2 Text")
                        .typography(Typography.caption2)
                }
                
                Divider()
                
                Group {
                    Text("Custom Styles")
                        .typography(Typography.headline)
                        .padding(.top)
                    
                    HStack {
                        VStack {
                            Text("450")
                                .typography(Typography.nutritionValue)
                            Text("CALORIES")
                                .typography(Typography.nutritionLabel)
                        }
                        
                        VStack {
                            Text("7")
                                .typography(Typography.bristolNumber)
                            Text("Bristol Type")
                                .typography(Typography.caption)
                        }
                        
                        VStack {
                            Text("3")
                                .typography(Typography.painLevelNumber)
                            Text("Pain Level")
                                .typography(Typography.caption)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Typography System")
    }
}

#Preview {
    NavigationStack {
        TypographyPreview()
    }
}
#endif

// MARK: - Migration Guide

/*
 
 MIGRATION GUIDE: Replacing Fixed Fonts with Typography
 
 OLD (Fixed fonts):
 ```swift
 Text("Hello")
     .font(.title)
 
 Text("World")
     .font(.system(size: 17))
 
 Text("Detail")
     .font(.caption)
     .fontWeight(.semibold)
 ```
 
 NEW (Dynamic Typography):
 ```swift
 Text("Hello")
     .typography(Typography.title)
 
 Text("World")
     .typography(Typography.body)
 
 Text("Detail")
     .typography(Typography.caption)
     // Weight is already in the style
 ```
 
 COMMON REPLACEMENTS:
 
 .font(.largeTitle) → .typography(Typography.largeTitle)
 .font(.title) → .typography(Typography.title)
 .font(.title2) → .typography(Typography.title2)
 .font(.title3) → .typography(Typography.title3)
 .font(.headline) → .typography(Typography.headline)
 .font(.body) → .typography(Typography.body)
 .font(.callout) → .typography(Typography.callout)
 .font(.subheadline) → .typography(Typography.subheadline)
 .font(.footnote) → .typography(Typography.footnote)
 .font(.caption) → .typography(Typography.caption)
 .font(.caption2) → .typography(Typography.caption2)
 
 CUSTOM SIZES:
 .font(.system(size: 28, weight: .bold)) → .typography(Typography.nutritionValue)
 .font(.system(size: 17, weight: .semibold)) → .typography(Typography.button)
 
 FOR ICONS THAT SHOULD SCALE:
 ```swift
 @ScaledMetric var iconSize: CGFloat = 24
 
 Image(systemName: "heart")
     .font(.system(size: iconSize))
 ```
 
 TESTING DYNAMIC TYPE:
 
 1. In Simulator: Settings → Accessibility → Display & Text Size → Larger Text
 2. Or use environment override in preview:
 ```swift
 #Preview {
     MyView()
         .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
 }
 ```
 
 PRIORITY ORDER FOR MIGRATION:
 
 1. Dashboard view
 2. Meal Builder
 3. Symptom Logger
 4. Food Search
 5. Calendar
 6. Settings
 7. Other views
 
 */
