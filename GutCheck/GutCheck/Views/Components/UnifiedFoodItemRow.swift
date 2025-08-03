//
//  UnifiedFoodItemRow.swift
//  GutCheck
//
//  Unified reusable food item component for consistent display across the app

import SwiftUI

/// Display styles for different contexts
enum FoodItemRowStyle {
    case search          // Search results - larger with brand info
    case recentItem      // Recent items - compact design  
    case mealBuilder     // Meal building - with edit/delete actions
    case mealDetail      // Meal details - view-only with full info
    case compact         // Minimal display for lists
}

/// Actions available for food items
struct FoodItemActions {
    let onTap: (() -> Void)?           // Tap anywhere on item (show details)
    let onAdd: (() -> Void)?           // Tap + button (add to meal)
    let onEdit: (() -> Void)?          // Tap pencil (edit item)
    let onDelete: (() -> Void)?        // Tap trash (delete item)
    
    init(
        onTap: (() -> Void)? = nil,
        onAdd: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.onTap = onTap
        self.onAdd = onAdd
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
}

/// Unified food item row component - use this everywhere in the app
struct UnifiedFoodItemRow: View {
    let item: FoodItem
    let style: FoodItemRowStyle
    let actions: FoodItemActions
    
    init(
        item: FoodItem,
        style: FoodItemRowStyle,
        actions: FoodItemActions = FoodItemActions()
    ) {
        self.item = item
        self.style = style
        self.actions = actions
    }
    
