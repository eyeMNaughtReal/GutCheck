//
//  HealthKitTestView.swift
//  GutCheck
//
//  Test view to verify HealthKit data writing functionality
//

import SwiftUI
import HealthKit

struct HealthKitTestView: View {
    @State private var isAuthorized = false
    @State private var isLoading = false
    @State private var statusMessage = "Ready to test HealthKit integration"
    @State private var testResults: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("HealthKit Integration Test")
                    .font(.title)
                    .padding()
                
                Text(statusMessage)
                    .foregroundColor(isAuthorized ? .green : .orange)
                    .multilineTextAlignment(.center)
                    .padding()
                
                if isLoading {
                    ProgressView("Testing...")
                } else {
                    VStack(spacing: 12) {
                        Button("Request HealthKit Authorization") {
                            requestAuthorization()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isAuthorized)
                        
                        if isAuthorized {
                            Button("Test Meal Data Write") {
                                testMealDataWrite()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Test Symptom Data Write") {
                                testSymptomDataWrite()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Test Water Intake Write") {
                                testWaterIntakeWrite()
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button("Clear Test Results") {
                            testResults.removeAll()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                    }
                    .padding()
                }
                
                if !testResults.isEmpty {
                    List(testResults, id: \.self) { result in
                        Text(result)
                            .font(.system(.body, design: .monospaced))
                    }
                    .frame(maxHeight: 300)
                }
                
                Spacer()
            }
            .navigationTitle("HealthKit Test")
        }
    }
    
    private func requestAuthorization() {
        isLoading = true
        statusMessage = "Requesting HealthKit authorization..."
        
        HealthKitManager.shared.requestAuthorization { success, error in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    isAuthorized = true
                    statusMessage = "✅ HealthKit authorized successfully!"
                    testResults.append("✅ Authorization granted at \(Date().formatted())")
                } else {
                    statusMessage = "❌ HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")"
                    testResults.append("❌ Authorization failed: \(error?.localizedDescription ?? "Unknown")")
                }
            }
        }
    }
    
    private func testMealDataWrite() {
        isLoading = true
        statusMessage = "Testing meal data write..."
        
        // Create test meal with proper nutrition info
        var testNutrition = NutritionInfo()
        testNutrition.calories = 350
        testNutrition.protein = 25.0
        testNutrition.carbs = 45.0
        testNutrition.fat = 12.0
        testNutrition.fiber = 8.0
        testNutrition.sugar = 15.0
        testNutrition.sodium = 850.0
        
        let testFoodItem = FoodItem(
            name: "Test Food",
            quantity: "1 serving",
            nutrition: testNutrition
        )
        
        let testMeal = Meal(
            name: "HealthKit Test Meal",
            date: Date(),
            type: .lunch,
            source: .manual,
            foodItems: [testFoodItem],
            notes: "Test meal for HealthKit integration",
            tags: ["test"],
            createdBy: "test-user"
        )
        
        HealthKitManager.shared.writeMealToHealthKit(testMeal) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    statusMessage = "✅ Test meal written to HealthKit successfully!"
                    testResults.append("✅ Meal data written: 350 cal, 25g protein, 45g carbs, 12g fat")
                } else {
                    statusMessage = "❌ Failed to write meal data: \(error?.localizedDescription ?? "Unknown error")"
                    testResults.append("❌ Meal write failed: \(error?.localizedDescription ?? "Unknown")")
                }
            }
        }
    }
    
    private func testSymptomDataWrite() {
        isLoading = true
        statusMessage = "Testing symptom data write..."
        
        // Create test symptom
        let testSymptom = Symptom(
            date: Date(),
            stoolType: .type4,
            painLevel: .mild,
            urgencyLevel: .mild,
            notes: "Test symptom for HealthKit integration",
            tags: ["test"],
            createdBy: "test-user"
        )
        
        HealthKitManager.shared.writeSymptomToHealthKit(testSymptom) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    statusMessage = "✅ Test symptom written to HealthKit successfully!"
                    testResults.append("✅ Symptom data written: Type 4, Mild pain, Mild urgency")
                } else {
                    statusMessage = "❌ Failed to write symptom data: \(error?.localizedDescription ?? "Unknown error")"
                    testResults.append("❌ Symptom write failed: \(error?.localizedDescription ?? "Unknown")")
                }
            }
        }
    }
    
    private func testWaterIntakeWrite() {
        isLoading = true
        statusMessage = "Testing water intake write..."
        
        let waterAmount = 500.0 // 500ml
        
        HealthKitManager.shared.writeWaterIntakeToHealthKit(amount: waterAmount) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    statusMessage = "✅ Test water intake written to HealthKit successfully!"
                    testResults.append("✅ Water intake written: \(waterAmount)ml")
                } else {
                    statusMessage = "❌ Failed to write water intake: \(error?.localizedDescription ?? "Unknown error")"
                    testResults.append("❌ Water write failed: \(error?.localizedDescription ?? "Unknown")")
                }
            }
        }
    }
}

#if DEBUG
struct HealthKitTestView_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitTestView()
    }
}
#endif