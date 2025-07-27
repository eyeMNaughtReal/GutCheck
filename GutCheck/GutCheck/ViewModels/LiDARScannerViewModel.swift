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
        scanStage = .results
        isProcessing = false
        
        // Create mock detected objects
        detectedObjects = [
            DetectedObject(
                id: UUID(),
                name: "Apple",
                confidence: 0.85,
                estimatedVolume: 150.0,
                boundingBox: CGRect(x: 100, y: 100, width: 80, height: 80),
                foodInfo: FoodInfo(
                    name: "Apple",
                    estimatedWeight: 150.0,
                    calories: 78,
                    nutritionInfo: NutritionInfo(calories: 78, protein: 0.4, carbs: 20.6, fat: 0.3)
                )
            )
        ]
        
        // Mock food predictions
        foodPredictions = ["Apple", "Orange", "Banana"]
        detectedFoodName = "Apple"
        
        // Mock captured image
        capturedImage = createMockFoodImage()
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
    }
    
    func createFoodItemFromScan() {
        // Create a FoodItem from the current scan results
        // This should integrate with the meal logging system
        print("Creating food item from scan results")
        // TODO: Implement food item creation and navigation to meal builder
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