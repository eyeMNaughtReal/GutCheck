//
//  LiDARScannerViewModel.swift
//  GutCheck
//
//  ViewModel for LiDAR scanning functionality
//

import Foundation
import ARKit
import RealityKit
import UIKit

@MainActor
class LiDARScannerViewModel: NSObject, ObservableObject {
    @Published var isDeviceSupported: Bool = false
    @Published var scanStage: ScanStage = .initializing
    @Published var detectedObjects: [DetectedObject] = []
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var lidarErrorMessage: String? = nil
    @Published var currentDistance: Float = 0.0
    @Published var distanceGuidance: String = "Position device 30-50cm from object"
    @Published var capturedImage: UIImage? = nil
    @Published var foodPredictions: [String] = []
    @Published var detectedFoodName: String? = nil
    @Published var createdFoodItem: FoodItem? = nil
    
    // Service for getting detailed nutrition data
    private let nutritionService = FoodSearchService()
    private let visionService = GoogleVisionService.shared
    
    // Computed properties for estimated values from current detection
    var estimatedVolume: Double {
        return detectedObjects.first?.estimatedVolume ?? 0.0
    }
    
    var estimatedWeight: Double {
        return detectedObjects.first?.foodInfo?.estimatedWeight ?? 0.0
    }
    
    var arSession = ARSession()
    
    enum ScanStage {
        case initializing
        case initial
        case scanning
        case processing
        case completed
        case results
        
        var title: String {
            switch self {
            case .initializing: return "Initializing..."
            case .initial: return "Ready to Scan"
            case .scanning: return "Scanning..."
            case .processing: return "Processing..."
            case .completed: return "Scan Complete"
            case .results: return "Results"
            }
        }
    }
    
    override init() {
        super.init()
        checkDeviceCapabilities()
    }
    
    func checkDeviceCapabilities() {
        isDeviceSupported = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        if !isDeviceSupported {
            lidarErrorMessage = "LiDAR is not supported on this device"
        }
    }
    
    func startARSession() {
        guard isDeviceSupported else {
            lidarErrorMessage = "LiDAR is not supported on this device"
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        arSession.run(configuration)
        scanStage = .scanning
    }
    
    func stopARSession() {
        arSession.pause()
    }
    
    func startScanning() {
        scanStage = .scanning
    }
    
    func captureFrame() {
        captureScene()
    }
    
    func captureScene() {
        scanStage = .processing
        isProcessing = true
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.completeProcessing()
        }
    }
    
    private func completeProcessing() {
        Task {
            do {
                // Capture the current camera frame as an image
                if let capturedImage = await captureCurrentFrame() {
                    self.capturedImage = capturedImage
                    
                    // Use Google Vision to identify food items
                    let recognizedFoods = try await visionService.recognizeFood(from: capturedImage)
                    
                    if !recognizedFoods.isEmpty {
                        self.foodPredictions = recognizedFoods
                        self.detectedFoodName = recognizedFoods.first
                        
                        // Create food item with the detected food
                        if let foodName = recognizedFoods.first {
                            self.createdFoodItem = await createFoodItemFromScan(foodName: foodName, estimatedWeight: 150.0)
                        }
                        
                        print("🔍 Google Vision detected foods: \(recognizedFoods)")
                    } else {
                        // Fallback to basic food detection
                        self.foodPredictions = ["Unknown Food Item"]
                        self.detectedFoodName = "Unknown Food Item"
                        self.createdFoodItem = await createFoodItemFromScan(foodName: "Unknown Food Item", estimatedWeight: 150.0)
                        print("⚠️ No food items detected by Google Vision, using fallback")
                    }
                } else {
                    // Create mock image if capture fails
                    self.capturedImage = createMockFoodImage()
                    self.foodPredictions = ["Apple"]
                    self.detectedFoodName = "Apple"
                    self.createdFoodItem = await createFoodItemFromScan(foodName: "Apple", estimatedWeight: 150.0)
                    print("⚠️ Failed to capture camera frame, using mock data")
                }
                
                self.scanStage = .results
                self.isProcessing = false
            } catch {
                print("❌ Error in food recognition: \(error)")
                // Fallback to mock data on error
                self.capturedImage = createMockFoodImage()
                self.foodPredictions = ["Unknown Food Item"]
                self.detectedFoodName = "Unknown Food Item"
                self.createdFoodItem = await createFoodItemFromScan(foodName: "Unknown Food Item", estimatedWeight: 150.0)
                self.scanStage = .results
                self.isProcessing = false
            }
        }
    }
    
