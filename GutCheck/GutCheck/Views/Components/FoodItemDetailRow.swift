import SwiftUI

struct FoodItemDetailRow: View {
    let foodItem: FoodItem
    var isEditing: Bool = false
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(foodItem.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                if isEditing {
                    if let onEdit = onEdit {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .foregroundColor(ColorTheme.primary)
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    if let onDelete = onDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundColor(ColorTheme.error)
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            
            // Quantity
            Text("\(foodItem.quantity)")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
            
            // Nutrition details
            if let calories = foodItem.nutrition.calories {
                Text("\(calories) kcal")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primaryText)
            }
            
            HStack(spacing: 12) {
                if let protein = foodItem.nutrition.protein {
                    UnifiedNutritionBadge(protein: protein)
                }
                if let carbs = foodItem.nutrition.carbs {
                    UnifiedNutritionBadge(carbs: carbs)
                }
                if let fat = foodItem.nutrition.fat {
                    UnifiedNutritionBadge(fat: fat)
                }
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
}
