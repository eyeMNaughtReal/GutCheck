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
    @Published var detailedNutrition: [String: Double] = [:]
    
    // Food item created from scan
    @Published var scannedFoodItem: FoodItem?
    
    // Configure camera
    func checkCameraPermission() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        print("🎥 Camera permission status: \(authStatus.rawValue)")
        
        switch authStatus {
        case .authorized:
            print("🎥 Camera already authorized")
            self.isAuthorized = true
            self.setupCameraSession()
        case .notDetermined:
            print("🎥 Camera permission not determined, requesting access...")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                print("🎥 Camera permission request result: \(granted)")
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        print("🎥 Setting up camera session after permission granted")
                        self?.setupCameraSession()
                    } else {
                        print("🎥 Camera permission denied by user")
                    }
                }
            }
        case .denied:
            print("🎥 Camera permission denied")
            self.isAuthorized = false
        case .restricted:
            print("🎥 Camera permission restricted")
            self.isAuthorized = false
        @unknown default:
            print("🎥 Unknown camera permission status")
            self.isAuthorized = false
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func setupCameraSession() {
        print("🎥 Setting up camera session...")
        
        // Initialize camera session
        cameraSession.beginConfiguration()
        
        // Set up capture device
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("🎥 Failed to get capture device")
            DispatchQueue.main.async {
                self.cameraErrorMessage = "Camera not available. Please check device hardware or permissions."
                self.isAuthorized = false
            }
            return
        }
        
        print("🎥 Capture device obtained: \(captureDevice.localizedName)")
        self.captureDevice = captureDevice
        
        // Input
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("🎥 Failed to create device input")
            return
        }
        
        print("🎥 Device input created successfully")
        
        if cameraSession.canAddInput(deviceInput) {
            cameraSession.addInput(deviceInput)
            print("🎥 Device input added to session")
        } else {
            print("🎥 Cannot add device input to session")
            return
        }
        
        // Output
        let metadataOutput = AVCaptureMetadataOutput()
        
        if cameraSession.canAddOutput(metadataOutput) {
            cameraSession.addOutput(metadataOutput)
            print("🎥 Metadata output added to session")
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .upce, .code128, .code39, .code93, .qr]
            print("🎥 Metadata output configured with barcode types")
        } else {
            print("🎥 Cannot add metadata output to session")
            return
        }
        
        cameraSession.commitConfiguration()
        print("🎥 Camera session configuration committed successfully")
    }
    
    func startScanning() {
        print("🎥 Start scanning called. Authorized: \(isAuthorized)")
        guard isAuthorized else { 
            print("🎥 Not authorized to start scanning")
            return 
        }
        
        if !cameraSession.isRunning {
            print("🎥 Camera session not running, starting...")
            // Capture the session locally to avoid capturing self
            let session = cameraSession
            
            Task.detached {
                session.startRunning()
                print("🎥 Camera session started running")
                
                await MainActor.run { [weak self] in
                    self?.isScanning = true
                    print("🎥 isScanning set to true")
                }
            }
        } else {
            print("🎥 Camera session already running")
            isScanning = true
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
        print("🔍 Looking up barcode: \(barcode)")
        
        // Try real API first, fallback to mock data
        lookupProductFromAPI(barcode: barcode) { [weak self] success in
            DispatchQueue.main.async {
                if !success {
                    // Fallback to mock data if API fails
                    print("🔍 API lookup failed, using mock data")
                    self?.generateMockProduct(barcode: barcode)
                }
                self?.foundProduct = true
                self?.isLoading = false
            }
        }
    }
    
    private func lookupProductFromAPI(barcode: String, completion: @escaping (Bool) -> Void) {
        // Use Open Food Facts API (free food database)
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("🔍 API request failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? Int,
                   status == 1,
                   let product = json["product"] as? [String: Any] {
                    
                    DispatchQueue.main.async {
                        // Extract product information
                        let name = product["product_name"] as? String ?? "Unknown Product"
                        let brand = product["brands"] as? String ?? ""
                        let description = brand.isEmpty ? name : "\(brand) - \(name)"
                        
                        // Debug logging
                        print("🔍 Raw API response - product_name: '\(product["product_name"] ?? "nil")'")
                        print("🔍 Raw API response - brands: '\(product["brands"] ?? "nil")'")
                        print("🔍 Parsed name: '\(name)'")
                        print("🔍 Parsed brand: '\(brand)'")
                        print("🔍 Final description: '\(description)'")
                        
                        // Extract detailed nutrition per 100g
                        var calories = 100 // default
                        var protein = 0.0
                        var carbs = 0.0
                        var fat = 0.0
                        var fiber = 0.0
                        var sugar = 0.0
                        var sodium = 0.0
                        
                        if let nutriments = product["nutriments"] as? [String: Any] {
                            print("🔍 Available nutriments: \(nutriments.keys.sorted())")
                            
                            // Calories
                            if let energyKcal100g = nutriments["energy-kcal_100g"] as? Double {
                                calories = Int(energyKcal100g)
                                print("🔍 Got calories from API: \(calories)")
                            }
                            
                            // Protein
                            if let proteins100g = nutriments["proteins_100g"] as? Double {
                                protein = proteins100g
                                print("🔍 Got protein from API: \(protein)g")
                            }
                            
                            // Carbohydrates  
                            if let carbohydrates100g = nutriments["carbohydrates_100g"] as? Double {
                                carbs = carbohydrates100g
                                print("🔍 Got carbs from API: \(carbs)g")
                            }
                            
                            // Fat
                            if let fat100g = nutriments["fat_100g"] as? Double {
                                fat = fat100g
                                print("🔍 Got fat from API: \(fat)g")
                            }
                            
                            // Fiber
                            if let fiber100g = nutriments["fiber_100g"] as? Double {
                                fiber = fiber100g
                                print("🔍 Got fiber from API: \(fiber)g")
                            }
                            
                            // Sugar
                            if let sugars100g = nutriments["sugars_100g"] as? Double {
                                sugar = sugars100g
                                print("🔍 Got sugar from API: \(sugar)g")
                            }
                            
                            // Sodium (convert from mg to g)
                            if let sodium100g = nutriments["sodium_100g"] as? Double {
                                sodium = sodium100g / 1000.0 // Convert mg to g
                                print("🔍 Got sodium from API: \(sodium)g")
                            }
                        }
                        
                        self.productName = name
                        self.productDescription = description
                        self.productCalories = calories
                        
                        // Store detailed nutrition for food item creation
                        self.detailedNutrition = [
                            "protein": protein,
                            "carbs": carbs, 
                            "fat": fat,
                            "fiber": fiber,
                            "sugar": sugar,
                            "sodium": sodium
                        ]
                        
                        print("🔍 Set productName to: '\(self.productName)'")
                        print("🔍 Set productDescription to: '\(self.productDescription)'")
                        print("🔍 API product found: \(name) - \(description) - \(calories) kcal")
                        print("🔍 Nutrition: P:\(protein)g C:\(carbs)g F:\(fat)g Fiber:\(fiber)g")
                    }
                    completion(true)
                } else {
                    print("🔍 Product not found in API database")
                    completion(false)
                }
            } catch {
                print("🔍 JSON parsing error: \(error.localizedDescription)")
                completion(false)
            }
        }.resume()
    }
    
    private func generateMockProduct(barcode: String) {
        // Mock product data - showing actual barcode for debugging
        // In a real app, this would come from a database or API
        print("🔍 [MOCK] Looking up barcode: \(barcode)")
        
        // For now, create a generic product that shows the barcode
        productName = "Unknown Product"
        productDescription = "Barcode: \(barcode)"
        productCalories = 100
        detailedNutrition = [:] // Clear detailed nutrition for mock data
        
        print("🔍 [MOCK] Set generic productName to: '\(productName)'")
        print("🔍 [MOCK] Set generic productDescription to: '\(productDescription)'")
        
        // You can add specific barcodes for testing if you know them
        switch barcode {
        case "041220120000": // Example Duke's Mayo barcode (if you know it)
            productName = "Duke's Mayonnaise"
            productDescription = "Real mayonnaise"
            productCalories = 90
            detailedNutrition = [
                "protein": 0.1,
                "carbs": 0.6,
                "fat": 10.0,
                "fiber": 0.0,
                "sugar": 0.6,
                "sodium": 0.09
            ]
            print("🔍 [MOCK] Set Duke's Mayo productName to: '\(productName)'")
            print("🔍 [MOCK] Set Duke's Mayo productDescription to: '\(productDescription)'")
        case "072058500000": // Example gravy mix barcode
            productName = "Country Gravy Mix"
            productDescription = "Instant gravy mix"
            productCalories = 25
            detailedNutrition = [
                "protein": 1.0,
                "carbs": 4.0,
                "fat": 0.5,
                "fiber": 0.2,
                "sugar": 1.0,
                "sodium": 0.4
            ]
            print("🔍 [MOCK] Set gravy mix productName to: '\(productName)'")
            print("🔍 [MOCK] Set gravy mix productDescription to: '\(productDescription)'")
        default:
            // Keep the generic unknown product
            print("🔍 [MOCK] Using generic unknown product")
            break
        }
        
        print("🔍 [MOCK] Mock product generated: \(productName) - \(productDescription)")
    }
    
    // MARK: - Food Item Creation
    func createFoodItemFromScannedProduct() {
        // Use real nutrition data from API if available, otherwise calculate estimates
        let protein = detailedNutrition["protein"] ?? (Double(productCalories) * 0.1)
        let carbs = detailedNutrition["carbs"] ?? (Double(productCalories) * 0.5)  
        let fat = detailedNutrition["fat"] ?? (Double(productCalories) * 0.3)
        let fiber = detailedNutrition["fiber"] ?? 0.0
        let sugar = detailedNutrition["sugar"] ?? 0.0
        let sodium = detailedNutrition["sodium"] ?? 0.0
        
        print("🔍 Creating food item with nutrition:")
        print("🔍 - Calories: \(productCalories)")
        print("🔍 - Protein: \(protein)g \(detailedNutrition["protein"] != nil ? "(real)" : "(estimated)")")
        print("🔍 - Carbs: \(carbs)g \(detailedNutrition["carbs"] != nil ? "(real)" : "(estimated)")")
        print("🔍 - Fat: \(fat)g \(detailedNutrition["fat"] != nil ? "(real)" : "(estimated)")")
        print("🔍 - Fiber: \(fiber)g")
        print("🔍 - Sugar: \(sugar)g")
        print("🔍 - Sodium: \(sodium)g")
        
        // Create a FoodItem from the scanned product with real nutrition data
        let foodItem = FoodItem(
            id: UUID().uuidString,
            name: productName,
            quantity: "1 serving",
            estimatedWeightInGrams: 100,
            ingredients: [],
            allergens: [],
            nutrition: NutritionInfo(
                calories: productCalories,
                protein: protein,
                carbs: carbs,
                fat: fat
            ),
            source: .barcode,
            barcodeValue: scannedBarcode,
            isUserEdited: false,
            nutritionDetails: [
                "fiber": String(fiber),
                "sugar": String(sugar),
                "sodium": String(sodium)
            ]
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
