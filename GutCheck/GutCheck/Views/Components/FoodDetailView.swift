import SwiftUI

private struct NutritionValue: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(ColorTheme.primaryText)
            Text(label)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FoodHeaderView: View {
    let foodItem: FoodItem
    
    var body: some View {
        VStack(spacing: 16) {
            Text(foodItem.name)
                .font(.title.bold())
                .foregroundColor(ColorTheme.primaryText)
                .multilineTextAlignment(.center)
            
            Text(foodItem.quantity)
                .font(.title2)
                .foregroundColor(ColorTheme.secondaryText)
            
            if let weight = foodItem.estimatedWeightInGrams {
                Text("Estimated Weight: \(Int(weight))g")
                    .font(.headline)
                    .foregroundColor(ColorTheme.secondaryText)
            }
        }
        .padding(.horizontal)
    }
}

private struct NutritionCardView: View {
    let nutrition: NutritionInfo
    
    private func formatCalories(_ value: Int?) -> String {
        if let value = value {
            return "\(value)"
        }
        return "N/A"
    }
    
    private func formatNutrient(_ value: Double?) -> String {
        if let value = value {
            return String(format: "%.1f", value)
        }
        return "N/A"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Nutrition Information")
                .font(.title3.bold())
                .foregroundColor(ColorTheme.primaryText)
            
            HStack(spacing: 24) {
                NutritionValue(
                    label: "Calories",
                    value: formatCalories(nutrition.calories)
                )
                NutritionValue(
                    label: "Protein",
                    value: "\(formatNutrient(nutrition.protein))g"
                )
                NutritionValue(
                    label: "Carbs",
                    value: "\(formatNutrient(nutrition.carbs))g"
                )
                NutritionValue(
                    label: "Fat",
                    value: "\(formatNutrient(nutrition.fat))g"
                )
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

private struct NutritionDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.subheadline)
                .foregroundColor(ColorTheme.primaryText)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(ColorTheme.surface)
    }
}

private struct DetailedNutritionView: View {
    let nutritionDetails: [String: String]
    
    private var validNutritionItems: [(String, String)] {
        nutritionDetails
            .sorted { $0.key < $1.key }
            .filter { item in
                item.value != "N/A" && item.value != "0" && item.value != "0.0"
            }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Nutrition")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(spacing: 2) {
                ForEach(validNutritionItems, id: \.0) { key, value in
                    NutritionDetailRow(label: key, value: value)
                }
            }
            .background(ColorTheme.surface)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

private struct HealthInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Information")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(spacing: 12) {
                HealthInfoRow(
                    icon: "exclamationmark.triangle",
                    iconColor: .orange,
                    title: "Triggers:",
                    value: "None detected"
                )
                
                HealthInfoRow(
                    icon: "allergens",
                    iconColor: .red,
                    title: "Allergens:",
                    value: "None detected"
                )
            }
        }
        .padding(.horizontal)
    }
}

private struct HealthInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            Text(title)
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}

private struct SourceInfoView: View {
    let source: FoodInputSource
    
    private var sourceDescription: String {
        switch source {
        case .manual:
            return "Manual Entry"
        case .barcode:
            return "Barcode Scan"
        case .lidar:
            return "LiDAR Scan"
        case .ai:
            return "AI Detection"
        }
    }
    
    var body: some View {
        HStack {
            Text("Source:")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
            
            Text(sourceDescription)
                .font(.subheadline)
                .foregroundColor(ColorTheme.primaryText)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct FoodDetailView: View {
    let foodItem: FoodItem
    
    private var content: some View {
        VStack(spacing: 24) {
            FoodHeaderView(foodItem: foodItem)
            NutritionCardView(nutrition: foodItem.nutrition)
            
            if !foodItem.nutritionDetails.isEmpty {
                DetailedNutritionView(nutritionDetails: foodItem.nutritionDetails)
            }
            
            HealthInfoView()
            
            SourceInfoView(source: foodItem.source)
        }
    }
    
    var body: some View {
        ScrollView {
            content
                .padding(.vertical)
        }
        .navigationTitle(foodItem.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
