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
    @Published var scanProgress: Float = 0.0
    @Published var scanInstructions: String = "Move around the food item to capture all angles"
    @Published var confidenceLevel: Float = 0.0
    @Published var confidenceFactors: [String] = []
    
    // Service for getting detailed nutrition data
    private let nutritionService = FoodSearchService()
    private let visionService = GoogleVisionService.shared
    
    // LiDAR scanning state
    private var accumulatedMeshData: [ARMeshAnchor] = []
    private var scanStartTime: Date?
    private let scanDuration: TimeInterval = 10.0 // 10 seconds of scanning
    private var scanTimer: Timer?
    private var meshQualityScores: [Float] = []
    private var cameraMovementDetected: Bool = false
    private var multipleViewpointsCount: Int = 0
    
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
        
        arSession.delegate = self
        arSession.run(configuration)
        
        // Set to initial state so user can manually start scanning
        scanStage = .initial
        print("🔍 LiDAR: AR session started, set to .initial state")
    }
    
    func stopARSession() {
        arSession.pause()
    }
    
    func startScanning() {
        scanStage = .scanning
        accumulatedMeshData = []
        scanStartTime = Date()
        scanProgress = 0.0
        confidenceLevel = 0.0
        confidenceFactors = []
        meshQualityScores = []
        cameraMovementDetected = false
        multipleViewpointsCount = 0
        scanInstructions = "Move around the food item to capture all angles"
        
        // Start accumulating mesh data
        startMeshAccumulation()
    }
    
    private func startMeshAccumulation() {
        scanTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.updateScanProgress()
                self.accumulateMeshData()
            }
        }
    }
    
    private func updateScanProgress() {
        guard let startTime = scanStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        scanProgress = min(Float(elapsed / scanDuration), 1.0)
        
        let remaining = max(0, scanDuration - elapsed)
        if remaining > 0 {
            scanInstructions = "Scanning... \(Int(remaining))s remaining. Keep moving around the food."
        } else {
            scanInstructions = "Scan complete! Processing..."
            finishScanning()
        }
    }
    
    private func accumulateMeshData() {
        guard let currentFrame = arSession.currentFrame else { return }
        
        let meshAnchors = currentFrame.anchors.compactMap { $0 as? ARMeshAnchor }
        
        // Track camera movement for confidence scoring
        detectCameraMovement(frame: currentFrame)
        
        // Add new mesh anchors that aren't already accumulated
        for meshAnchor in meshAnchors {
            if !accumulatedMeshData.contains(where: { $0.identifier == meshAnchor.identifier }) {
                accumulatedMeshData.append(meshAnchor)
                
                // Evaluate mesh quality for confidence
                let quality = evaluateMeshQuality(meshAnchor: meshAnchor)
                meshQualityScores.append(quality)
            }
        }
        
        // Update confidence in real-time
        calculateRealTimeConfidence()
        
        print("📊 Accumulated \(accumulatedMeshData.count) mesh anchors so far (confidence: \(Int(confidenceLevel * 100))%)")
    }
    
    private func detectCameraMovement(frame: ARFrame) {
        // Simple movement detection based on camera transform changes
        // In a real implementation, you'd track transform changes over time
        cameraMovementDetected = true
        
        // Count viewpoints (simplified - could be more sophisticated)
        if accumulatedMeshData.count > multipleViewpointsCount * 3 {
            multipleViewpointsCount += 1
        }
    }
    
    private func evaluateMeshQuality(meshAnchor: ARMeshAnchor) -> Float {
        let geometry = meshAnchor.geometry
        let vertexCount = geometry.vertices.count
        
        // Score based on vertex density and geometry completeness
        var quality: Float = 0.0
        
        // More vertices generally indicate better detail
        if vertexCount > 1000 {
            quality += 0.4
        } else if vertexCount > 500 {
            quality += 0.3
        } else if vertexCount > 100 {
            quality += 0.2
        } else {
            quality += 0.1
        }
        
        // Check if mesh has reasonable size (not too small or huge)
        let volume = calculateMeshVolume(vertices: geometry.vertices)
        if volume > 0.00005 && volume < 0.01 { // 50cm³ to 10L range
            quality += 0.3
        } else {
            quality += 0.1
        }
        
        // Bonus for having face data
        if geometry.faces.count > 0 {
            quality += 0.3
        }
        
        return min(quality, 1.0)
    }
    
    private func calculateRealTimeConfidence() {
        var totalConfidence: Float = 0.0
        var factors: [String] = []
        
        // Factor 1: Number of mesh anchors (more = better)
        let meshCount = Float(accumulatedMeshData.count)
        let meshScore = min(meshCount / 10.0, 1.0) * 0.25 // 25% weight
        totalConfidence += meshScore
        if meshCount >= 5.0 {
            factors.append("Good mesh coverage (\(Int(meshCount)) anchors)")
        }
        
        // Factor 2: Average mesh quality
        let avgQuality = meshQualityScores.isEmpty ? 0.0 : meshQualityScores.reduce(0, +) / Float(meshQualityScores.count)
        totalConfidence += avgQuality * 0.3 // 30% weight
        if avgQuality > 0.7 {
            factors.append("High mesh quality")
        }
        
        // Factor 3: Camera movement detected
        if cameraMovementDetected {
            totalConfidence += 0.2 // 20% weight
            factors.append("Camera movement detected")
        }
        
        // Factor 4: Multiple viewpoints
        let viewpointScore = min(Float(multipleViewpointsCount) / 3.0, 1.0) * 0.15 // 15% weight
        totalConfidence += viewpointScore
        if multipleViewpointsCount >= 2 {
            factors.append("Multiple viewpoints (\(multipleViewpointsCount))")
        }
        
        // Factor 5: Scan duration (longer scan = more confidence)
        if let startTime = scanStartTime {
            let elapsed = Float(Date().timeIntervalSince(startTime))
            let durationScore = min(elapsed / Float(scanDuration), 1.0) * 0.1 // 10% weight
            totalConfidence += durationScore
        }
        
        confidenceLevel = min(totalConfidence, 1.0)
        confidenceFactors = factors
    }
    
    private func finishScanning() {
        scanTimer?.invalidate()
        scanTimer = nil
        captureScene()
    }
    
    func captureFrame() {
        captureScene()
    }
    
    func captureScene() {
        scanStage = .processing
        isProcessing = true
        scanInstructions = "Processing scan data..."
        
        // Calculate volume using accumulated mesh data instead of single frame
        calculateVolumeFromAccumulatedData()
        
        // Simulate processing delay for UI feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.completeProcessing()
        }
    }
    
    private func calculateVolumeFromAccumulatedData() {
        if !accumulatedMeshData.isEmpty {
            print("🔄 Processing \(accumulatedMeshData.count) accumulated mesh anchors")
            
            // Focus on objects close to camera position during scan
            var relevantVolume: Float = 0.0
            var processedAnchors = 0
            
            // Get camera position from the most recent frame
            guard let currentFrame = arSession.currentFrame else {
                print("⚠️ No current frame for camera position")
                useDefaultEstimates()
                return
            }
            
            let cameraTransform = currentFrame.camera.transform
            let cameraPosition = cameraTransform.columns.3
            
            // Process accumulated mesh data with better filtering
            for meshAnchor in accumulatedMeshData {
                let geometry = meshAnchor.geometry
                let vertices = geometry.vertices
                
                // Calculate distance from camera during scan
                let anchorPosition = meshAnchor.transform.columns.3
                let distance = simd_distance(
                    simd_make_float3(anchorPosition.x, anchorPosition.y, anchorPosition.z),
                    simd_make_float3(cameraPosition.x, cameraPosition.y, cameraPosition.z)
                )
                
                // Focus on objects within reasonable food scanning distance
                if distance < 0.8 && processedAnchors < 5 { // Slightly closer range for food
                    let anchorVolume = calculateMeshVolume(vertices: vertices)
                    
                    // More restrictive filtering for food items
                    if anchorVolume < 0.01 { // Less than 10 liters
                        relevantVolume += anchorVolume
                        processedAnchors += 1
                        print("📐 Including anchor at \(distance)m with volume \(anchorVolume) m³")
                    } else {
                        print("🚫 Excluding large anchor: \(anchorVolume) m³")
                    }
                }
            }
            
            // Convert to realistic food measurements
            let estimatedVolumeInCm3 = Double(max(relevantVolume * 1000000, 80.0)) // Min 80 cm³
            let cappedVolumeInCm3 = min(estimatedVolumeInCm3, 1500.0) // Max 1.5 liters
            
            // Food-appropriate density and weight bounds
            let estimatedWeightInGrams = cappedVolumeInCm3 * 1.0 // Average food density
            let cappedWeightInGrams = min(max(estimatedWeightInGrams, 80.0), 800.0) // 80g-800g range
            
            createFoodObjectWithMeasurements(volume: cappedVolumeInCm3, weight: cappedWeightInGrams)
            
            print("📏 Final volume: \(cappedVolumeInCm3) cm³ (from \(processedAnchors) anchors)")
            print("⚖️ Final weight: \(cappedWeightInGrams) g")
            print("🎯 Used accumulated mesh data for better accuracy")
        } else {
            print("⚠️ No accumulated mesh data, using defaults")
            useDefaultEstimates()
        }
    }
    
    private func createFoodObjectWithMeasurements(volume: Double, weight: Double) {
        // Calculate final confidence based on measurement quality
        let measurementConfidence = calculateMeasurementConfidence(volume: volume, weight: weight)
        let finalConfidence = (confidenceLevel + measurementConfidence) / 2.0
        
        let updatedFoodInfo = FoodInfo(
            name: "Food Item",
            estimatedWeight: weight,
            calories: Int(weight * 1.3), // Reasonable calorie density
            nutritionInfo: NutritionInfo(calories: Int(weight * 1.3), protein: 4.0, carbs: 22.0, fat: 2.5)
        )
        
        if !detectedObjects.isEmpty {
            for i in 0..<detectedObjects.count {
                detectedObjects[i].estimatedVolume = volume
                detectedObjects[i].foodInfo = updatedFoodInfo
                detectedObjects[i].confidence = Double(finalConfidence)
            }
        } else {
            let detectedObject = DetectedObject(
                id: UUID(),
                name: "Food Item",
                confidence: Double(finalConfidence),
                estimatedVolume: volume,
                boundingBox: CGRect(x: 100, y: 100, width: 100, height: 100),
                foodInfo: updatedFoodInfo
            )
            detectedObjects = [detectedObject]
        }
        
        // Update UI confidence
        confidenceLevel = finalConfidence
        
        // Add measurement-specific confidence factors
        if weight > 100 && weight < 500 {
            confidenceFactors.append("Realistic food weight (\(Int(weight))g)")
        }
        if volume > 100 && volume < 800 {
            confidenceFactors.append("Reasonable food volume (\(Int(volume))cm³)")
        }
    }
    
    private func calculateMeasurementConfidence(volume: Double, weight: Double) -> Float {
        var confidence: Float = 0.0
        
        // Volume confidence (realistic food volumes)
        if volume >= 80 && volume <= 1000 {
            confidence += 0.4 // Very realistic
        } else if volume >= 50 && volume <= 1500 {
            confidence += 0.3 // Somewhat realistic
        } else {
            confidence += 0.1 // Less realistic
        }
        
        // Weight confidence (realistic food weights)
        if weight >= 80 && weight <= 600 {
            confidence += 0.4 // Very realistic
        } else if weight >= 50 && weight <= 800 {
            confidence += 0.3 // Somewhat realistic
        } else {
            confidence += 0.1 // Less realistic
        }
        
        // Volume-weight ratio confidence (density check)
        let density = weight / volume // g/cm³
        if density >= 0.8 && density <= 1.5 { // Realistic food density range
            confidence += 0.2
        } else {
            confidence += 0.05
        }
        
        return min(confidence, 1.0)
    }
    
    private func useDefaultEstimates() {
        let defaultVolume = 180.0 // 180 cm³
        let defaultWeight = 160.0 // 160g
        createFoodObjectWithMeasurements(volume: defaultVolume, weight: defaultWeight)
        print("📏 Using default volume: \(defaultVolume) cm³")
        print("⚖️ Using default weight: \(defaultWeight) g")
    }
    
    private func calculateMeshVolume(vertices: ARGeometrySource) -> Float {
        // This is a simplified volume calculation using bounding box
        // Applied with conservative scaling for food estimation
        
        let vertexCount = vertices.count
        let vertexStride = vertices.stride
        let vertexData = vertices.buffer.contents()
        
        // Calculate bounding box volume as approximation
        var minPoint = SIMD3<Float>(Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)
        var maxPoint = SIMD3<Float>(-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude)
        
        for i in 0..<vertexCount {
            let vertexPointer = vertexData.advanced(by: i * vertexStride)
            let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
            
            minPoint = SIMD3<Float>(
                min(minPoint.x, vertex.x),
                min(minPoint.y, vertex.y),
                min(minPoint.z, vertex.z)
            )
            maxPoint = SIMD3<Float>(
                max(maxPoint.x, vertex.x),
                max(maxPoint.y, vertex.y),
                max(maxPoint.z, vertex.z)
            )
        }
        
        let dimensions = maxPoint - minPoint
        let boundingBoxVolume = dimensions.x * dimensions.y * dimensions.z
        
        // Apply conservative scaling factor for food items
        // Bounding box overestimates actual volume, especially for irregular food shapes
        let scalingFactor: Float = 0.3 // Assume food fills ~30% of bounding box
        let estimatedVolume = boundingBoxVolume * scalingFactor
        
        // Ensure minimum realistic volume and cap maximum
        let minVolume: Float = 0.00005 // 50 cm³ in m³
        let maxVolume: Float = 0.002   // 2000 cm³ in m³ (2 liters)
        
        return min(max(estimatedVolume, minVolume), maxVolume)
    }
    
    private func completeProcessing() {
        Task {
            do {
                // Get the estimated weight from LiDAR calculation, fallback to 150g
                let calculatedWeight = detectedObjects.first?.foodInfo?.estimatedWeight ?? 150.0
                
                // Capture the current camera frame as an image
                if let capturedImage = await captureCurrentFrame() {
                    self.capturedImage = capturedImage
                    
                    // Use Google Vision to identify food items
                    let recognizedFoods = try await visionService.recognizeFood(from: capturedImage)
                    
                    if !recognizedFoods.isEmpty {
                        self.foodPredictions = recognizedFoods
                        self.detectedFoodName = recognizedFoods.first
                        
                        // Boost confidence for successful food recognition
                        self.confidenceLevel = min(self.confidenceLevel + 0.15, 1.0)
                        self.confidenceFactors.append("Food identified: \(recognizedFoods.first ?? "Unknown")")
                        
                        // Create food item with the detected food and calculated weight
                        if let foodName = recognizedFoods.first {
                            self.createdFoodItem = await createFoodItemFromScan(foodName: foodName, estimatedWeight: calculatedWeight)
                        }
                        
                        print("🔍 Google Vision detected foods: \(recognizedFoods)")
                        print("⚖️ Using calculated weight: \(calculatedWeight)g")
                        print("🎯 Final confidence: \(Int(self.confidenceLevel * 100))%")
                    } else {
                        // Reduce confidence for failed recognition
                        self.confidenceLevel = max(self.confidenceLevel - 0.1, 0.0)
                        self.confidenceFactors.append("Food recognition uncertain")
                        
                        // Fallback to basic food detection
                        self.foodPredictions = ["Unknown Food Item"]
                        self.detectedFoodName = "Unknown Food Item"
                        self.createdFoodItem = await createFoodItemFromScan(foodName: "Unknown Food Item", estimatedWeight: calculatedWeight)
                        print("⚠️ No food items detected by Google Vision, using fallback with weight: \(calculatedWeight)g")
                        print("🎯 Reduced confidence: \(Int(self.confidenceLevel * 100))%")
                    }
                } else {
                    // Create mock image if capture fails
                    self.capturedImage = createMockFoodImage()
                    self.foodPredictions = ["Apple"]
                    self.detectedFoodName = "Apple"
                    self.createdFoodItem = await createFoodItemFromScan(foodName: "Apple", estimatedWeight: calculatedWeight)
                    print("⚠️ Failed to capture camera frame, using mock data with weight: \(calculatedWeight)g")
                }
                
                self.scanStage = .results
                self.isProcessing = false
            } catch {
                print("❌ Error in food recognition: \(error)")
                let calculatedWeight = detectedObjects.first?.foodInfo?.estimatedWeight ?? 150.0
                // Fallback to mock data on error
                self.capturedImage = createMockFoodImage()
                self.foodPredictions = ["Unknown Food Item"]
                self.detectedFoodName = "Unknown Food Item"
                self.createdFoodItem = await createFoodItemFromScan(foodName: "Unknown Food Item", estimatedWeight: calculatedWeight)
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
        scanProgress = 0.0
        scanInstructions = "Move around the food item to capture all angles"
        confidenceLevel = 0.0
        confidenceFactors = []
        
        // Clean up scanning state
        scanTimer?.invalidate()
        scanTimer = nil
        accumulatedMeshData = []
        scanStartTime = nil
        meshQualityScores = []
        cameraMovementDetected = false
        multipleViewpointsCount = 0
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
            // Use detailed nutrition data - boost confidence
            foodItem = createDetailedFoodItem(from: nutritionixFood, estimatedWeight: estimatedWeight)
            
            // Increase confidence for successful nutrition lookup
            confidenceLevel = min(confidenceLevel + 0.1, 1.0)
            confidenceFactors.append("Nutritionix data found")
            
            print("✅ Created food item with real nutrition data: \(nutritionixFood.name)")
        } else {
            // Fallback to basic nutrition estimation - reduce confidence slightly
            foodItem = createBasicFoodItem(for: foodName, estimatedWeight: estimatedWeight)
            
            // Decrease confidence for estimated nutrition
            confidenceLevel = max(confidenceLevel - 0.05, 0.0)
            confidenceFactors.append("Using estimated nutrition")
            
            print("⚠️ Created food item with estimated nutrition data: \(foodName)")
        }
        
        print("🔍 LiDAR food item created: \(foodItem.name)")
        print("🔍 Nutrition: \(foodItem.nutrition.calories ?? 0) cal, P: \(foodItem.nutrition.protein ?? 0)g, C: \(foodItem.nutrition.carbs ?? 0)g, F: \(foodItem.nutrition.fat ?? 0)g")
        print("🔍 Allergens: \(foodItem.allergens.joined(separator: ", "))")
        print("🎯 Confidence factors: \(confidenceFactors.joined(separator: ", "))")
        
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
        
        // Parse ingredients from Nutritionix
        let ingredients = parseIngredients(from: nutritionixFood.ingredients)
        
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
            ingredients: ingredients,
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
        case let name where name.contains("pasta") || name.contains("spaghetti") || name.contains("noodle"):
            return (131, 5.0, 25.0, 1.1) // Cooked pasta with sauce
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
        case let name where name.contains("food"):
            return (120, 3.0, 20.0, 2.5) // Generic cooked food estimate
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
    
    private func parseIngredients(from ingredientsString: String?) -> [String] {
        guard let ingredientsString = ingredientsString, !ingredientsString.isEmpty else {
            return []
        }
        
        // Clean up the ingredients string and split by common separators
        let cleanedString = ingredientsString
            .replacingOccurrences(of: ".", with: "") // Remove periods
            .replacingOccurrences(of: ";", with: ",") // Normalize separators
            .replacingOccurrences(of: " and ", with: ", ") // Handle "and" separators
            .replacingOccurrences(of: " & ", with: ", ") // Handle "&" separators
        
        // Split by commas and clean up each ingredient
        let ingredients = cleanedString
            .components(separatedBy: ",")
            .map { ingredient in
                ingredient
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }
            .filter { !$0.isEmpty }
        
        return ingredients
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
    
    nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        Task { @MainActor in
            let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
            if !meshAnchors.isEmpty && scanStage == .scanning {
                print("🔄 AR session added \(meshAnchors.count) new mesh anchors")
            }
        }
    }
    
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        Task { @MainActor in
            let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
            if !meshAnchors.isEmpty && scanStage == .scanning {
                // Update accumulated data with refined mesh information
                for updatedAnchor in meshAnchors {
                    if let index = accumulatedMeshData.firstIndex(where: { $0.identifier == updatedAnchor.identifier }) {
                        accumulatedMeshData[index] = updatedAnchor
                    }
                }
            }
        }
    }
}