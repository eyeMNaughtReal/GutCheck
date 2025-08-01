//
//  SmartFoodScannerView.swift
//  GutCheck
//
//  Enhanced food scanner that combines barcode + LiDAR for optimal accuracy
//

import SwiftUI

struct SmartFoodScannerView: View {
    @StateObject private var barcodeViewModel = BarcodeScannerViewModel()
    @StateObject private var lidarViewModel = LiDARScannerViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: ScanStep = .barcode
    @State private var showingMealBuilder = false
    @State private var showingSearchFallback = false
    @State private var finalFoodItem: FoodItem?
    
    enum ScanStep {
        case barcode
        case lidarEnhancement
        case searchFallback
        case results
        
        var title: String {
            switch self {
            case .barcode: return "Scan Barcode"
            case .lidarEnhancement: return "Estimate Portion"
            case .searchFallback: return "Search Food"
            case .results: return "Review & Add"
            }
        }
        
        var instructions: String {
            switch self {
            case .barcode: return "Point camera at product barcode for exact nutrition data"
            case .lidarEnhancement: return "Use LiDAR to measure your actual portion size"
            case .searchFallback: return "Search for your food manually"
            case .results: return "Review your food item and add to meal"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                ColorTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    progressHeader
                    
                    // Main content area
                    GeometryReader { geometry in
                        TabView(selection: $currentStep) {
                            // Step 1: Barcode Scanner
                            barcodeStep
                                .tag(ScanStep.barcode)
                            
                            // Step 2: LiDAR Enhancement (optional)
                            lidarEnhancementStep
                                .tag(ScanStep.lidarEnhancement)
                            
                            // Step 3: Search Fallback
                            searchFallbackStep
                                .tag(ScanStep.searchFallback)
                            
                            // Step 4: Results
                            resultsStep
                                .tag(ScanStep.results)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .disabled(true) // Prevent manual swiping
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            barcodeViewModel.checkCameraPermission()
        }
        .sheet(isPresented: $showingMealBuilder) {
            MealBuilderView()
        }
        .sheet(isPresented: $showingSearchFallback) {
            FoodSearchView()
        }
    }
    
    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Close button and title
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(ColorTheme.primaryText)
                        .padding(12)
                        .background(Circle().fill(ColorTheme.surface))
                }
                
                Spacer()
                
                VStack {
                    Text(currentStep.title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(ColorTheme.primaryText)
                    Text(currentStep.instructions)
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Help button
                Button(action: {}) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(ColorTheme.secondaryText)
                        .padding(12)
                }
            }
            .padding(.horizontal)
            
            // Progress steps
            HStack(spacing: 12) {
                ForEach([ScanStep.barcode, .lidarEnhancement, .searchFallback, .results], id: \.self) { step in
                    progressStepIndicator(step: step)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 8)
        .background(ColorTheme.background)
    }
    
    private func progressStepIndicator(step: ScanStep) -> some View {
        let isCompleted = stepIndex(step) < stepIndex(currentStep)
        let isCurrent = step == currentStep
        
        return HStack(spacing: 8) {
            Circle()
                .fill(isCompleted ? Color.green : (isCurrent ? ColorTheme.accent : ColorTheme.surface))
                .frame(width: 24, height: 24)
                .overlay(
                    Group {
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(stepIndex(step) + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(isCurrent ? .white : ColorTheme.secondaryText)
                        }
                    }
                )
            
            if step != .results {
                Rectangle()
                    .fill(isCompleted ? Color.green : ColorTheme.surface)
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func stepIndex(_ step: ScanStep) -> Int {
        switch step {
        case .barcode: return 0
        case .lidarEnhancement: return 1
        case .searchFallback: return 2
        case .results: return 3
        }
    }
    
    // MARK: - Step Views
    private var barcodeStep: some View {
        VStack(spacing: 20) {
            if barcodeViewModel.isAuthorized {
                // Camera preview with barcode scanning
                ZStack {
                    CameraPreviewView(cameraSession: barcodeViewModel.cameraSession)
                        .frame(height: 400)
                        .cornerRadius(16)
                        .onAppear {
                            barcodeViewModel.startScanning()
                        }
                    
                    // Scanning overlay
                    barcodeOverlay
                }
                
                // Results or controls
                if barcodeViewModel.foundProduct {
                    barcodeResultsView
                } else {
                    barcodeControlsView
                }
            } else {
                cameraPermissionView
            }
        }
        .padding()
    }
    
    private var barcodeOverlay: some View {
        ZStack {
            // Semi-transparent overlay
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .frame(width: 280, height: 180)
                        .blendMode(.destinationOut)
                )
            
            // Scanning frame
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorTheme.accent, lineWidth: 3)
                .frame(width: 280, height: 180)
                .overlay(
                    VStack {
                        Spacer()
                        Text("Align barcode within frame")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                    }
                    .padding(.bottom, -30)
                )
            
            // Scan animation
            if barcodeViewModel.isScanning {
                Rectangle()
                    .fill(ColorTheme.accent.opacity(0.5))
                    .frame(width: 280, height: 2)
                    .offset(y: barcodeViewModel.scannerLinePosition)
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                        value: barcodeViewModel.scannerLinePosition
                    )
                    .onAppear {
                        barcodeViewModel.scannerLinePosition = 80
                    }
                    .frame(width: 280, height: 180)
            }
        }
    }
    
    private var barcodeResultsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Product Found!")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color.green)
                Spacer()
                Button("Rescan") {
                    barcodeViewModel.clearScannedProduct()
                }
                .font(.subheadline)
                .foregroundColor(ColorTheme.accent)
            }
            
