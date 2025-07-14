//
//  LiDARScannerViewModel.swift
//  GutCheck
//
//  Created on 7/14/25.
//

import Foundation
import ARKit
import RealityKit
import SwiftUI
import Combine

// Define scanning stages
enum ScanStage: Equatable {
    case initial
    case scanning
    case processing
    case results
    
    var title: String {
        switch self {
        case .initial:
            return "LiDAR Scanner"
        case .scanning:
            return "Scanning Food"
        case .processing:
            return "Processing"
        case .results:
            return "Results"
        }
    }
}

class LiDARScannerViewModel: NSObject, ObservableObject, ARSessionDelegate {
    // AR session
    let arSession = ARSession()
    
    // LiDAR capabilities
    @Published var isDeviceSupported = false
    
    // Scanning state
    @Published var scanStage: ScanStage = .initial
    @Published var currentDistance: Float?
    @Published var distanceGuidance = "Move closer to food"
    
    // Results
    @Published var capturedImage: UIImage?
    @Published var detectedFoodName = "Unknown food"
    @Published var estimatedVolume: Float = 0
    @Published var estimatedWeight: Float = 0
    @Published var detectedFoodItem: FoodItem?
    
    // Private properties
    private var depthData: CVPixelBuffer?
    private var colorImage: CVPixelBuffer?
    
