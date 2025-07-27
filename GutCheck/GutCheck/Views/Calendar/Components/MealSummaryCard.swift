import SwiftUI

struct MealSummaryCard: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(meal.type.rawValue)
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(meal.foodItems) { food in
                Text(food.name)
                    .foregroundColor(.secondary)
            }
            
            Text(meal.date.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    MealSummaryCard(meal: Meal(
        id: "1",
        name: "Breakfast",
        date: Date(),
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
