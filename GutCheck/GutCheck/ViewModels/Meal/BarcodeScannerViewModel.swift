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
    @Published var foundProduct = false {
        didSet {
            Swift.print("📦 BarcodeScannerViewModel: foundProduct changed from \(oldValue) to \(foundProduct)")
        }
    }
    @Published var productName = ""
    @Published var productDescription = ""
    @Published var productCalories = 0
    @Published var detailedNutrition: [String: Double] = [:]
    @Published var productIngredients: [String] = []
    @Published var productAllergens: [String] = []
    @Published var productAdditives: [String] = []
    
    // Temporary storage for comparing data sources
    private var openFoodFactsData: ProductData?
    private var nutritionixData: ProductData?
    
    // Food item created from scan
    @Published var scannedFoodItem: FoodItem?
    
    // MARK: - Data Structures for API Comparison
    
    private struct ProductData {
        let name: String
        let description: String
        let calories: Int
        let detailedNutrition: [String: Double]
        let ingredients: [String]
        let allergens: [String]
        let additives: [String]
        let source: String
        
        var nutritionCount: Int {
            return detailedNutrition.count
        }
        
        var hasIngredients: Bool {
            return !ingredients.isEmpty
        }
        
        var hasAdditives: Bool {
            return !additives.isEmpty
        }
        
        var dataQualityScore: Int {
            var score = 0
            score += nutritionCount // Each nutrition field adds 1 point
            score += hasIngredients ? 10 : 0 // Ingredients are valuable
            score += hasAdditives ? 5 : 0 // Additives are valuable
            score += !allergens.isEmpty ? 5 : 0 // Allergens are valuable
            return score
        }
    }
    
    // Configure camera - now uses centralized PermissionManager
    func checkCameraPermission() {
        let permissionManager = PermissionManager.shared
        
        // Update from centralized permission status
        self.isAuthorized = permissionManager.cameraStatus.isGranted
        
        if permissionManager.cameraStatus.isGranted {
            Swift.print("🎥 Camera already authorized via PermissionManager")
            self.setupCameraSession()
        } else if permissionManager.cameraStatus.needsRequest {
            Swift.print("🎥 Camera permission not determined, will be handled by UI")
            self.isAuthorized = false
        } else {
            Swift.print("🎥 Camera permission denied or restricted")
            self.isAuthorized = false
        }
    }
    
    // Request permission through centralized system
    func requestCameraPermission() async -> Bool {
        let permissionManager = PermissionManager.shared
        let granted = await permissionManager.requestCameraPermission()
        
        await MainActor.run {
            self.isAuthorized = granted
            if granted {
                self.setupCameraSession()
            }
        }
        
        return granted
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
        Swift.print("📷 BarcodeScannerViewModel: metadata output received, objects count: \(metadataObjects.count)")
        
        // Process only the first detected barcode
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcodeValue = metadataObject.stringValue else { 
            Swift.print("📷 BarcodeScannerViewModel: no valid barcode detected")
            return 
        }
        
        Swift.print("📷 BarcodeScannerViewModel: detected barcode: \(barcodeValue)")
        
        Task { @MainActor in
            // Only process if we don't already have a barcode or if it's a different one
            if scannedBarcode != barcodeValue {
                Swift.print("📷 BarcodeScannerViewModel: processing new barcode: \(barcodeValue)")
                // Pause scanning temporarily
                stopScanning()
                if isAuthorized {
                    scannedBarcode = barcodeValue
                    // Simulate product lookup
                    lookupProduct(barcode: barcodeValue)
                } else {
                    Swift.print("📷 BarcodeScannerViewModel: not authorized for scanning")
                }
            } else {
                Swift.print("📷 BarcodeScannerViewModel: ignoring duplicate barcode: \(barcodeValue)")
            }
        }
    }
    
    // MARK: - Product Lookup
    private func lookupProduct(barcode: String) {
        isLoading = true
        Swift.print("🔍 Looking up barcode: \(barcode)")
        
        // Clear previous comparison data
        openFoodFactsData = nil
        nutritionixData = nil
        
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
        // Try OpenFoodFacts API first for comprehensive data including ingredients and additives
        lookupFromOpenFoodFacts(barcode: barcode) { [weak self] openFoodFactsSuccess in
            if openFoodFactsSuccess {
                Swift.print("🔍 OpenFoodFacts API lookup successful")
                
                // Also try Nutritionix to compare and potentially enhance the data
                self?.lookupFromNutritionix(barcode: barcode) { [weak self] nutritionixSuccess in
                    if nutritionixSuccess {
                        Swift.print("🔍 Both APIs successful - comparing data quality")
                        self?.chooseBestDataSource()
                    }
                    completion(true) // We have at least OpenFoodFacts data
                }
            } else {
                Swift.print("🔍 OpenFoodFacts API failed, trying Nutritionix")
                self?.lookupFromNutritionix(barcode: barcode, completion: completion)
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
        request.setValue(NutritionixSecrets.appId, forHTTPHeaderField: "x-app-id")
        request.setValue(NutritionixSecrets.apiKey, forHTTPHeaderField: "x-app-key")
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
                        
                        // Store comprehensive detailed nutrition
                        let detailedNutrition = [
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
                        
                        // Store Nutritionix data for comparison
                        self.nutritionixData = ProductData(
                            name: name,
                            description: description,
                            calories: calories,
                            detailedNutrition: detailedNutrition,
                            ingredients: [], // Nutritionix doesn't provide ingredients via barcode
                            allergens: [], // Nutritionix doesn't provide allergens via barcode
                            additives: [], // Nutritionix doesn't provide additives
                            source: "Nutritionix"
                        )
                        
                        // If no OpenFoodFacts data, use Nutritionix immediately
                        if self.openFoodFactsData == nil {
                            self.applyProductData(self.nutritionixData!)
                        }
                        
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
                        
                        // Extract ingredients
                        var ingredients: [String] = []
                        if let ingredientsText = product["ingredients_text"] as? String, !ingredientsText.isEmpty {
                            ingredients = self.parseOpenFoodFactsIngredients(ingredientsText)
                            Swift.print("🔍 Open Food Facts ingredients: \(ingredients)")
                        }
                        
                        // Extract allergens
                        var allergens: [String] = []
                        if let allergensText = product["allergens"] as? String, !allergensText.isEmpty {
                            allergens = self.parseOpenFoodFactsAllergens(allergensText)
                            Swift.print("🔍 Open Food Facts allergens: \(allergens)")
                        }
                        
                        // Extract additives
                        var additives: [String] = []
                        if let additivesTags = product["additives_tags"] as? [String] {
                            additives = self.parseOpenFoodFactsAdditives(additivesTags)
                            Swift.print("🔍 Open Food Facts additives: \(additives)")
                        }
                        
                        // Extract detailed nutrition per 100g
                        var calories = 100 // default
                        var protein = 0.0
                        var carbs = 0.0
                        var fat = 0.0
                        var fiber = 0.0
                        var sugar = 0.0
                        var sodium = 0.0
                        
                        // Additional nutrition for comprehensive data
                        var saturatedFat = 0.0
                        var vitaminC = 0.0
                        var calcium = 0.0
                        var iron = 0.0
                        var cholesterol = 0.0
                        var potassium = 0.0
                        var vitaminA = 0.0
                        var vitaminD = 0.0
                        var vitaminE = 0.0
                        var vitaminK = 0.0
                        var vitaminB1 = 0.0
                        var vitaminB2 = 0.0
                        var vitaminB3 = 0.0
                        var vitaminB6 = 0.0
                        var vitaminB12 = 0.0
                        var folate = 0.0
                        var magnesium = 0.0
                        var phosphorus = 0.0
                        var zinc = 0.0
                        
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
                            
                            // Saturated Fat
                            if let saturatedFat100g = nutriments["saturated-fat_100g"] as? Double {
                                saturatedFat = saturatedFat100g
                            }
                            
                            // Vitamin C
                            if let vitaminC100g = nutriments["vitamin-c_100g"] as? Double {
                                vitaminC = vitaminC100g
                            }
                            
                            // Calcium
                            if let calcium100g = nutriments["calcium_100g"] as? Double {
                                calcium = calcium100g
                            }
                            
                            // Iron
                            if let iron100g = nutriments["iron_100g"] as? Double {
                                iron = iron100g
                            }
                            
                            // Cholesterol
                            if let cholesterol100g = nutriments["cholesterol_100g"] as? Double {
                                cholesterol = cholesterol100g
                            }
                            
                            // Potassium
                            if let potassium100g = nutriments["potassium_100g"] as? Double {
                                potassium = potassium100g
                            }
                            
                            // Vitamin A
                            if let vitaminA100g = nutriments["vitamin-a_100g"] as? Double {
                                vitaminA = vitaminA100g
                            }
                            
                            // Vitamin D
                            if let vitaminD100g = nutriments["vitamin-d_100g"] as? Double {
                                vitaminD = vitaminD100g
                            }
                            
                            // Vitamin E
                            if let vitaminE100g = nutriments["vitamin-e_100g"] as? Double {
                                vitaminE = vitaminE100g
                            }
                            
                            // Vitamin K
                            if let vitaminK100g = nutriments["vitamin-k_100g"] as? Double {
                                vitaminK = vitaminK100g
                            }
                            
                            // B Vitamins
                            if let vitaminB1100g = nutriments["vitamin-b1_100g"] as? Double {
                                vitaminB1 = vitaminB1100g
                            }
                            
                            if let vitaminB2100g = nutriments["vitamin-b2_100g"] as? Double {
                                vitaminB2 = vitaminB2100g
                            }
                            
                            if let vitaminB3100g = nutriments["vitamin-b3_100g"] as? Double {
                                vitaminB3 = vitaminB3100g
                            }
                            
                            if let vitaminB6100g = nutriments["vitamin-b6_100g"] as? Double {
                                vitaminB6 = vitaminB6100g
                            }
                            
                            if let vitaminB12100g = nutriments["vitamin-b12_100g"] as? Double {
                                vitaminB12 = vitaminB12100g
                            }
                            
                            // Folate
                            if let folate100g = nutriments["folate_100g"] as? Double {
                                folate = folate100g
                            }
                            
                            // Minerals
                            if let magnesium100g = nutriments["magnesium_100g"] as? Double {
                                magnesium = magnesium100g
                            }
                            
                            if let phosphorus100g = nutriments["phosphorus_100g"] as? Double {
                                phosphorus = phosphorus100g
                            }
                            
                            if let zinc100g = nutriments["zinc_100g"] as? Double {
                                zinc = zinc100g
                            }
                        }
                        
                        // Store detailed nutrition for comparison
                        let detailedNutrition = [
                            "protein": protein,
                            "carbs": carbs, 
                            "fat": fat,
                            "fiber": fiber,
                            "sugar": sugar,
                            "sodium": sodium,
                            "saturatedFat": saturatedFat,
                            "vitamin_c": vitaminC,
                            "calcium": calcium,
                            "iron": iron,
                            "cholesterol": cholesterol,
                            "potassium": potassium,
                            "vitaminA": vitaminA,
                            "vitaminD": vitaminD,
                            "vitaminE": vitaminE,
                            "vitaminK": vitaminK,
                            "vitaminB1": vitaminB1,
                            "vitaminB2": vitaminB2,
                            "vitaminB3": vitaminB3,
                            "vitaminB6": vitaminB6,
                            "vitaminB12": vitaminB12,
                            "folate": folate,
                            "magnesium": magnesium,
                            "phosphorus": phosphorus,
                            "zinc": zinc
                        ]
                        
                        // Store OpenFoodFacts data for comparison
                        self.openFoodFactsData = ProductData(
                            name: name,
                            description: description,
                            calories: calories,
                            detailedNutrition: detailedNutrition,
                            ingredients: ingredients,
                            allergens: allergens,
                            additives: additives,
                            source: "OpenFoodFacts"
                        )
                        
                        // Apply OpenFoodFacts data immediately (can be overridden if Nutritionix is better)
                        self.applyProductData(self.openFoodFactsData!)
                        
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
    
    // MARK: - Data Source Comparison
    
    private func chooseBestDataSource() {
        guard let openFoodFactsData = openFoodFactsData,
              let nutritionixData = nutritionixData else {
            return
        }
        
        let openFoodFactsScore = openFoodFactsData.dataQualityScore
        let nutritionixScore = nutritionixData.dataQualityScore
        
        Swift.print("🔍 Data Quality Comparison:")
        Swift.print("🔍 - OpenFoodFacts score: \(openFoodFactsScore) (nutrition: \(openFoodFactsData.nutritionCount), ingredients: \(openFoodFactsData.hasIngredients), additives: \(openFoodFactsData.hasAdditives))")
        Swift.print("🔍 - Nutritionix score: \(nutritionixScore) (nutrition: \(nutritionixData.nutritionCount), ingredients: \(nutritionixData.hasIngredients), additives: \(nutritionixData.hasAdditives))")
        
        let bestData = openFoodFactsScore >= nutritionixScore ? openFoodFactsData : nutritionixData
        
        // If switching to Nutritionix, but we want to keep OpenFoodFacts ingredients/additives
        if bestData.source == "Nutritionix" && openFoodFactsData.hasIngredients {
            Swift.print("🔍 Using Nutritionix nutrition data but keeping OpenFoodFacts ingredients/additives")
            applyHybridData(nutritionData: nutritionixData, ingredientData: openFoodFactsData)
        } else {
            Swift.print("🔍 Using \(bestData.source) as primary data source")
            applyProductData(bestData)
        }
        
        // Clear temporary data
        self.openFoodFactsData = nil
        self.nutritionixData = nil
    }
    
    private func applyProductData(_ data: ProductData) {
        self.productName = data.name
        self.productDescription = data.description
        self.productCalories = data.calories
        self.detailedNutrition = data.detailedNutrition
        self.productIngredients = data.ingredients
        self.productAllergens = data.allergens
        self.productAdditives = data.additives
    }
    
    private func applyHybridData(nutritionData: ProductData, ingredientData: ProductData) {
        self.productName = nutritionData.name
        self.productDescription = nutritionData.description
        self.productCalories = nutritionData.calories
        self.detailedNutrition = nutritionData.detailedNutrition
        self.productIngredients = ingredientData.ingredients
        self.productAllergens = ingredientData.allergens
        self.productAdditives = ingredientData.additives
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
        let vitaminC = detailedNutrition["vitaminC"] ?? detailedNutrition["vitamin_c"] ?? 0.0
        let vitaminD = detailedNutrition["vitaminD"] ?? 0.0
        let vitaminE = detailedNutrition["vitaminE"] ?? 0.0
        let vitaminK = detailedNutrition["vitaminK"] ?? 0.0
        let vitaminB1 = detailedNutrition["vitaminB1"] ?? 0.0
        let vitaminB2 = detailedNutrition["vitaminB2"] ?? 0.0
        let vitaminB3 = detailedNutrition["vitaminB3"] ?? 0.0
        let vitaminB6 = detailedNutrition["vitaminB6"] ?? 0.0
        let vitaminB12 = detailedNutrition["vitaminB12"] ?? 0.0
        let folate = detailedNutrition["folate"] ?? 0.0
        let magnesium = detailedNutrition["magnesium"] ?? 0.0
        let phosphorus = detailedNutrition["phosphorus"] ?? 0.0
        let zinc = detailedNutrition["zinc"] ?? 0.0
        
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
        Swift.print("🔍 - Vitamin A: \(vitaminA)IU")
        Swift.print("🔍 - Vitamin D: \(vitaminD)mcg")
        Swift.print("🔍 - Vitamin E: \(vitaminE)mg")
        Swift.print("🔍 - Magnesium: \(magnesium)mg")
        Swift.print("🔍 - Phosphorus: \(phosphorus)mg")
        Swift.print("🔍 - Zinc: \(zinc)mg")
        
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
        
        // Add additives information for compound analysis - Grouped by Type
        if !productAdditives.isEmpty {
            nutritionDetails["additives"] = productAdditives.joined(separator: ", ")
            nutritionDetails["additives_count"] = "\(productAdditives.count)"
            
            // Group additives by type for better organization
            let groupedAdditives = groupAdditivesByType(productAdditives)
            for (type, additives) in groupedAdditives {
                nutritionDetails["additives_\(type.lowercased())"] = additives.joined(separator: ", ")
            }
        }
        
        // Add ingredients information - Grouped by Category  
        if !productIngredients.isEmpty {
            nutritionDetails["ingredients"] = productIngredients.joined(separator: ", ")
            nutritionDetails["ingredients_count"] = "\(productIngredients.count)"
            
            // Group ingredients by food category for better analysis
            let groupedIngredients = groupIngredientsByCategory(productIngredients)
            for (category, ingredients) in groupedIngredients {
                nutritionDetails["ingredients_\(category.lowercased())"] = ingredients.joined(separator: ", ")
            }
        }
        
        // Add allergen information - Grouped by Severity
        if !productAllergens.isEmpty {
            nutritionDetails["allergens"] = productAllergens.joined(separator: ", ")
            nutritionDetails["allergens_count"] = "\(productAllergens.count)"
            
            // Group allergens by severity level
            let groupedAllergens = groupAllergensBySeverity(productAllergens)
            for (severity, allergens) in groupedAllergens {
                nutritionDetails["allergens_\(severity.lowercased())"] = allergens.joined(separator: ", ")
            }
        }
        
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
        if vitaminD > 0 {
            nutritionDetails["vitamin_d"] = String(format: "%.1f", vitaminD)
        }
        if vitaminE > 0 {
            nutritionDetails["vitamin_e"] = String(format: "%.1f", vitaminE)
        }
        if vitaminK > 0 {
            nutritionDetails["vitamin_k"] = String(format: "%.1f", vitaminK)
        }
        if vitaminB1 > 0 {
            nutritionDetails["vitamin_b1"] = String(format: "%.1f", vitaminB1)
        }
        if vitaminB2 > 0 {
            nutritionDetails["vitamin_b2"] = String(format: "%.1f", vitaminB2)
        }
        if vitaminB3 > 0 {
            nutritionDetails["vitamin_b3"] = String(format: "%.1f", vitaminB3)
        }
        if vitaminB6 > 0 {
            nutritionDetails["vitamin_b6"] = String(format: "%.1f", vitaminB6)
        }
        if vitaminB12 > 0 {
            nutritionDetails["vitamin_b12"] = String(format: "%.1f", vitaminB12)
        }
        if folate > 0 {
            nutritionDetails["folate"] = String(format: "%.1f", folate)
        }
        if magnesium > 0 {
            nutritionDetails["magnesium"] = String(format: "%.1f", magnesium)
        }
        if phosphorus > 0 {
            nutritionDetails["phosphorus"] = String(format: "%.1f", phosphorus)
        }
        if zinc > 0 {
            nutritionDetails["zinc"] = String(format: "%.1f", zinc)
        }
        
        // Add grouped health summary to nutrition details
        let healthSummary = getGroupedHealthSummary()
        if let additivesByType = healthSummary["additives_by_type"] as? [String: [String]] {
            for (type, additivesList) in additivesByType {
                nutritionDetails["health_additives_\(type.lowercased())"] = additivesList.joined(separator: ", ")
            }
        }
        if let ingredientsByCategory = healthSummary["ingredients_by_category"] as? [String: [String]] {
            for (category, ingredientsList) in ingredientsByCategory {
                nutritionDetails["health_ingredients_\(category.lowercased())"] = ingredientsList.joined(separator: ", ")
            }
        }
        if let allergensBySeverity = healthSummary["allergens_by_severity"] as? [String: [String]] {
            for (severity, allergensList) in allergensBySeverity {
                nutritionDetails["health_allergens_\(severity.lowercased())"] = allergensList.joined(separator: ", ")
            }
        }
        if let riskScore = healthSummary["allergen_risk_score"] as? Int {
            nutritionDetails["health_risk_score"] = "\(riskScore)"
        }
        
        // Create a FoodItem from the scanned product with comprehensive nutrition data
        let foodItem = FoodItem(
            id: UUID().uuidString,
            name: productName,
            quantity: "1 serving (as labeled)",
            estimatedWeightInGrams: 100,
            ingredients: productIngredients,
            allergens: productAllergens, // Keep allergens separate from additives
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
        // Add to unified meal builder service
        MealBuilderService.shared.addFoodItem(foodItem)
    }
    
    // MARK: - Open Food Facts Parsing Functions
    
    private func parseOpenFoodFactsIngredients(_ ingredientsText: String) -> [String] {
        // Open Food Facts ingredients are usually comma-separated
        // Clean up the text and split
        let cleanedText = ingredientsText
            .replacingOccurrences(of: "_", with: "") // Remove underscores
            .replacingOccurrences(of: ".", with: "") // Remove periods at end
            .replacingOccurrences(of: ":", with: ",") // Replace colons with commas
            .replacingOccurrences(of: ";", with: ",") // Replace semicolons with commas
            .replacingOccurrences(of: " and ", with: ", ") // Handle "and" separators
            .replacingOccurrences(of: " & ", with: ", ") // Handle "&" separators
        
        // Split by commas and clean each ingredient
        let ingredients = cleanedText
            .components(separatedBy: ",")
            .map { ingredient in
                ingredient
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                    // Remove percentages and parenthetical info
                    .replacingOccurrences(of: #"\s*\([^)]*\)"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"\s*\d+%"#, with: "", options: .regularExpression)
            }
            .filter { !$0.isEmpty && $0.count > 1 } // Filter out empty and single-character strings
        
        return ingredients
    }
    
    private func parseOpenFoodFactsAllergens(_ allergensText: String) -> [String] {
        // Open Food Facts allergens are usually prefixed with "en:" and separated by commas
        let allergens = allergensText
            .components(separatedBy: ",")
            .compactMap { allergen -> String? in
                let cleaned = allergen
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "en:", with: "") // Remove language prefix
                    .replacingOccurrences(of: "_", with: " ") // Replace underscores with spaces
                    .capitalized
                
                // Map to common allergen names
                switch cleaned.lowercased() {
                case "milk":
                    return "Dairy"
                case "gluten":
                    return "Gluten"
                case "eggs":
                    return "Eggs"
                case "nuts", "tree nuts":
                    return "Tree Nuts"
                case "peanuts":
                    return "Peanuts"
                case "soy", "soybeans":
                    return "Soy"
                case "fish":
                    return "Fish"
                case "shellfish", "crustaceans":
                    return "Shellfish"
                case "sesame":
                    return "Sesame"
                default:
                    return cleaned.isEmpty ? nil : cleaned
                }
            }
            .filter { !$0.isEmpty }
        
        return allergens
    }
    
    private func parseOpenFoodFactsAdditives(_ additivesTags: [String]) -> [String] {
        // Open Food Facts additives are prefixed with "en:" and use E-numbers or chemical names
        let additives = additivesTags
            .compactMap { additive -> String? in
                let cleaned = additive
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "en:", with: "") // Remove language prefix
                    .replacingOccurrences(of: "_", with: " ") // Replace underscores with spaces
                    .capitalized
                
                // Skip if empty or too short
                guard !cleaned.isEmpty && cleaned.count > 1 else { return nil }
                
                // Map common additives to more readable names
                switch cleaned.lowercased() {
                case let additive where additive.contains("e100"):
                    return "Curcumin (E100)"
                case let additive where additive.contains("e101"):
                    return "Riboflavin (E101)"
                case let additive where additive.contains("e102"):
                    return "Tartrazine (E102)"
                case let additive where additive.contains("e200"):
                    return "Sorbic Acid (E200)"
                case let additive where additive.contains("e202"):
                    return "Potassium Sorbate (E202)"
                case let additive where additive.contains("e211"):
                    return "Sodium Benzoate (E211)"
                case let additive where additive.contains("e220"):
                    return "Sulfur Dioxide (E220)"
                case let additive where additive.contains("e250"):
                    return "Sodium Nitrite (E250)"
                case let additive where additive.contains("e300"):
                    return "Ascorbic Acid (E300)"
                case let additive where additive.contains("e330"):
                    return "Citric Acid (E330)"
                case let additive where additive.contains("e621"):
                    return "Monosodium Glutamate (E621)"
                case "monosodium glutamate", "msg":
                    return "Monosodium Glutamate (E621)"
                case "citric acid":
                    return "Citric Acid (E330)"
                case "ascorbic acid":
                    return "Ascorbic Acid (E300)"
                case "sodium benzoate":
                    return "Sodium Benzoate (E211)"
                case "potassium sorbate":
                    return "Potassium Sorbate (E202)"
                default:
                    // Return the cleaned name if no specific mapping
                    return cleaned
                }
            }
            .filter { !$0.isEmpty }
        
        return additives
    }
    
    // MARK: - Health Indicator Grouping Methods
    
    private func groupAdditivesByType(_ additives: [String]) -> [String: [String]] {
        var grouped: [String: [String]] = [
            "Preservatives": [],
            "Colorings": [],
            "Flavor_Enhancers": [],
            "Sweeteners": [],
            "Emulsifiers": [],
            "Other": []
        ]
        
        for additive in additives {
            let lowerAdditive = additive.lowercased()
            
            if lowerAdditive.contains("sodium benzoate") || lowerAdditive.contains("potassium sorbate") ||
               lowerAdditive.contains("citric acid") || lowerAdditive.contains("ascorbic acid") ||
               lowerAdditive.contains("e200") || lowerAdditive.contains("e211") || 
               lowerAdditive.contains("e220") || lowerAdditive.contains("e300") {
                grouped["Preservatives"]?.append(additive)
            }
            else if lowerAdditive.contains("tartrazine") || lowerAdditive.contains("e102") ||
                    lowerAdditive.contains("e100") || lowerAdditive.contains("e101") ||
                    lowerAdditive.contains("yellow") || lowerAdditive.contains("red") {
                grouped["Colorings"]?.append(additive)
            }
            else if lowerAdditive.contains("msg") || lowerAdditive.contains("monosodium glutamate") ||
                    lowerAdditive.contains("e621") || lowerAdditive.contains("glutamate") {
                grouped["Flavor_Enhancers"]?.append(additive)
            }
            else if lowerAdditive.contains("aspartame") || lowerAdditive.contains("sucralose") ||
                    lowerAdditive.contains("stevia") || lowerAdditive.contains("acesulfame") {
                grouped["Sweeteners"]?.append(additive)
            }
            else if lowerAdditive.contains("lecithin") || lowerAdditive.contains("polysorbate") ||
                    lowerAdditive.contains("mono") || lowerAdditive.contains("diglyceride") {
                grouped["Emulsifiers"]?.append(additive)
            }
            else {
                grouped["Other"]?.append(additive)
            }
        }
        
        // Remove empty categories
        return grouped.filter { !$0.value.isEmpty }
    }
    
    private func groupIngredientsByCategory(_ ingredients: [String]) -> [String: [String]] {
        var grouped: [String: [String]] = [
            "Grains": [],
            "Proteins": [],
            "Dairy": [],
            "Vegetables": [],
            "Fruits": [],
            "Fats_Oils": [],
            "Spices": [],
            "Other": []
        ]
        
        for ingredient in ingredients {
            let lowerIngredient = ingredient.lowercased()
            
            if lowerIngredient.contains("wheat") || lowerIngredient.contains("flour") ||
               lowerIngredient.contains("rice") || lowerIngredient.contains("oat") ||
               lowerIngredient.contains("barley") || lowerIngredient.contains("corn") {
                grouped["Grains"]?.append(ingredient)
            }
            else if lowerIngredient.contains("chicken") || lowerIngredient.contains("beef") ||
                    lowerIngredient.contains("pork") || lowerIngredient.contains("fish") ||
                    lowerIngredient.contains("egg") || lowerIngredient.contains("protein") {
                grouped["Proteins"]?.append(ingredient)
            }
            else if lowerIngredient.contains("milk") || lowerIngredient.contains("cheese") ||
                    lowerIngredient.contains("butter") || lowerIngredient.contains("cream") ||
                    lowerIngredient.contains("yogurt") || lowerIngredient.contains("whey") {
                grouped["Dairy"]?.append(ingredient)
            }
            else if lowerIngredient.contains("tomato") || lowerIngredient.contains("onion") ||
                    lowerIngredient.contains("carrot") || lowerIngredient.contains("pepper") ||
                    lowerIngredient.contains("celery") || lowerIngredient.contains("lettuce") {
                grouped["Vegetables"]?.append(ingredient)
            }
            else if lowerIngredient.contains("apple") || lowerIngredient.contains("orange") ||
                    lowerIngredient.contains("lemon") || lowerIngredient.contains("berry") ||
                    lowerIngredient.contains("grape") || lowerIngredient.contains("fruit") {
                grouped["Fruits"]?.append(ingredient)
            }
            else if lowerIngredient.contains("oil") || lowerIngredient.contains("fat") ||
                    lowerIngredient.contains("butter") || lowerIngredient.contains("margarine") {
                grouped["Fats_Oils"]?.append(ingredient)
            }
            else if lowerIngredient.contains("salt") || lowerIngredient.contains("pepper") ||
                    lowerIngredient.contains("garlic") || lowerIngredient.contains("herb") ||
                    lowerIngredient.contains("spice") || lowerIngredient.contains("cumin") {
                grouped["Spices"]?.append(ingredient)
            }
            else {
                grouped["Other"]?.append(ingredient)
            }
        }
        
        // Remove empty categories
        return grouped.filter { !$0.value.isEmpty }
    }
    
    private func groupAllergensBySeverity(_ allergens: [String]) -> [String: [String]] {
        var grouped: [String: [String]] = [
            "Major": [],
            "Common": [],
            "Mild": []
        ]
        
        for allergen in allergens {
            let lowerAllergen = allergen.lowercased()
            
            // Major allergens - FDA's Big 8 + 1
            if lowerAllergen.contains("peanut") || lowerAllergen.contains("shellfish") ||
               lowerAllergen.contains("tree nut") || lowerAllergen.contains("milk") ||
               lowerAllergen.contains("egg") || lowerAllergen.contains("wheat") ||
               lowerAllergen.contains("soy") || lowerAllergen.contains("fish") ||
               lowerAllergen.contains("sesame") {
                grouped["Major"]?.append(allergen)
            }
            // Common allergens
            else if lowerAllergen.contains("gluten") || lowerAllergen.contains("dairy") ||
                    lowerAllergen.contains("lactose") || lowerAllergen.contains("corn") {
                grouped["Common"]?.append(allergen)
            }
            // Mild allergens or intolerances
            else {
                grouped["Mild"]?.append(allergen)
            }
        }
        
        // Remove empty categories
        return grouped.filter { !$0.value.isEmpty }
    }
    
    /// Generate a health summary with grouped indicators for UI display
    func getGroupedHealthSummary() -> [String: Any] {
        var summary: [String: Any] = [:]
        
        // Additives grouping
        if !productAdditives.isEmpty {
            let groupedAdditives = groupAdditivesByType(productAdditives)
            summary["additives_by_type"] = groupedAdditives
            summary["additives_total"] = productAdditives.count
            summary["additives_types_count"] = groupedAdditives.count
        }
        
        // Ingredients grouping
        if !productIngredients.isEmpty {
            let groupedIngredients = groupIngredientsByCategory(productIngredients)
            summary["ingredients_by_category"] = groupedIngredients
            summary["ingredients_total"] = productIngredients.count
            summary["ingredients_categories_count"] = groupedIngredients.count
        }
        
        // Allergens grouping
        if !productAllergens.isEmpty {
            let groupedAllergens = groupAllergensBySeverity(productAllergens)
            summary["allergens_by_severity"] = groupedAllergens
            summary["allergens_total"] = productAllergens.count
            
            // Calculate risk score based on allergen severity
            var riskScore = 0
            if let majorAllergens = groupedAllergens["Major"] {
                riskScore += majorAllergens.count * 3
            }
            if let commonAllergens = groupedAllergens["Common"] {
                riskScore += commonAllergens.count * 2
            }
            if let mildAllergens = groupedAllergens["Mild"] {
                riskScore += mildAllergens.count * 1
            }
            summary["allergen_risk_score"] = riskScore
        }
        
        // Overall health summary
        summary["product_name"] = productName
        summary["product_description"] = productDescription
        summary["calories"] = productCalories
        summary["barcode"] = scannedBarcode
        summary["analysis_timestamp"] = Date().timeIntervalSince1970
        
        Swift.print("🏥 Generated grouped health summary:")
        Swift.print("🏥 - Additives: \(productAdditives.count) total in \(groupAdditivesByType(productAdditives).count) categories")
        Swift.print("🏥 - Ingredients: \(productIngredients.count) total in \(groupIngredientsByCategory(productIngredients).count) categories")
        Swift.print("🏥 - Allergens: \(productAllergens.count) total with risk score: \(summary["allergen_risk_score"] ?? 0)")
        
        // Print detailed grouping for debugging
        printDetailedGrouping()
        
        return summary
    }
    
    /// Print detailed grouping information for debugging
    private func printDetailedGrouping() {
        Swift.print("📊 DETAILED HEALTH GROUPING ANALYSIS:")
        
        // Additives grouping details
        if !productAdditives.isEmpty {
            Swift.print("📊 ADDITIVES BY TYPE:")
            let groupedAdditives = groupAdditivesByType(productAdditives)
            for (type, additives) in groupedAdditives.sorted(by: { $0.key < $1.key }) {
                Swift.print("📊   \(type): \(additives.joined(separator: ", "))")
            }
        }
        
        // Ingredients grouping details
        if !productIngredients.isEmpty {
            Swift.print("📊 INGREDIENTS BY CATEGORY:")
            let groupedIngredients = groupIngredientsByCategory(productIngredients)
            for (category, ingredients) in groupedIngredients.sorted(by: { $0.key < $1.key }) {
                Swift.print("📊   \(category): \(ingredients.joined(separator: ", "))")
            }
        }
        
        // Allergens grouping details
        if !productAllergens.isEmpty {
            Swift.print("📊 ALLERGENS BY SEVERITY:")
            let groupedAllergens = groupAllergensBySeverity(productAllergens)
            for (severity, allergens) in groupedAllergens.sorted(by: { $0.key < $1.key }) {
                Swift.print("📊   \(severity) Risk: \(allergens.joined(separator: ", "))")
            }
        }
        
        Swift.print("📊 END GROUPING ANALYSIS")
    }
    
    /// Get a user-friendly grouped summary for display
    func getUserFriendlyGroupedSummary() -> [String: [String: [String]]] {
        var friendlySummary: [String: [String: [String]]] = [:]
        
        // Group additives
        if !productAdditives.isEmpty {
            friendlySummary["additives"] = groupAdditivesByType(productAdditives)
        }
        
        // Group ingredients  
        if !productIngredients.isEmpty {
            friendlySummary["ingredients"] = groupIngredientsByCategory(productIngredients)
        }
        
        // Group allergens
        if !productAllergens.isEmpty {
            friendlySummary["allergens"] = groupAllergensBySeverity(productAllergens)
        }
        
        return friendlySummary
    }
}
