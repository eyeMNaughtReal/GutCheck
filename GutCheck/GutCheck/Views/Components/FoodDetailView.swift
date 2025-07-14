import SwiftUI

struct FoodDetailView: View {
    let foodItem: FoodItem
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(foodItem.name)
                .font(.largeTitle)
                .bold()
            Text("Quantity: \(foodItem.quantity)")
            Text("Estimated Weight: \(Int(foodItem.estimatedWeightInGrams ?? 0))g")
            Text("Calories: \(foodItem.nutrition.calories ?? 0)")
            Text("Protein: \(foodItem.nutrition.protein ?? 0)g  Carbs: \(foodItem.nutrition.carbs ?? 0)g  Fat: \(foodItem.nutrition.fat ?? 0)g")
            // Placeholder for triggers/allergens
            Text("Triggers: None detected")
                .foregroundColor(.orange)
            Text("Allergens: None detected")
                .foregroundColor(.red)
            Spacer()
        }
        .padding()
        .navigationTitle(foodItem.name)
    }
}