    // Check if device supports LiDAR
    func checkDeviceCapabilities() {
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            isDeviceSupported = true
        } else {
            isDeviceSupported = false
        }
    }
    
    // Start AR session
    func startARSession() {
        guard isDeviceSupported else { return }
        
        let configuration = ARWorldTrackingConfiguration()
        
        // Configure depth
        if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics = .sceneDepth
        }
        
        // Add scene reconstruction if available
        if type(of: configuration).supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        // Set delegate
        arSession.delegate = self
        
        // Run configuration
        arSession.run(configuration)
    }
    
    // Stop AR session
    func stopARSession() {
        arSession.pause()
    }
    
    // Start scanning
    func startScanning() {
        scanStage = .scanning
    }
    
    // Reset scan
    func resetScan() {
        scanStage = .scanning
        capturedImage = nil
        depthData = nil
        colorImage = nil
        detectedFoodName = "Unknown food"
        estimatedVolume = 0
        estimatedWeight = 0
    }
    
    // Capture frame
    func captureFrame() {
        guard scanStage == .scanning else { return }
        
        scanStage = .processing
        
        // Process the depth and color data
        processFrame()
    }
    
    // Process frame
    private func processFrame() {
        // In a real app, this would use depth and color data for volume estimation
        // For now, we'll simulate with mock data and a delay
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            // Generate mock results
            self.generateMockResults()
            self.scanStage = .results
        }
    }
    
    // Generate mock results
    private func generateMockResults() {
        // Mock food detection
        let foodOptions = [
            "Apple", "Banana", "Orange", "Rice", "Pasta", "Chicken breast",
            "Steak", "Mixed vegetables", "Salad", "Soup", "Sandwich"
        ]
        
        detectedFoodName = foodOptions.randomElement() ?? "Unknown food"
        
        // Mock volume estimation (in ml)
        estimatedVolume = Float.random(in: 100...500)
        
        // Mock weight estimation (in g) - approximately based on water density (1g/ml)
        estimatedWeight = estimatedVolume * Float.random(in: 0.7...1.3)
        
        // Create mock image if none exists
        if capturedImage == nil {
            capturedImage = createMockFoodImage()
        }
    }
    
    // Create food item from scan
    func createFoodItemFromScan() {
        // Create a FoodItem from the scan results
        let foodItem = FoodItem(
            name: detectedFoodName,
            quantity: "\(Int(estimatedWeight))g",
            estimatedWeightInGrams: Double(estimatedWeight),
            nutrition: estimateNutrition(foodName: detectedFoodName, weight: Double(estimatedWeight)),
            source: .lidar
        )
        
        // Show the food item detail view
        detectedFoodItem = foodItem
    }
    
    // Estimate nutrition based on food name and weight
    private func estimateNutrition(foodName: String, weight: Double) -> NutritionInfo {
        // In a real app, this would use a food database
        // For now, we'll use simple estimates based on food type
        
        var caloriesPer100g: Double = 100  // Default
        var proteinPer100g: Double = 5
        var carbsPer100g: Double = 15
        var fatPer100g: Double = 2
        
        // Very simple food categorization
        let name = foodName.lowercased()
        
        if name.contains("apple") || name.contains("banana") || name.contains("orange") {
            // Fruits
            caloriesPer100g = 60
            proteinPer100g = 0.5
            carbsPer100g = 15
            fatPer100g = 0.2
        } else if name.contains("rice") || name.contains("pasta") {
            // Starches
            caloriesPer100g = 130
            proteinPer100g = 3
            carbsPer100g = 28
            fatPer100g = 0.3
        } else if name.contains("chicken") || name.contains("steak") {
            // Meats
            caloriesPer100g = 180
            proteinPer100g = 25
            carbsPer100g = 0
            fatPer100g = 10
        } else if name.contains("vegetable") || name.contains("salad") {
            // Vegetables
            caloriesPer100g = 30
            proteinPer100g = 2
            carbsPer100g = 5
            fatPer100g = 0.3
        }
        
        // Calculate nutrition based on weight
        let ratio = weight / 100
        
        return NutritionInfo(
            calories: Int(caloriesPer100g * ratio),
            protein: proteinPer100g * ratio,
            carbs: carbsPer100g * ratio,
            fat: fatPer100g * ratio
        )
    }
    
    // Add to meal
    func addToMeal(_ foodItem: FoodItem) {
        // Add to meal builder
        MealBuilder.shared.addFoodItem(foodItem)
    }
    
    // MARK: - ARSessionDelegate
    
    // Remove @MainActor isolation to satisfy protocol
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Only process frames when scanning
        guard scanStage == .scanning else { return }
        
        // Get distance to camera focus point
        let camera = frame.camera
        
        // Use center of frame as reference point
        let screenCenter = CGPoint(x: 0.5, y: 0.5)
        
        // Get depth at center point if available
        if let depthData = frame.sceneDepth?.depthMap {
            let depthWidth = CVPixelBufferGetWidth(depthData)
            let depthHeight = CVPixelBufferGetHeight(depthData)
            
            let pixelX = Int(screenCenter.x * CGFloat(depthWidth))
            let pixelY = Int(screenCenter.y * CGFloat(depthHeight))
            
            CVPixelBufferLockBaseAddress(depthData, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(depthData, .readOnly) }
            
            if let baseAddress = CVPixelBufferGetBaseAddress(depthData) {
                let bytesPerRow = CVPixelBufferGetBytesPerRow(depthData)
                let bytesPerPixel = 4 // 32-bit float for depth data
                
                let pixelAddress = baseAddress.advanced(by: pixelY * bytesPerRow + pixelX * bytesPerPixel)
                let depthValue = pixelAddress.assumingMemoryBound(to: Float32.self).pointee
                
                // Update distance if valid on main thread
                if depthValue > 0 && depthValue.isFinite {
                    DispatchQueue.main.async {
                        self.currentDistance = depthValue
                        
                        // Update guidance based on distance
                        if depthValue < 0.2 {
                            self.distanceGuidance = "Move further away"
                        } else if depthValue > 0.4 {
                            self.distanceGuidance = "Move closer to food"
                        } else {
                            self.distanceGuidance = "Distance good for scanning"
                        }
                    }
                }
            }
        }
    }
    
    // Capture frame data for a specific frame
    func captureFrameData(_ frame: ARFrame) {
        if scanStage == .scanning {
            // Store depth data and color image for processing
            depthData = frame.sceneDepth?.depthMap
            colorImage = frame.capturedImage
            
            // Create UIImage from captured frame
            capturedImage = convertCapturedImageToUIImage(frame.capturedImage)
        }
    }
    
    // MARK: - Helper Methods
    
    // Convert CVPixelBuffer to UIImage
    private func convertCapturedImageToUIImage(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
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
).supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        // Set delegate
        arSession.delegate = self
        
        // Run configuration
        arSession.run(configuration)
    }
    
    // Stop AR session
    func stopARSession() {
        arSession.pause()
    }
    
    // Start scanning
    func startScanning() {
        scanStage = .scanning
    }
    
    // Reset scan
    func resetScan() {
        scanStage = .scanning
        capturedImage = nil
        depthData = nil
        colorImage = nil
        detectedFoodName = "Unknown food"
        estimatedVolume = 0
        estimatedWeight = 0
    }
    
    // Capture frame
    func captureFrame() {
        guard scanStage == .scanning else { return }
        
        scanStage = .processing
        
        // Process the depth and color data
        processFrame()
    }
    
    // Process frame
    private func processFrame() {
        // In a real app, this would use depth and color data for volume estimation
        // For now, we'll simulate with mock data and a delay
        
        Task {
            // Simulate processing delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
            
            // Generate mock results
            await MainActor.run {
                generateMockResults()
                scanStage = .results
            }
        }
    }
    
    // Generate mock results
    private func generateMockResults() {
        // Mock food detection
        let foodOptions = [
            "Apple", "Banana", "Orange", "Rice", "Pasta", "Chicken breast",
            "Steak", "Mixed vegetables", "Salad", "Soup", "Sandwich"
        ]
        
        detectedFoodName = foodOptions.randomElement() ?? "Unknown food"
        
        // Mock volume estimation (in ml)
        estimatedVolume = Float.random(in: 100...500)
        
        // Mock weight estimation (in g) - approximately based on water density (1g/ml)
        estimatedWeight = estimatedVolume * Float.random(in: 0.7...1.3)
        
        // Create mock image if none exists
        if capturedImage == nil {
            capturedImage = createMockFoodImage()
        }
    }
    
    // Create food item from scan
    func createFoodItemFromScan() {
        // Create a FoodItem from the scan results
        let foodItem = FoodItem(
            name: detectedFoodName,
            quantity: "\(Int(estimatedWeight))g",
            estimatedWeightInGrams: Double(estimatedWeight),
            source: .lidar,
            nutrition: estimateNutrition(foodName: detectedFoodName, weight: Double(estimatedWeight))
        )
        
        // Show the food item detail view
        detectedFoodItem = foodItem
    }
    
    // Estimate nutrition based on food name and weight
    private func estimateNutrition(foodName: String, weight: Double) -> NutritionInfo {
        // In a real app, this would use a food database
        // For now, we'll use simple estimates based on food type
        
        var caloriesPer100g: Double = 100  // Default
        var proteinPer100g: Double = 5
        var carbsPer100g: Double = 15
        var fatPer100g: Double = 2
        
        // Very simple food categorization
        let name = foodName.lowercased()
        
        if name.contains("apple") || name.contains("banana") || name.contains("orange") {
            // Fruits
            caloriesPer100g = 60
            proteinPer100g = 0.5
            carbsPer100g = 15
            fatPer100g = 0.2
        } else if name.contains("rice") || name.contains("pasta") {
            // Starches
            caloriesPer100g = 130
            proteinPer100g = 3
            carbsPer100g = 28
            fatPer100g = 0.3
        } else if name.contains("chicken") || name.contains("steak") {
            // Meats
            caloriesPer100g = 180
            proteinPer100g = 25
            carbsPer100g = 0
            fatPer100g = 10
        } else if name.contains("vegetable") || name.contains("salad") {
            // Vegetables
            caloriesPer100g = 30
            proteinPer100g = 2
            carbsPer100g = 5
            fatPer100g = 0.3
        }
        
        // Calculate nutrition based on weight
        let ratio = weight / 100
        
        return NutritionInfo(
            calories: Int(caloriesPer100g * ratio),
            protein: proteinPer100g * ratio,
            carbs: carbsPer100g * ratio,
            fat: fatPer100g * ratio
        )
    }
    
    // Add to meal
    func addToMeal(_ foodItem: FoodItem) {
        // Add to meal builder
        MealBuilder.shared.addFoodItem(foodItem)
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Only process frames when scanning
        guard scanStage == .scanning else { return }
        
        // Get distance to camera focus point
        if let camera = frame.camera {
            // Use center of frame as reference point
            let screenCenter = CGPoint(x: 0.5, y: 0.5)
            
            // Get depth at center point if available
            if let depthData = frame.sceneDepth?.depthMap {
                let depthWidth = CVPixelBufferGetWidth(depthData)
                let depthHeight = CVPixelBufferGetHeight(depthData)
                
                let pixelX = Int(screenCenter.x * CGFloat(depthWidth))
                let pixelY = Int(screenCenter.y * CGFloat(depthHeight))
                
                CVPixelBufferLockBaseAddress(depthData, .readOnly)
                defer { CVPixelBufferUnlockBaseAddress(depthData, .readOnly) }
                
                if let baseAddress = CVPixelBufferGetBaseAddress(depthData) {
                    let bytesPerRow = CVPixelBufferGetBytesPerRow(depthData)
                    let bytesPerPixel = 4 // 32-bit float for depth data
                    
                    let pixelAddress = baseAddress.advanced(by: pixelY * bytesPerRow + pixelX * bytesPerPixel)
                    let depthValue = pixelAddress.assumingMemoryBound(to: Float32.self).pointee
                    
                    // Update distance if valid
                    if depthValue > 0 && depthValue.isFinite {
                        currentDistance = depthValue
                        
                        // Update guidance based on distance
                        if depthValue < 0.2 {
                            distanceGuidance = "Move further away"
                        } else if depthValue > 0.4 {
                            distanceGuidance = "Move closer to food"
                        } else {
                            distanceGuidance = "Distance good for scanning"
                        }
                    }
                }
            }
        }
    }
    
    // Capture frame data
    func session(_ session: ARSession, didUpdate frame: ARFrame, captureImage: Bool = false) {
        if captureImage && scanStage == .scanning {
            // Store depth data and color image for processing
            depthData = frame.sceneDepth?.depthMap
            colorImage = frame.capturedImage
            
            // Create UIImage from captured frame
            capturedImage = convertCapturedImageToUIImage(frame.capturedImage)
        }
    }
    
    // MARK: - Helper Methods
    
    // Convert CVPixelBuffer to UIImage
    private func convertCapturedImageToUIImage(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
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