    var body: some View {
        HStack(spacing: config.iconSpacing) {
            // Food icon
            foodIcon
            
            // Main content area - tappable for details
            if let onTap = actions.onTap {
                Button(action: onTap) {
                    mainContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                mainContent
            }
            
            // Action buttons
            actionButtons
        }
        .padding(config.padding)
        .background(ColorTheme.cardBackground)
        .cornerRadius(config.cornerRadius)
        .shadow(color: ColorTheme.shadowColor, radius: config.shadowRadius, x: 0, y: 1)
    }
    
    // MARK: - Computed Properties
    
    private var config: StyleConfig {
        StyleConfig.for(style)
    }
    
    private var foodIcon: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(ColorTheme.accent.opacity(0.2))
            .frame(width: config.iconSize, height: config.iconSize)
            .overlay(
                Image(systemName: "fork.knife")
                    .foregroundColor(ColorTheme.accent)
                    .font(.system(size: config.iconSize * 0.4))
            )
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: config.contentSpacing) {
            // Food name
            Text(item.name)
                .font(config.nameFont)
                .foregroundColor(ColorTheme.primaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(config.nameLineLimit)
            
            // Brand (if available and style supports it)
            if config.showBrand, let brand = item.nutritionDetails["brand"] {
                Text(brand)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.accent)
                    .lineLimit(1)
            }
            
            // Quantity
            Text(item.quantity)
                .font(config.quantityFont)
                .foregroundColor(ColorTheme.secondaryText)
                .lineLimit(1)
            
            // Nutrition preview
            nutritionPreview
            
            // Allergens (if any and style supports it)
            if config.showAllergens && !item.allergens.isEmpty {
                allergenTags
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var nutritionPreview: some View {
        HStack(spacing: config.nutritionSpacing) {
            if let calories = item.nutrition.calories {
                NutritionBadge(
                    text: "\(Int(calories)) kcal",
                    color: ColorTheme.accent,
                    size: config.badgeSize
                )
            }
            
            if config.showMacros {
                if let protein = item.nutrition.protein {
                    NutritionBadge(
                        text: config.compactMacros ? "\(String(format: "%.1f", protein)) P" : "P: \(String(format: "%.1f", protein))g",
                        color: .blue,
                        size: config.badgeSize
                    )
                }
                
                if let carbs = item.nutrition.carbs {
                    NutritionBadge(
                        text: config.compactMacros ? "\(String(format: "%.1f", carbs)) C" : "C: \(String(format: "%.1f", carbs))g",
                        color: .green,
                        size: config.badgeSize
                    )
                }
                
                if let fat = item.nutrition.fat {
                    NutritionBadge(
                        text: config.compactMacros ? "\(String(format: "%.1f", fat)) F" : "F: \(String(format: "%.1f", fat))g",
                        color: .red,
                        size: config.badgeSize
                    )
                }
            }
        }
    }
    
    private var allergenTags: some View {
        HStack {
            ForEach(item.allergens.prefix(config.maxAllergens), id: \.self) { allergen in
                Text(allergen)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(ColorTheme.error.opacity(0.2))
                    .foregroundColor(ColorTheme.error)
                    .cornerRadius(4)
            }
            if item.allergens.count > config.maxAllergens {
                Text("+\(item.allergens.count - config.maxAllergens)")
                    .font(.caption2)
                    .foregroundColor(ColorTheme.secondaryText)
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            // Add button
            if let onAdd = actions.onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(config.actionButtonFont)
                        .foregroundColor(ColorTheme.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Edit button
            if let onEdit = actions.onEdit {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(config.actionButtonFont)
                        .foregroundColor(ColorTheme.primary)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 4)
            }
            
            // Delete button
            if let onDelete = actions.onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(config.actionButtonFont)
                        .foregroundColor(ColorTheme.error)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Supporting Components

struct NutritionBadge: View {
    let text: String
    let color: Color
    let size: BadgeSize
    
    var body: some View {
        Text(text)
            .font(size.font)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(size.cornerRadius)
    }
}

// MARK: - Configuration

enum BadgeSize {
    case small, medium, large
    
    var font: Font {
        switch self {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .subheadline
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 2
        case .large: return 4
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
}

struct StyleConfig {
    let iconSize: CGFloat
    let iconSpacing: CGFloat
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let contentSpacing: CGFloat
    let nutritionSpacing: CGFloat
    let nameFont: Font
    let quantityFont: Font
    let actionButtonFont: Font
    let badgeSize: BadgeSize
    let nameLineLimit: Int
    let showBrand: Bool
    let showMacros: Bool
    let compactMacros: Bool
    let showAllergens: Bool
    let maxAllergens: Int
    
    static func `for`(_ style: FoodItemRowStyle) -> StyleConfig {
        switch style {
        case .search:
            return StyleConfig(
                iconSize: 60,
                iconSpacing: 16,
                padding: 16,
                cornerRadius: 12,
                shadowRadius: 2,
                contentSpacing: 4,
                nutritionSpacing: 8,
                nameFont: .headline,
                quantityFont: .subheadline,
                actionButtonFont: .title2,
                badgeSize: .medium,
                nameLineLimit: 2,
                showBrand: true,
                showMacros: true,
                compactMacros: false,
                showAllergens: true,
                maxAllergens: 3
            )
            
        case .recentItem:
            return StyleConfig(
                iconSize: 50,
                iconSpacing: 16,
                padding: 12,
                cornerRadius: 12,
                shadowRadius: 2,
                contentSpacing: 4,
                nutritionSpacing: 8,
                nameFont: .headline,
                quantityFont: .subheadline,
                actionButtonFont: .title3,
                badgeSize: .small,
                nameLineLimit: 1,
                showBrand: false,
                showMacros: true,
                compactMacros: true,
                showAllergens: true,
                maxAllergens: 2
            )
            
        case .mealBuilder:
            return StyleConfig(
                iconSize: 50,
                iconSpacing: 12,
                padding: 16,
                cornerRadius: 12,
                shadowRadius: 4,
                contentSpacing: 8,
                nutritionSpacing: 12,
                nameFont: .headline,
                quantityFont: .subheadline,
                actionButtonFont: .system(size: 16),
                badgeSize: .small,
                nameLineLimit: 2,
                showBrand: false,
                showMacros: true,
                compactMacros: false,
                showAllergens: false,
                maxAllergens: 0
            )
            
        case .mealDetail:
            return StyleConfig(
                iconSize: 50,
                iconSpacing: 12,
                padding: 16,
                cornerRadius: 12,
                shadowRadius: 4,
                contentSpacing: 8,
                nutritionSpacing: 12,
                nameFont: .headline,
                quantityFont: .subheadline,
                actionButtonFont: .system(size: 16),
                badgeSize: .medium,
                nameLineLimit: 2,
                showBrand: true,
                showMacros: true,
                compactMacros: false,
                showAllergens: true,
                maxAllergens: 3
            )
            
        case .compact:
            return StyleConfig(
                iconSize: 40,
                iconSpacing: 12,     
                padding: 12,
                cornerRadius: 8,
                shadowRadius: 1,
                contentSpacing: 2,
                nutritionSpacing: 6,
                nameFont: .subheadline,
                quantityFont: .caption,
                actionButtonFont: .caption,
                badgeSize: .small,
                nameLineLimit: 1,
                showBrand: false,
                showMacros: false,
                compactMacros: true,
                showAllergens: false,
                maxAllergens: 0
            )
        }
    }
}

// MARK: - Preview

#Preview("Search Style") {
    VStack(spacing: 16) {
        UnifiedFoodItemRow(
            item: FoodItem(
                name: "Grilled Chicken Breast",
                quantity: "1 breast (6 oz)",
                nutrition: NutritionInfo(calories: 231, protein: 43.5, carbs: 0, fat: 5)
            ),
            style: .search,
            actions: FoodItemActions(
                onTap: { print("Tapped for details") },
                onAdd: { print("Added to meal") }
            )
        )
        
        UnifiedFoodItemRow(
            item: FoodItem(
                name: "Greek Yogurt",
                quantity: "1 cup",
                allergens: ["Dairy"],
                nutrition: NutritionInfo(calories: 130, protein: 23, carbs: 9, fat: 0)
            ),
            style: .recentItem,
            actions: FoodItemActions(
                onTap: { print("Tapped for details") },
                onAdd: { print("Added to meal") }
            )
        )
        
        UnifiedFoodItemRow(
            item: FoodItem(
                name: "Brown Rice",
                quantity: "1 cup cooked",
                nutrition: NutritionInfo(calories: 216, protein: 5, carbs: 45, fat: 1.8)
            ),
            style: .mealBuilder,
            actions: FoodItemActions(
                onEdit: { print("Edit item") },
                onDelete: { print("Delete item") }
            )
        )
    }
    .padding()
}
