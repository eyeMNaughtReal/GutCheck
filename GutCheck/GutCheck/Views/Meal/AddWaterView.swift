//
//  AddWaterView.swift
//  GutCheck
//
//  Created on 8/2/25.
//

import SwiftUI
import UIKit

struct AddWaterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cups: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Simple input
            HStack {
                TextField("0", value: $cups, format: .number)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ColorTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ColorTheme.primary.opacity(0.3), lineWidth: 1)
                    )
                
                Text("cup(s)")
                    .font(.title3)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            .padding(.horizontal)
            
            // Single action button
            Button(action: {
                addWater()
            }) {
                Text("Add Water")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(cups <= 0)
            .opacity(cups <= 0 ? 0.6 : 1)
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var cupsValue: Double {
        cups
    }
    
    private var fluidOunces: String {
        let oz = cups * 8.0
        return String(format: "%.1f", oz)
    }
    
    private var milliliters: String {
        let ml = cups * 236.6 // 1 cup ≈ 236.6 mL
        return String(format: "%.0f", ml)
    }
    
    // MARK: - Actions
    
    private func addWater() {
        guard cups > 0 else { return }
        
        let waterItem = FoodItem(
            name: "Water",
            quantity: "\(cups) cup\(cups == 1 ? "" : "s")",
            estimatedWeightInGrams: Double(Int(cups * 236.6)), // Convert to grams
            nutrition: NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0)
        )
        
        // Add to meal builder service
        MealBuilderService.shared.addFoodItem(waterItem)
        
        // Write water intake to HealthKit
        let millilitersAmount = cups * 236.6
        HealthKitManager.shared.writeWaterIntakeToHealthKit(amount: millilitersAmount) { success, error in
            if success {
                print("✅ AddWaterView: Successfully wrote water intake to HealthKit: \(millilitersAmount)ml")
            } else if let error = error {
                print("⚠️ AddWaterView: HealthKit water write failed: \(error.localizedDescription)")
            }
        }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddWaterView()
}