            HStack(alignment: .top, spacing: 16) {
                // Product image placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(ColorTheme.accent.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(ColorTheme.accent)
                    )
                
                // Product details
                VStack(alignment: .leading, spacing: 4) {
                    Text(barcodeViewModel.productName)
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text(barcodeViewModel.productDescription)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                        .lineLimit(2)
                    
                    Text("Per 100g: \(barcodeViewModel.productCalories) kcal")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                }
            }
            .padding()
            .background(ColorTheme.surface)
            .cornerRadius(12)
            
            VStack(spacing: 12) {
                Button("Enhance with LiDAR Portion Size") {
                    proceedToLiDAREnhancement()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.accent)
                .cornerRadius(12)
                
                Button("Use Standard Serving Size") {
                    createFoodFromBarcode(useStandardServing: true)
                }
                .font(.subheadline)
                .foregroundColor(ColorTheme.primary)
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(16)
    }
    
    private var barcodeControlsView: some View {
        VStack(spacing: 16) {
            if barcodeViewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Looking up product...")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    Text("Point camera at the product barcode")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    Button("Can't find barcode? Search instead") {
                        proceedToSearchFallback()
                    }
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.accent)
                }
                .padding()
            }
        }
        .background(ColorTheme.surface)
        .cornerRadius(16)
    }
    
    private var cameraPermissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.metering.none")
                .font(.system(size: 72))
                .foregroundColor(ColorTheme.secondaryText)
            
            Text("Camera Access Needed")
                .font(.title2.bold())
                .foregroundColor(ColorTheme.primaryText)
            
            Text("We need camera access to scan barcodes and estimate portions.")
                .multilineTextAlignment(.center)
                .foregroundColor(ColorTheme.secondaryText)
            
            Button("Enable Camera Access") {
                barcodeViewModel.openSettings()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(ColorTheme.primary)
            .cornerRadius(12)
        }
        .padding()
    }
    
    private var lidarEnhancementStep: some View {
        VStack(spacing: 20) {
            Text("Great! Now let's measure your actual portion")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
                .multilineTextAlignment(.center)
            
            Text("We found the nutrition data from the barcode. Now use LiDAR to estimate how much you're actually eating.")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Embedded LiDAR scanner
            if lidarViewModel.isDeviceSupported {
                LiDARPortionEstimatorView(viewModel: lidarViewModel) { estimatedWeight in
                    createFoodFromBarcodeWithLiDAR(estimatedWeight: estimatedWeight)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.metering.matrix")
                        .font(.system(size: 48))
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Text("LiDAR not available on this device")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("We'll use the standard serving size from the barcode.")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    Button("Continue with Standard Size") {
                        createFoodFromBarcode(useStandardServing: true)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(ColorTheme.accent)
                    .cornerRadius(12)
                }
                .padding()
            }
            
            Button("Skip - Use Standard Serving") {
                createFoodFromBarcode(useStandardServing: true)
            }
            .font(.subheadline)
            .foregroundColor(ColorTheme.secondaryText)
        }
        .padding()
    }
    
    private var searchFallbackStep: some View {
        VStack(spacing: 20) {
            Text("No barcode found")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            Text("Let's search for your food manually")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
            
            Button("Open Food Search") {
                showingSearchFallback = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(ColorTheme.accent)
            .cornerRadius(12)
            
            Button("Try LiDAR Only") {
                proceedToLiDAROnly()
            }
            .font(.subheadline)
            .foregroundColor(ColorTheme.primary)
        }
        .padding()
    }
    
    private var resultsStep: some View {
        VStack(spacing: 20) {
            if let foodItem = finalFoodItem {
                FoodItemPreviewCard(foodItem: foodItem)
                
                VStack(spacing: 12) {
                    Button("Add to Meal") {
                        addToMeal(foodItem)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.accent)
                    .cornerRadius(12)
                    
                    Button("Edit Details") {
                        // TODO: Show edit view
                    }
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primary)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    private func proceedToLiDAREnhancement() {
        currentStep = .lidarEnhancement
        lidarViewModel.checkDeviceCapabilities()
        lidarViewModel.startARSession()
    }
    
    private func proceedToSearchFallback() {
        currentStep = .searchFallback
    }
    
    private func proceedToLiDAROnly() {
        // Switch to standalone LiDAR mode
        dismiss()
        // Parent view should handle showing LiDAR scanner
    }
    
    private func createFoodFromBarcode(useStandardServing: Bool) {
        let nutrition = NutritionInfo(
            calories: barcodeViewModel.productCalories,
            protein: barcodeViewModel.detailedNutrition["protein"],
            carbs: barcodeViewModel.detailedNutrition["carbs"],
            fat: barcodeViewModel.detailedNutrition["fat"],
            fiber: barcodeViewModel.detailedNutrition["fiber"],
            sugar: barcodeViewModel.detailedNutrition["sugar"],
            sodium: barcodeViewModel.detailedNutrition["sodium"]
        )
        
        finalFoodItem = FoodItem(
            name: barcodeViewModel.productName,
            quantity: "100g (standard serving)",
            estimatedWeightInGrams: 100.0,
            nutrition: nutrition,
            source: .barcode,
            barcodeValue: barcodeViewModel.scannedBarcode
        )
        
        currentStep = .results
    }
    
    private func createFoodFromBarcodeWithLiDAR(estimatedWeight: Double) {
        let portionMultiplier = estimatedWeight / 100.0 // Barcode data is per 100g
        
        let adjustedNutrition = NutritionInfo(
            calories: Int(Double(barcodeViewModel.productCalories) * portionMultiplier),
            protein: barcodeViewModel.detailedNutrition["protein"].map { $0 * portionMultiplier },
            carbs: barcodeViewModel.detailedNutrition["carbs"].map { $0 * portionMultiplier },
            fat: barcodeViewModel.detailedNutrition["fat"].map { $0 * portionMultiplier },
            fiber: barcodeViewModel.detailedNutrition["fiber"].map { $0 * portionMultiplier },
            sugar: barcodeViewModel.detailedNutrition["sugar"].map { $0 * portionMultiplier },
            sodium: barcodeViewModel.detailedNutrition["sodium"].map { $0 * portionMultiplier }
        )
        
        finalFoodItem = FoodItem(
            name: barcodeViewModel.productName,
            quantity: "\(Int(estimatedWeight))g (LiDAR measured)",
            estimatedWeightInGrams: estimatedWeight,
            nutrition: adjustedNutrition,
            source: .barcode,
            barcodeValue: barcodeViewModel.scannedBarcode
        )
        
        currentStep = .results
    }
    
    private func addToMeal(_ foodItem: FoodItem) {
        MealBuilder.shared.addFoodItem(foodItem)
        showingMealBuilder = true
    }
}

// MARK: - Supporting Views

struct LiDARPortionEstimatorView: View {
    @ObservedObject var viewModel: LiDARScannerViewModel
    let onComplete: (Double) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Mini AR view
            ARViewContainer(session: viewModel.arSession, delegate: viewModel)
                .frame(height: 300)
                .cornerRadius(16)
                .overlay(
                    VStack {
                        Spacer()
                        if viewModel.scanStage == .scanning {
                            Text(viewModel.scanInstructions)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                                .padding(.bottom, 8)
                        }
                    }
                )
            
            // Progress and confidence
            if viewModel.confidenceLevel > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("Measurement Confidence")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(Int(viewModel.confidenceLevel * 100))%")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(confidenceColor(viewModel.confidenceLevel))
                    }
                    
                    ProgressView(value: viewModel.confidenceLevel)
                        .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor(viewModel.confidenceLevel)))
                }
                .padding()
                .background(ColorTheme.surface)
                .cornerRadius(8)
            }
            
            // Controls
            if viewModel.scanStage == .results {
                Button("Use This Measurement (\(Int(viewModel.estimatedWeight))g)") {
                    onComplete(viewModel.estimatedWeight)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.accent)
                .cornerRadius(12)
            } else if viewModel.scanStage == .initial {
                Button("Start LiDAR Scan") {
                    viewModel.startScanning()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.accent)
                .cornerRadius(12)
            }
        }
    }
    
    private func confidenceColor(_ confidence: Float) -> Color {
        if confidence >= 0.7 { return Color.green }
        else if confidence >= 0.4 { return Color.orange }
        else { return Color.red }
    }
}

