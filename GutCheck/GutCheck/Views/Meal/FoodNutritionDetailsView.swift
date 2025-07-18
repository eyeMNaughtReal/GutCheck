import SwiftUI

struct FoodNutritionDetailsView: View {
    let foodItem: FoodItem
    let nutritionFieldLabels: [String: String] = [
        "calories": "Calories",
        "total_fat": "Total Fat (g)",
        "saturated_fat": "Saturated Fat (g)",
        "trans_fatty_acid": "Trans Fat (g)",
        "cholesterol": "Cholesterol (mg)",
        "sodium": "Sodium (mg)",
        "total_carbohydrate": "Carbohydrates (g)",
        "dietary_fiber": "Fiber (g)",
        "sugars": "Sugars (g)",
        "protein": "Protein (g)",
        "potassium": "Potassium (mg)",
        "phosphorus": "Phosphorus (mg)",
        "vitamin_a_dv": "Vitamin A (%DV)",
        "vitamin_c_dv": "Vitamin C (%DV)",
        "calcium_dv": "Calcium (%DV)",
        "iron_dv": "Iron (%DV)",
        "monounsaturated_fat": "Monounsaturated Fat (g)",
        "polyunsaturated_fat": "Polyunsaturated Fat (g)",
        "vitamin_d_mcg": "Vitamin D (mcg)",
        "thiamin_mg": "Thiamin (mg)",
        "riboflavin_mg": "Riboflavin (mg)",
        "niacin_mg": "Niacin (mg)",
        "vitamin_b6_mg": "Vitamin B6 (mg)",
        "folate_mcg": "Folate (mcg)",
        "vitamin_b12_mcg": "Vitamin B12 (mcg)",
        "biotin_mcg": "Biotin (mcg)",
        "pantothenic_acid_mg": "Pantothenic Acid (mg)",
        "phosphorus_mg": "Phosphorus (mg)",
        "iodine_mcg": "Iodine (mcg)",
        "magnesium_mg": "Magnesium (mg)",
        "zinc_mg": "Zinc (mg)",
        "selenium_mcg": "Selenium (mcg)",
        "copper_mg": "Copper (mg)",
        "manganese_mg": "Manganese (mg)",
        "chromium_mcg": "Chromium (mcg)",
        "molybdenum_mcg": "Molybdenum (mcg)",
        "chloride_mg": "Chloride (mg)",
        "vitamin_e_mg": "Vitamin E (mg)",
        "vitamin_k_mcg": "Vitamin K (mcg)"
    ]
    var body: some View {
        List {
            ForEach(foodItem.nutritionDetails.sorted(by: { $0.key < $1.key }), id: \.0) { pair in
                let key = pair.key
                let value = pair.value
                if value != "N/A" && value != "0" && value != "0.0" {
                    HStack {
                        Text(nutritionFieldLabels[key] ?? key.replacingOccurrences(of: "_", with: " ").capitalized)
                            .fontWeight(.medium)
                        Spacer()
                        Text(value)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(foodItem.name)
    }
}

// Preview
struct FoodNutritionDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let sample = FoodItem(
            name: "Big Mac",
            quantity: "1 burger",
            nutrition: NutritionInfo(calories: 563, protein: 25, carbs: 44, fat: 33),
            nutritionDetails: [
                "calories": "563",
                "protein": "25",
                "total_fat": "33",
                "total_carbohydrate": "44",
                "sodium": "1010",
                "cholesterol": "80",
                "vitamin_a_dv": "10"
            ]
        )
        NavigationStack {
            FoodNutritionDetailsView(foodItem: sample)
        }
    }
}
