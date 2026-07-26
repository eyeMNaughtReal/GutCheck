import SwiftUI

struct MealSummaryCard: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(meal.type.rawValue)
                .font(.headline)
                .foregroundStyle(.primary)
            
            ForEach(meal.foodItems) { food in
                Text(food.name)
                    .foregroundStyle(.secondary)
            }
            
            Text(meal.date.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
    }
}

#Preview {
    MealSummaryCard(meal: Meal(
        id: "1",
        name: "Breakfast",
        date: Date.now,
        type: .breakfast,
        source: .manual,
        foodItems: [
            FoodItem(
                id: "1", 
                name: "Toast",
                quantity: "1 slice",
                estimatedWeightInGrams: nil,
                ingredients: [],
                allergens: [],
                nutrition: NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0),
                source: .manual,
                barcodeValue: nil,
                isUserEdited: false,
                nutritionDetails: [:]
            )
        ],
        notes: nil,
        tags: [],
        createdBy: "user123"
    ))
}