struct FoodItemPreviewCard: View {
    let foodItem: FoodItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(foodItem.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text(foodItem.quantity)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    if let source = sourceDescription {
                        Text(source)
                            .font(.caption)
                            .foregroundColor(ColorTheme.accent)
                    }
                }
                
                Spacer()
                
                VStack {
                    Text("\(foodItem.nutrition.calories ?? 0)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(ColorTheme.primaryText)
                    Text("calories")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                }
            }
            
            // Nutrition breakdown
            HStack(spacing: 16) {
                nutritionPill("P", value: foodItem.nutrition.protein, unit: "g")
                nutritionPill("C", value: foodItem.nutrition.carbs, unit: "g")
                nutritionPill("F", value: foodItem.nutrition.fat, unit: "g")
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(16)
    }
    
    private var sourceDescription: String? {
        switch foodItem.source {
        case .barcode:
            if foodItem.quantity.contains("LiDAR") {
                return "📊 Barcode nutrition + 📏 LiDAR portion"
            } else {
                return "📊 Barcode nutrition"
            }
        case .lidar:
            return "📏 LiDAR estimated"
        case .manual:
            return "🔍 Manual entry"
        case .ai:
            return "🤖 AI recognized"
        }
    }
    
    private func nutritionPill(_ label: String, value: Double?, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundColor(ColorTheme.secondaryText)
            Text(value != nil ? String(format: "%.1f", value!) : "--")
                .font(.caption.weight(.medium))
                .foregroundColor(ColorTheme.primaryText)
            Text(unit)
                .font(.caption2)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(ColorTheme.background)
        .cornerRadius(8)
    }
}

// Preview
struct SmartFoodScannerView_Previews: PreviewProvider {
    static var previews: some View {
        SmartFoodScannerView()
    }
}
