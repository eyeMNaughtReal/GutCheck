//
//  BarcodeScannerViewModel.swift
//  GutCheck
//
//  Created on 7/14/25.
//

import Foundation
import AVFoundation
import UIKit

@MainActor
class BarcodeScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    // Camera session - nonisolated because AVCaptureSession must be accessed from background threads
    nonisolated let cameraSession = AVCaptureSession()
    private var captureDevice: AVCaptureDevice?
    
    // Error handling
    enum CameraError: LocalizedError {
        case deviceNotAvailable
        case setupFailed
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .deviceNotAvailable:
                return "Camera is not available on this device"
            case .setupFailed:
                return "Failed to setup camera"
            case .permissionDenied:
                return "Camera access is denied"
            }
        }
    }
    
    // Scanner properties
    @Published var isScanning = false
    @Published var isAuthorized = false
    @Published var scannerLinePosition: CGFloat = -80  // Starting position

    // Error state for camera setup
    @Published var cameraErrorMessage: String? = nil
    
    // Flash state
    @Published var isFlashOn = false
    
    // Barcode results
    @Published var scannedBarcode = ""
    @Published var showingAlert = false
    
    // Product information
    @Published var isLoading = false
    @Published var foundProduct = false
    @Published var productName = ""
    @Published var productDescription = ""
    @Published var productCalories = 0
    
    // Food item created from scan
    @Published var scannedFoodItem: FoodItem?
    
    // Configure camera
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isAuthorized = true
            self.setupCameraSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupCameraSession()
                    }
                }
            }
        case .denied, .restricted:
            self.isAuthorized = false
        @unknown default:
            self.isAuthorized = false
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func setupCameraSession() {
        // Initialize camera session
        cameraSession.beginConfiguration()
        
        // Set up capture device
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            DispatchQueue.main.async {
                self.cameraErrorMessage = "Camera not available. Please check device hardware or permissions."
                self.isAuthorized = false
            }
            print("Failed to get capture device")
            return
        }
        self.captureDevice = captureDevice
        
        // Input
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Failed to create device input")
            return
        }
        
        if cameraSession.canAddInput(deviceInput) {
            cameraSession.addInput(deviceInput)
        }
        
        // Output
        let metadataOutput = AVCaptureMetadataOutput()
        
        if cameraSession.canAddOutput(metadataOutput) {
            cameraSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .upce, .code128, .code39, .code93, .qr]
        }
        
        cameraSession.commitConfiguration()
    }
    
    func startScanning() {
        guard isAuthorized else { return }
        
        if !cameraSession.isRunning {
            // Capture the session locally to avoid capturing self
            let session = cameraSession
            
            Task.detached {
                session.startRunning()
                
                await MainActor.run { [weak self] in
                    self?.isScanning = true
                }
            }
        }
    }
    
    func stopScanning() {
        if cameraSession.isRunning {
            cameraSession.stopRunning()
            isScanning = false
        }
    }
    
    func toggleFlash() {
        guard let device = captureDevice, device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.torchMode == .off {
                device.torchMode = .on
                isFlashOn = true
            } else {
                device.torchMode = .off
                isFlashOn = false
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error toggling flash: \(error)")
        }
    }
    
    // MARK: - Barcode Detection
    
    // Nonisolated delegate method to satisfy protocol requirement
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Process only the first detected barcode
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcodeValue = metadataObject.stringValue else { return }
        
        Task { @MainActor in
            // Only process if we don't already have a barcode or if it's a different one
            if scannedBarcode != barcodeValue {
                // Pause scanning temporarily
                stopScanning()
                if isAuthorized {
                    scannedBarcode = barcodeValue
                    // Simulate product lookup
                    lookupProduct(barcode: barcodeValue)
                }
            }
        }
    }
    
    // MARK: - Product Lookup
    private func lookupProduct(barcode: String) {
        isLoading = true
        // In a real app, we would use an API to look up the product
        // For now, we'll simulate with a delay and mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            // Simulate 80% chance of finding a product
            if Double.random(in: 0...1) < 0.8 {
                self.generateMockProduct(barcode: barcode)
                self.foundProduct = true
            } else {
                self.foundProduct = false
                self.showingAlert = true
            }
            self.isLoading = false
        }
    }
    
    private func generateMockProduct(barcode: String) {
        // Mock product data based on the barcode
        // In a real app, this would come from a database or API
        // Sample products
        let products: [(name: String, description: String, calories: Int)] = [
            ("Organic Greek Yogurt", "Plain, full-fat yogurt", 150),
            ("Nature Valley Granola Bar", "Oats 'n Honey flavor", 190),
            ("Coca-Cola Zero Sugar", "Zero-calorie soft drink", 0),
            ("Starbucks Cold Brew", "Black coffee, unsweetened", 5),
            ("Lay's Classic Potato Chips", "Original flavor", 160),
            ("Kind Bar", "Dark Chocolate Nuts & Sea Salt", 180),
            ("Chicken Breast", "Boneless, skinless", 120),
            ("Honey Nut Cheerios", "Whole grain breakfast cereal", 140),
            ("Peanut Butter", "Creamy natural peanut butter", 190),
            ("Halo Top Ice Cream", "Vanilla Bean, low-calorie", 280)
        ]
        // Pick a random product from the list
        let randomIndex = Int(barcode.hash) % products.count
        let randomProduct = products[abs(randomIndex)]
        // Update properties
        productName = randomProduct.name
        productDescription = randomProduct.description
        productCalories = randomProduct.calories
    }
    
    // MARK: - Food Item Creation
    func createFoodItemFromScannedProduct() {
        // Create a FoodItem from the scanned product - FIXED PARAMETER ORDER
        let foodItem = FoodItem(
            id: UUID().uuidString,
            name: productName,
            quantity: "1 serving",
            estimatedWeightInGrams: 100,
            ingredients: [],
            allergens: [],
            nutrition: NutritionInfo(
                calories: productCalories,
                protein: Double(productCalories) * 0.1,
                carbs: Double(productCalories) * 0.5,
                fat: Double(productCalories) * 0.3
            ),
            source: .barcode,
            barcodeValue: scannedBarcode,
            isUserEdited: false,
            nutritionDetails: [:]
        )
        // Show the food item detail view
        scannedFoodItem = foodItem
    }
    
    func clearScannedProduct() {
        // Clear the current product
        foundProduct = false
        scannedBarcode = ""
        productName = ""
        productDescription = ""
        // Resume scanning
        startScanning()
    }
    
    func addToMeal(_ foodItem: FoodItem) {
        // Add to meal builder
        MealBuilder.shared.addFoodItem(foodItem)
    }
}
