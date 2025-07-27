//
//  NutritionComponents.swift
//  GutCheck
//
//  Unified nutrition display components for consistent UI across the app
//

import SwiftUI

// MARK: - Unified Nutrition Badge

struct UnifiedNutritionBadge: View {
    let value: String
    let unit: String
    let color: Color
    let style: BadgeStyle
    
    enum BadgeStyle {
        case compact, standard, large
        
        var fontSize: Font {
            switch self {
            case .compact: return .caption2
            case .standard: return .caption
            case .large: return .footnote
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .compact: return EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
            case .standard: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .large: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            }
        }
    }
    
    init(value: String, unit: String, color: Color, style: BadgeStyle = .standard) {
        self.value = value
        self.unit = unit
        self.color = color
        self.style = style
    }
    
    // Convenience initializers
    init(calories: Int, style: BadgeStyle = .standard) {
        self.init(value: "\(calories)", unit: "kcal", color: .orange, style: style)
    }
    
    init(protein: Double, style: BadgeStyle = .standard) {
        self.init(value: String(format: "%.1f", protein), unit: "P", color: .blue, style: style)
    }
    
    init(carbs: Double, style: BadgeStyle = .standard) {
        self.init(value: String(format: "%.1f", carbs), unit: "C", color: .green, style: style)
    }
    
    init(fat: Double, style: BadgeStyle = .standard) {
        self.init(value: String(format: "%.1f", fat), unit: "F", color: .red, style: style)
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Text(value)
                .font(style.fontSize)
                .fontWeight(.medium)
            Text(unit)
                .font(style.fontSize)
                .fontWeight(.regular)
        }
        .padding(style.padding)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(style == .large ? 6 : 4)
    }
}

// MARK: - Unified Macro Row

struct UnifiedMacroRow: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    init(label: String, value: String, unit: String, color: Color) {
        self.label = label
        self.value = value
        self.unit = unit
        self.color = color
    }
    
    // Convenience initializer
    init(nutrition: NutritionInfo, type: MacroType) {
        let config = MacroType.config(for: type, nutrition: nutrition)
        self.label = config.label
        self.value = config.value
        self.unit = config.unit
        self.color = config.color
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(ColorTheme.primaryText)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
        }
    }
}

// MARK: - Unified Nutrition Summary

struct UnifiedNutritionSummary: View {
    let nutrition: NutritionInfo
    let style: SummaryStyle
    
    enum SummaryStyle {
        case compact, standard, detailed
    }
    
    init(nutrition: NutritionInfo, style: SummaryStyle = .standard) {
        self.nutrition = nutrition
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with calories
            if let calories = nutrition.calories {
                HStack {
                    Text("Nutrition Facts")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Spacer()
                    
                    Text("\(calories) kcal")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primary)
                }
            }
            
            if style != .compact {
                Divider()
                macrosSection
                
                if style == .detailed {
                    additionalNutrientsSection
                }
            } else {
                compactMacrosRow
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
    
    private var macrosSection: some View {
        HStack(spacing: 16) {
            if let protein = nutrition.protein {
                NutrientColumn(name: "Protein", value: protein, unit: "g", color: .blue)
            }
            
            if let carbs = nutrition.carbs {
                NutrientColumn(name: "Carbs", value: carbs, unit: "g", color: .green)
            }
            
            if let fat = nutrition.fat {
                NutrientColumn(name: "Fat", value: fat, unit: "g", color: .red)
            }
        }
    }
    
    private var compactMacrosRow: some View {
        HStack(spacing: 8) {
            if let calories = nutrition.calories {
                UnifiedNutritionBadge(calories: calories, style: .compact)
            }
            
            if let protein = nutrition.protein {
                UnifiedNutritionBadge(protein: protein, style: .compact)
            }
            
            if let carbs = nutrition.carbs {
                UnifiedNutritionBadge(carbs: carbs, style: .compact)
            }
            
            if let fat = nutrition.fat {
                UnifiedNutritionBadge(fat: fat, style: .compact)
            }
        }
    }
    
    private var additionalNutrientsSection: some View {
        VStack(spacing: 8) {
            if let fiber = nutrition.fiber {
                UnifiedMacroRow(label: "Fiber", value: String(format: "%.1f", fiber), unit: "g", color: .brown)
            }
            
            if let sodium = nutrition.sodium {
                UnifiedMacroRow(label: "Sodium", value: String(format: "%.0f", sodium), unit: "mg", color: .purple)
            }
            
            if let sugar = nutrition.sugar {
                UnifiedMacroRow(label: "Sugar", value: String(format: "%.1f", sugar), unit: "g", color: .pink)
            }
        }
    }
}

// MARK: - Nutrient Column

struct NutrientColumn: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
            
            Text(String(format: "%.1f", value))
                .font(.headline)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Macro Type Configuration

enum MacroType {
    case calories, protein, carbs, fat, fiber, sodium, sugar
    
    static func config(for type: MacroType, nutrition: NutritionInfo) -> (label: String, value: String, unit: String, color: Color) {
        switch type {
        case .calories:
            return ("Calories", "\(nutrition.calories ?? 0)", "kcal", .orange)
        case .protein:
            return ("Protein", String(format: "%.1f", nutrition.protein ?? 0), "g", .blue)
        case .carbs:
            return ("Carbs", String(format: "%.1f", nutrition.carbs ?? 0), "g", .green)
        case .fat:
            return ("Fat", String(format: "%.1f", nutrition.fat ?? 0), "g", .red)
        case .fiber:
            return ("Fiber", String(format: "%.1f", nutrition.fiber ?? 0), "g", .brown)
        case .sodium:
            return ("Sodium", String(format: "%.0f", nutrition.sodium ?? 0), "mg", .purple)
        case .sugar:
            return ("Sugar", String(format: "%.1f", nutrition.sugar ?? 0), "g", .pink)
        }
    }
}

// MARK: - Convenience Extensions

extension NutritionInfo {
    func compactPreview() -> some View {
        HStack(spacing: 8) {
            if let calories = calories {
                UnifiedNutritionBadge(calories: calories, style: .compact)
            }
            
            if let protein = protein {
                UnifiedNutritionBadge(protein: protein, style: .compact)
            }
            
            if let carbs = carbs {
                UnifiedNutritionBadge(carbs: carbs, style: .compact)
            }
            
            if let fat = fat {
                UnifiedNutritionBadge(fat: fat, style: .compact)
            }
        }
    }
    
    func summaryCard(style: UnifiedNutritionSummary.SummaryStyle = .standard) -> some View {
        UnifiedNutritionSummary(nutrition: self, style: style)
    }
}
