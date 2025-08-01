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
        Swift.print("🎥 Camera permission status: \(authStatus.rawValue)")
        
        switch authStatus {
        case .authorized:
            Swift.print("🎥 Camera already authorized")
            self.isAuthorized = true
            self.setupCameraSession()
        case .notDetermined:
            Swift.print("🎥 Camera permission not determined, requesting access...")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Swift.print("🎥 Camera permission request result: \(granted)")
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        Swift.print("🎥 Setting up camera session after permission granted")
                        self?.setupCameraSession()
                    } else {
                        Swift.print("🎥 Camera permission denied by user")
                    }
                }
            }
        case .denied:
            Swift.print("🎥 Camera permission denied")
            self.isAuthorized = false
        case .restricted:
            Swift.print("🎥 Camera permission restricted")
            self.isAuthorized = false
        @unknown default:
            Swift.print("🎥 Unknown camera permission status")
            self.isAuthorized = false
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func setupCameraSession() {
        Swift.print("🎥 Setting up camera session...")
        
        // Initialize camera session
        cameraSession.beginConfiguration()
        
        // Set up capture device
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            Swift.print("🎥 Failed to get capture device")
            DispatchQueue.main.async {
                self.cameraErrorMessage = "Camera not available. Please check device hardware or permissions."
                self.isAuthorized = false
            }
            return
        }
        
        Swift.print("🎥 Capture device obtained: \(captureDevice.localizedName)")
        self.captureDevice = captureDevice
        
        // Input
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            Swift.print("🎥 Failed to create device input")
            return
        }
        
        Swift.print("🎥 Device input created successfully")
        
        if cameraSession.canAddInput(deviceInput) {
            cameraSession.addInput(deviceInput)
            Swift.print("🎥 Device input added to session")
        } else {
            Swift.print("🎥 Cannot add device input to session")
            return
        }
        
        // Output
        let metadataOutput = AVCaptureMetadataOutput()
        
        if cameraSession.canAddOutput(metadataOutput) {
            cameraSession.addOutput(metadataOutput)
            Swift.print("🎥 Metadata output added to session")
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .upce, .code128, .code39, .code93, .qr]
            Swift.print("🎥 Metadata output configured with barcode types")
        } else {
            Swift.print("🎥 Cannot add metadata output to session")
            return
        }
        
        cameraSession.commitConfiguration()
        Swift.print("🎥 Camera session configuration committed successfully")
    }
    
    func startScanning() {
        Swift.print("🎥 Start scanning called. Authorized: \(isAuthorized)")
        guard isAuthorized else { 
            Swift.print("🎥 Not authorized to start scanning")
            return 
        }
        
        if !cameraSession.isRunning {
            Swift.print("🎥 Camera session not running, starting...")
            // Capture the session locally to avoid capturing self
            let session = cameraSession
            
            Task.detached {
                session.startRunning()
                Swift.print("🎥 Camera session started running")
                
                await MainActor.run { [weak self] in
                    self?.isScanning = true
                    Swift.print("🎥 isScanning set to true")
                }
            }
        } else {
            Swift.print("🎥 Camera session already running")
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
            Swift.print("Error toggling flash: \(error)")
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
        Swift.print("🔍 Looking up barcode: \(barcode)")
        
        // Try real API first, fallback to mock data
        lookupProductFromAPI(barcode: barcode) { [weak self] success in
            DispatchQueue.main.async {
                if !success {
                    // Fallback to mock data if API fails
                    Swift.print("🔍 API lookup failed, using mock data")
                    self?.generateMockProduct(for: barcode)
                }
                self?.foundProduct = true
                self?.isLoading = false
            }
        }
    }
    
    private func lookupProductFromAPI(barcode: String, completion: @escaping (Bool) -> Void) {
        // Try Nutritionix API first for more comprehensive nutrition data
        lookupFromNutritionix(barcode: barcode) { [weak self] success in
            if success {
                Swift.print("🔍 Nutritionix API lookup successful")
                completion(true)
            } else {
                Swift.print("🔍 Nutritionix API failed, trying Open Food Facts")
                self?.lookupFromOpenFoodFacts(barcode: barcode, completion: completion)
            }
        }
    }
    
    private func lookupFromNutritionix(barcode: String, completion: @escaping (Bool) -> Void) {
        // Use Nutritionix API for comprehensive nutrition data
        let urlString = "https://trackapi.nutritionix.com/v2/search/item"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("0f4298bb", forHTTPHeaderField: "x-app-id")
        request.setValue("239f65a9165bbaa7be71fd1d7f040973", forHTTPHeaderField: "x-app-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add UPC parameter
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.queryItems = [URLQueryItem(name: "upc", value: barcode)]
            if let finalURL = components.url {
                request.url = finalURL
            }
        }
        
        Swift.print("🔍 Nutritionix barcode lookup for: \(barcode)")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                Swift.print("🔍 Nutritionix API request failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                Swift.print("🔍 Nutritionix API response status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    Swift.print("🔍 Nutritionix API returned non-200 status")
                    completion(false)
                    return
                }
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let foods = json["foods"] as? [[String: Any]],
                   let firstFood = foods.first {
                    
                    Swift.print("🔍 Nutritionix API found product")
                    
                    DispatchQueue.main.async {
                        // Extract product information
                        let name = firstFood["food_name"] as? String ?? "Unknown Product"
                        let brand = firstFood["brand_name"] as? String ?? ""
                        let description = brand.isEmpty ? name : "\(brand) - \(name)"
                        
                        // Extract comprehensive nutrition data
                        let calories = Int(firstFood["nf_calories"] as? Double ?? 0)
                        let protein = firstFood["nf_protein"] as? Double ?? 0.0
                        let carbs = firstFood["nf_total_carbohydrate"] as? Double ?? 0.0
                        let fat = firstFood["nf_total_fat"] as? Double ?? 0.0
                        let fiber = firstFood["nf_dietary_fiber"] as? Double ?? 0.0
                        let sugar = firstFood["nf_sugars"] as? Double ?? 0.0
                        let sodium = (firstFood["nf_sodium"] as? Double ?? 0.0) / 1000.0 // Convert mg to g
                        
                        // Additional nutrition data
                        let saturatedFat = firstFood["nf_saturated_fat"] as? Double ?? 0.0
                        let cholesterol = firstFood["nf_cholesterol"] as? Double ?? 0.0
                        let potassium = firstFood["nf_potassium"] as? Double ?? 0.0
                        let calcium = firstFood["nf_calcium"] as? Double ?? 0.0
                        let iron = firstFood["nf_iron"] as? Double ?? 0.0
                        let vitaminA = firstFood["nf_vitamin_a_iu"] as? Double ?? 0.0
                        let vitaminC = firstFood["nf_vitamin_c"] as? Double ?? 0.0
                        
                        Swift.print("🔍 Nutritionix nutrition data:")
                        Swift.print("🔍 - Calories: \(calories)")
                        Swift.print("🔍 - Protein: \(protein)g")
                        Swift.print("🔍 - Carbs: \(carbs)g")
                        Swift.print("🔍 - Fat: \(fat)g")
                        Swift.print("🔍 - Fiber: \(fiber)g")
                        Swift.print("🔍 - Sugar: \(sugar)g")
                        Swift.print("🔍 - Sodium: \(sodium)g")
                        
                        self.productName = name
                        self.productDescription = description
                        self.productCalories = calories
                        
                        // Store comprehensive detailed nutrition
                        self.detailedNutrition = [
                            "protein": protein,
                            "carbs": carbs,
                            "fat": fat,
                            "fiber": fiber,
                            "sugar": sugar,
                            "sodium": sodium,
                            "saturatedFat": saturatedFat,
                            "cholesterol": cholesterol,
                            "potassium": potassium,
                            "calcium": calcium,
                            "iron": iron,
                            "vitaminA": vitaminA,
                            "vitaminC": vitaminC
                        ]
                        
                        Swift.print("🔍 Nutritionix product found: \(name) - \(description) - \(calories) kcal")
                    }
                    completion(true)
                } else {
                    Swift.print("🔍 Nutritionix: Product not found or invalid response")
                    completion(false)
                }
            } catch {
                Swift.print("🔍 Nutritionix JSON parsing error: \(error.localizedDescription)")
                completion(false)
            }
        }.resume()
    }
    
    private func lookupFromOpenFoodFacts(barcode: String, completion: @escaping (Bool) -> Void) {
        // Fallback to Open Food Facts API
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                Swift.print("🔍 Open Food Facts API request failed: \(error?.localizedDescription ?? "Unknown error")")
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
                        
                        // Extract detailed nutrition per 100g
                        var calories = 100 // default
                        var protein = 0.0
                        var carbs = 0.0
                        var fat = 0.0
                        var fiber = 0.0
                        var sugar = 0.0
                        var sodium = 0.0
                        
                        if let nutriments = product["nutriments"] as? [String: Any] {
                            Swift.print("🔍 Open Food Facts available nutriments: \(nutriments.keys.sorted())")
                            
                            // Calories
                            if let energyKcal100g = nutriments["energy-kcal_100g"] as? Double {
                                calories = Int(energyKcal100g)
                                Swift.print("🔍 Got calories from Open Food Facts: \(calories)")
                            }
                            
                            // Protein
                            if let proteins100g = nutriments["proteins_100g"] as? Double {
                                protein = proteins100g
                            }
                            
                            // Carbohydrates  
                            if let carbohydrates100g = nutriments["carbohydrates_100g"] as? Double {
                                carbs = carbohydrates100g
                            }
                            
                            // Fat
                            if let fat100g = nutriments["fat_100g"] as? Double {
                                fat = fat100g
                            }
                            
                            // Fiber
                            if let fiber100g = nutriments["fiber_100g"] as? Double {
                                fiber = fiber100g
                            }
                            
                            // Sugar
                            if let sugars100g = nutriments["sugars_100g"] as? Double {
                                sugar = sugars100g
                            }
                            
                            // Sodium (convert from mg to g)
                            if let sodium100g = nutriments["sodium_100g"] as? Double {
                                sodium = sodium100g / 1000.0 // Convert mg to g
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
                        
                        Swift.print("🔍 Open Food Facts product found: \(name) - \(description) - \(calories) kcal")
                        Swift.print("🔍 Open Food Facts nutrition: P:\(protein)g C:\(carbs)g F:\(fat)g Fiber:\(fiber)g")
                    }
                    completion(true)
                } else {
                    Swift.print("🔍 Open Food Facts: Product not found in database")
                    completion(false)
                }
            } catch {
                Swift.print("🔍 Open Food Facts JSON parsing error: \(error.localizedDescription)")
                completion(false)
            }
        }.resume()
    }
    
    private func generateMockProduct(for barcode: String) {
        // Mock product data - showing actual barcode for debugging
        // In a real app, this would come from a database or API
        Swift.print("🔍 [MOCK] Looking up barcode: \(barcode)")
        
        // For now, create a generic product that shows the barcode
        productName = "Unknown Product"
        productDescription = "Barcode: \(barcode)"
        productCalories = 100
        detailedNutrition = [:] // Clear detailed nutrition for mock data
        
        Swift.print("🔍 [MOCK] Set generic productName to: '\(productName)'")
        Swift.print("🔍 [MOCK] Set generic productDescription to: '\(productDescription)'")
        
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
            Swift.print("🔍 [MOCK] Set Duke's Mayo productName to: '\(productName)'")
            Swift.print("🔍 [MOCK] Set Duke's Mayo productDescription to: '\(productDescription)'")
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
            Swift.print("🔍 [MOCK] Set gravy mix productName to: '\(productName)'")
            Swift.print("🔍 [MOCK] Set gravy mix productDescription to: '\(productDescription)'")
        default:
            // Keep the generic unknown product
            Swift.print("🔍 [MOCK] Using generic unknown product")
            break
        }
        
        Swift.print("🔍 [MOCK] Mock product generated: \(productName) - \(productDescription)")
    }
    
    // MARK: - Food Item Creation
    func createFoodItemFromScannedProduct() {
        // Use comprehensive nutrition data from Nutritionix if available, otherwise fallback to estimates
        let protein = detailedNutrition["protein"] ?? (Double(productCalories) * 0.1)
        let carbs = detailedNutrition["carbs"] ?? (Double(productCalories) * 0.5)  
        let fat = detailedNutrition["fat"] ?? (Double(productCalories) * 0.3)
        let fiber = detailedNutrition["fiber"] ?? 0.0
        let sugar = detailedNutrition["sugar"] ?? 0.0
        let sodium = detailedNutrition["sodium"] ?? 0.0
        
        // Additional nutrition data from Nutritionix
        let saturatedFat = detailedNutrition["saturatedFat"] ?? 0.0
        let cholesterol = detailedNutrition["cholesterol"] ?? 0.0
        let potassium = detailedNutrition["potassium"] ?? 0.0
        let calcium = detailedNutrition["calcium"] ?? 0.0
        let iron = detailedNutrition["iron"] ?? 0.0
        let vitaminA = detailedNutrition["vitaminA"] ?? 0.0
        let vitaminC = detailedNutrition["vitaminC"] ?? 0.0
        
        Swift.print("🔍 Creating food item with comprehensive nutrition:")
        Swift.print("🔍 - Calories: \(productCalories)")
        Swift.print("🔍 - Protein: \(protein)g \(detailedNutrition["protein"] != nil ? "(real)" : "(estimated)")")
        Swift.print("🔍 - Carbs: \(carbs)g \(detailedNutrition["carbs"] != nil ? "(real)" : "(estimated)")")
        Swift.print("🔍 - Fat: \(fat)g \(detailedNutrition["fat"] != nil ? "(real)" : "(estimated)")")
        Swift.print("🔍 - Fiber: \(fiber)g")
        Swift.print("🔍 - Sugar: \(sugar)g")
        Swift.print("🔍 - Sodium: \(sodium)g")
        Swift.print("🔍 - Saturated Fat: \(saturatedFat)g")
        Swift.print("🔍 - Cholesterol: \(cholesterol)mg")
        Swift.print("🔍 - Potassium: \(potassium)mg")
        Swift.print("🔍 - Calcium: \(calcium)mg")
        Swift.print("🔍 - Iron: \(iron)mg")
        Swift.print("🔍 - Vitamin C: \(vitaminC)mg")
        
        // Create comprehensive nutrition details dictionary
        var nutritionDetails: [String: String] = [
            "protein": String(format: "%.1f", protein),
            "carbs": String(format: "%.1f", carbs),
            "fat": String(format: "%.1f", fat),
            "fiber": String(format: "%.1f", fiber),
            "sugar": String(format: "%.1f", sugar),
            "sodium": String(format: "%.1f", sodium * 1000), // Convert to mg
            "source": "nutritionix_barcode",
            "barcode": scannedBarcode
        ]
        
        // Add additional nutrition data if available
        if saturatedFat > 0 {
            nutritionDetails["saturated_fat"] = String(format: "%.1f", saturatedFat)
        }
        if cholesterol > 0 {
            nutritionDetails["cholesterol"] = String(format: "%.1f", cholesterol)
        }
        if potassium > 0 {
            nutritionDetails["potassium"] = String(format: "%.1f", potassium)
        }
        if calcium > 0 {
            nutritionDetails["calcium"] = String(format: "%.1f", calcium)
        }
        if iron > 0 {
            nutritionDetails["iron"] = String(format: "%.1f", iron)
        }
        if vitaminA > 0 {
            nutritionDetails["vitamin_a"] = String(format: "%.1f", vitaminA)
        }
        if vitaminC > 0 {
            nutritionDetails["vitamin_c"] = String(format: "%.1f", vitaminC)
        }
        
        // Create a FoodItem from the scanned product with comprehensive nutrition data
        let foodItem = FoodItem(
            id: UUID().uuidString,
            name: productName,
            quantity: "1 serving (as labeled)",
            estimatedWeightInGrams: 100,
            ingredients: [],
            allergens: [],
            nutrition: NutritionInfo(
                calories: productCalories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                sugar: sugar,
                sodium: sodium * 1000 // Convert from g to mg for display
            ),
            source: .barcode,
            barcodeValue: scannedBarcode,
            isUserEdited: false,
            nutritionDetails: nutritionDetails
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