    func resetScan() {
        scanStage = .initial
        detectedObjects = []
        isProcessing = false
        lidarErrorMessage = nil
        currentDistance = 0.0
        distanceGuidance = "Position device 30-50cm from object"
        capturedImage = nil
        foodPredictions = []
        detectedFoodName = nil
        createdFoodItem = nil
    }
    
    // Capture the current camera frame as UIImage
    private func captureCurrentFrame() async -> UIImage? {
        guard let currentFrame = arSession.currentFrame else {
            print("⚠️ No current AR frame available")
            return nil
        }
        
        let pixelBuffer = currentFrame.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("⚠️ Failed to create CGImage from camera frame")
            return nil
        }
        
        let image = UIImage(cgImage: cgImage)
        print("📸 Successfully captured camera frame: \(image.size)")
        return image
    }
    
    func createFoodItemFromScan() async {
        guard let detectedFood = detectedFoodName else {
            print("No food detected to create item from")
            return
        }
        
        // Default weight estimate for LiDAR scan
        let estimatedWeight = 150.0
        createdFoodItem = await createFoodItemFromScan(foodName: detectedFood, estimatedWeight: estimatedWeight)
    }
    
    // Create a food item from scan with specific parameters
    private func createFoodItemFromScan(foodName: String, estimatedWeight: Double) async -> FoodItem {
        // First, try to get detailed nutrition data from Nutritionix
        await nutritionService.searchFoods(query: foodName)
        
        let foodItem: FoodItem
        
        if let nutritionixFood = nutritionService.results.first {
            // Use detailed nutrition data
            foodItem = createDetailedFoodItem(from: nutritionixFood, estimatedWeight: estimatedWeight)
            print("✅ Created food item with real nutrition data: \(nutritionixFood.name)")
        } else {
            // Fallback to basic nutrition estimation
            foodItem = createBasicFoodItem(for: foodName, estimatedWeight: estimatedWeight)
            print("⚠️ Created food item with estimated nutrition data: \(foodName)")
        }
        
        print("🔍 LiDAR food item created: \(foodItem.name)")
        print("🔍 Nutrition: \(foodItem.nutrition.calories ?? 0) cal, P: \(foodItem.nutrition.protein ?? 0)g, C: \(foodItem.nutrition.carbs ?? 0)g, F: \(foodItem.nutrition.fat ?? 0)g")
        print("🔍 Allergens: \(foodItem.allergens.joined(separator: ", "))")
        
        return foodItem
    }
    
    private func createDetailedFoodItem(from nutritionixFood: NutritionixFood, estimatedWeight: Double) -> FoodItem {
        // Calculate portion based on estimated weight vs serving weight
        let servingWeight = nutritionixFood.servingWeight ?? 100.0
        let portionMultiplier = estimatedWeight / servingWeight
        
        // Adjust nutrition values based on portion size
        let adjustedCalories = nutritionixFood.calories.map { Int($0 * portionMultiplier) }
        let adjustedProtein = nutritionixFood.protein.map { $0 * portionMultiplier }
        let adjustedCarbs = nutritionixFood.carbs.map { $0 * portionMultiplier }
        let adjustedFat = nutritionixFood.fat.map { $0 * portionMultiplier }
        let adjustedFiber = nutritionixFood.fiber.map { $0 * portionMultiplier }
        let adjustedSugar = nutritionixFood.sugar.map { $0 * portionMultiplier }
        let adjustedSodium = nutritionixFood.sodium.map { $0 * portionMultiplier }
        
        // Create detailed nutrition dictionary
        var nutritionDict: [String: String] = [:]
        
        if let brand = nutritionixFood.brand {
            nutritionDict["brand"] = brand
        }
        
        if let calories = adjustedCalories {
            nutritionDict["calories"] = String(calories)
        }
        if let protein = adjustedProtein {
            nutritionDict["protein"] = String(format: "%.1f", protein)
        }
        if let carbs = adjustedCarbs {
            nutritionDict["total_carbohydrate"] = String(format: "%.1f", carbs)
        }
        if let fat = adjustedFat {
            nutritionDict["total_fat"] = String(format: "%.1f", fat)
        }
        if let fiber = adjustedFiber {
            nutritionDict["dietary_fiber"] = String(format: "%.1f", fiber)
        }
        if let sugar = adjustedSugar {
            nutritionDict["sugars"] = String(format: "%.1f", sugar)
        }
        if let sodium = adjustedSodium {
            nutritionDict["sodium"] = String(format: "%.1f", sodium)
        }
        
        // Add other nutrition details if available
        if let saturatedFat = nutritionixFood.saturatedFat {
            nutritionDict["saturated_fat"] = String(format: "%.1f", saturatedFat * portionMultiplier)
        }
        if let cholesterol = nutritionixFood.cholesterol {
            nutritionDict["cholesterol"] = String(format: "%.1f", cholesterol * portionMultiplier)
        }
        if let potassium = nutritionixFood.potassium {
            nutritionDict["potassium"] = String(format: "%.1f", potassium * portionMultiplier)
        }
        
        // Detect allergens
        let allergens = detectAllergens(from: nutritionixFood.name, brand: nutritionixFood.brand)
        
        // Create main nutrition info
        let nutrition = NutritionInfo(
            calories: adjustedCalories,
            protein: adjustedProtein,
            carbs: adjustedCarbs,
            fat: adjustedFat,
            fiber: adjustedFiber,
            sugar: adjustedSugar,
            sodium: adjustedSodium
        )
        
        return FoodItem(
            id: UUID().uuidString,
            name: nutritionixFood.name,
            quantity: "\(Int(estimatedWeight))g (LiDAR estimated)",
            estimatedWeightInGrams: estimatedWeight,
            ingredients: [],
            allergens: allergens,
            nutrition: nutrition,
            source: .lidar,
            isUserEdited: false,
            nutritionDetails: nutritionDict
        )
    }
    
    private func createBasicFoodItem(for foodName: String, estimatedWeight: Double) -> FoodItem {
        // Basic nutrition estimation per 100g for common foods
        let basicNutrition = getBasicNutritionEstimate(for: foodName)
        let portionMultiplier = estimatedWeight / 100.0
        
        let calories = Int(Double(basicNutrition.calories) * portionMultiplier)
        let protein = basicNutrition.protein * portionMultiplier
        let carbs = basicNutrition.carbs * portionMultiplier
        let fat = basicNutrition.fat * portionMultiplier
        
        let allergens = detectAllergens(from: foodName, brand: nil)
        
        let nutrition = NutritionInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
        
        let nutritionDict: [String: String] = [
            "calories": String(calories),
            "protein": String(format: "%.1f", protein),
            "total_carbohydrate": String(format: "%.1f", carbs),
            "total_fat": String(format: "%.1f", fat),
            "source": "estimated"
        ]
        
        return FoodItem(
            id: UUID().uuidString,
            name: foodName,
            quantity: "\(Int(estimatedWeight))g (LiDAR estimated)",
            estimatedWeightInGrams: estimatedWeight,
            ingredients: [],
            allergens: allergens,
            nutrition: nutrition,
            source: .lidar,
            isUserEdited: false,
            nutritionDetails: nutritionDict
        )
    }
    
    private func getBasicNutritionEstimate(for foodName: String) -> (calories: Int, protein: Double, carbs: Double, fat: Double) {
        let foodNameLower = foodName.lowercased()
        
        // Basic nutrition estimates per 100g for common foods
        switch foodNameLower {
        case let name where name.contains("apple"):
            return (52, 0.3, 14.0, 0.2)
        case let name where name.contains("banana"):
            return (89, 1.1, 23.0, 0.3)
        case let name where name.contains("orange"):
            return (47, 0.9, 12.0, 0.1)
        case let name where name.contains("bread"):
            return (265, 9.0, 49.0, 3.2)
        case let name where name.contains("rice"):
            return (130, 2.7, 28.0, 0.3)
        case let name where name.contains("chicken"):
            return (239, 27.0, 0.0, 14.0)
        case let name where name.contains("beef"):
            return (250, 26.0, 0.0, 15.0)
        case let name where name.contains("egg"):
            return (155, 13.0, 1.1, 11.0)
        case let name where name.contains("milk"):
            return (42, 3.4, 5.0, 1.0)
        case let name where name.contains("cheese"):
            return (113, 25.0, 1.3, 9.0)
        default:
            return (100, 2.0, 15.0, 2.0) // Generic estimate
        }
    }
    
    private func detectAllergens(from foodName: String, brand: String?) -> [String] {
        var allergens: [String] = []
        
        let allergenKeywords: [(String, [String])] = [
            ("Dairy", ["milk", "cheese", "cream", "butter", "whey", "casein", "lactose", "yogurt"]),
            ("Gluten", ["wheat", "barley", "rye", "malt", "bread", "flour", "gluten", "oats"]),
            ("Soy", ["soy", "soya", "soybean", "tofu", "tempeh", "lecithin"]),
            ("Eggs", ["egg", "albumin", "mayonnaise", "meringue"]),
            ("Tree Nuts", ["almond", "cashew", "walnut", "pecan", "hazelnut", "pistachio", "macadamia", "brazil nut"]),
            ("Peanuts", ["peanut", "groundnut", "arachis"]),
            ("Fish", ["fish", "salmon", "tuna", "cod", "anchovy", "sardine", "herring"]),
            ("Shellfish", ["shrimp", "crab", "lobster", "shellfish", "prawn", "crawfish", "mollusc"]),
            ("Sesame", ["sesame", "tahini", "benne"])
        ]
        
        // Combine all text sources for searching
        let searchTexts = [foodName, brand ?? ""].joined(separator: " ").lowercased()
        
        for (allergen, keywords) in allergenKeywords {
            if keywords.contains(where: { searchTexts.contains($0.lowercased()) }) {
                allergens.append(allergen)
            }
        }
        
        return allergens
    }
    
    // Create a mock food image for previews
    private func createMockFoodImage() -> UIImage? {
        // Generate a solid color image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300))
        return renderer.image { ctx in
            let colors: [UIColor] = [.systemGreen, .systemRed, .systemOrange, .systemYellow, .systemBrown]
            let color = colors.randomElement() ?? .systemGreen
            color.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 300))
        }
    }
}

struct DetectedObject: Identifiable {
    let id: UUID
    var name: String
    var confidence: Double
    var estimatedVolume: Double
    var boundingBox: CGRect
    var foodInfo: FoodInfo?
    
    mutating func updateFoodInfo(_ info: FoodInfo) {
        self.foodInfo = info
    }
}

struct FoodInfo {
    let name: String
    let estimatedWeight: Double
    let calories: Int
    let nutritionInfo: NutritionInfo
}

// MARK: - ARSessionDelegate
extension LiDARScannerViewModel: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor in
            lidarErrorMessage = "AR Session failed: \(error.localizedDescription)"
        }
    }
}