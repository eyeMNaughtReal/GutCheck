//
//  BarcodeScannerView.swift
//  GutCheck
//
//  Fixed to remove MealLoggingDestination references
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @StateObject private var viewModel = BarcodeScannerViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingMealBuilder = false
    
    // MARK: - Accessibility IDs
    private enum A11y {
        static let scannerView = "BarcodeScanner"
        static let closeButton = "CloseBarcodeScanner"
        static let flashButton = "ToggleFlash"
        static let settingsButton = "OpenSettings"
    }
    
    var body: some View {
        ZStack {
            // Camera preview
            if viewModel.isAuthorized {
                CameraPreviewView(cameraSession: viewModel.cameraSession)
                    .ignoresSafeArea()
                    .onAppear {
                        viewModel.startScanning()
                    }
                    .onDisappear {
                        viewModel.stopScanning()
                    }
                
                // Scanning overlay
                scanningOverlay
            } else {
                // Camera not authorized view
                VStack(spacing: 20) {
                    Image(systemName: "camera.metering.none")
                        .font(.system(size: 72))
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Text("Camera Access Needed")
                        .font(.title2.bold())
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("GutCheck needs camera access to scan barcodes.\nPlease enable camera access in Settings.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Button("Open Settings") {
                        viewModel.openSettings()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(ColorTheme.primary)
                    .cornerRadius(12)
                    .padding(.top, 8)
                }
                .padding()
                .background(ColorTheme.background.ignoresSafeArea())
            }
            
            // Bottom panel
            VStack {
                Spacer()
                
                scanResultsPanel
            }
            
            // Top bar
            VStack {
                ZStack {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.toggleFlash()
                        }) {
                            Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(.trailing, 16)
                    }
                    
                    Text("Scan Barcode")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.6)))
                }
                .padding(.top, 48)
                
                Spacer()
            }
        }
        .alert("Barcode Detected", isPresented: $viewModel.showingAlert) {
            Button("OK") { }
        } message: {
            Text("Barcode value: \(viewModel.scannedBarcode)")
        }
        .onAppear {
            viewModel.checkCameraPermission()
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .sheet(item: $viewModel.scannedFoodItem) { foodItem in
            EnhancedFoodItemDetailView(foodItem: foodItem) { updatedItem in
                viewModel.addToMeal(updatedItem)
                showingMealBuilder = true
            }
        }
        .sheet(isPresented: $showingMealBuilder) {
            MealBuilderView()
        }
    }
    
    // Helper function for nutrition items
    private func nutritionItem(_ label: String, value: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(ColorTheme.secondaryText)
            HStack {
                Text(String(format: "%.1f", value))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(ColorTheme.primaryText)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(ColorTheme.secondaryText)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(ColorTheme.background)
        .cornerRadius(6)
    }
    
    // Scanning overlay with targeting square
    private var scanningOverlay: some View {
        ZStack {
            // Semi-transparent dark overlay
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .ignoresSafeArea()
                .mask(
                    Rectangle()
                        .overlay(
                            // Cutout for scanning area
                            RoundedRectangle(cornerRadius: 16)
                                .frame(width: 280, height: 180)
                                .blendMode(.destinationOut)
                        )
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
            if viewModel.isScanning {
                Rectangle()
                    .fill(ColorTheme.accent.opacity(0.5))
                    .frame(width: 280, height: 2)
                    .offset(y: viewModel.scannerLinePosition)
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                        value: viewModel.scannerLinePosition
                    )
                    .onAppear {
                        viewModel.scannerLinePosition = 80
                    }
                    .frame(width: 280, height: 180)
            }
        }
    }
    
    // Bottom panel showing scan results or manual entry option
    private var scanResultsPanel: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                // Loading state
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("Looking up product...")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: ColorTheme.shadowColor, radius: 10, y: -5)
                
            } else if viewModel.foundProduct {
                // Product found
                VStack(spacing: 16) {
                    HStack {
                        Text("Product Found")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.clearScannedProduct()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ColorTheme.secondaryText)
                        }
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
                            Text(viewModel.productName)
                                .font(.headline)
                                .foregroundColor(ColorTheme.primaryText)
                            
                            Text(viewModel.productDescription)
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.secondaryText)
                                .lineLimit(2)
                            
                            Text("Per 100g: \(viewModel.productCalories) kcal")
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                    }
                    
                    // Detailed nutrition information
                    if !viewModel.detailedNutrition.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nutritional Information (per serving)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(ColorTheme.primaryText)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                // Primary macronutrients
                                if let protein = viewModel.detailedNutrition["protein"] {
                                    nutritionItem("Protein", value: protein, unit: "g")
                                }
                                if let carbs = viewModel.detailedNutrition["carbs"] {
                                    nutritionItem("Carbs", value: carbs, unit: "g")
                                }
                                if let fat = viewModel.detailedNutrition["fat"] {
                                    nutritionItem("Fat", value: fat, unit: "g")
                                }
                                
                                // Secondary nutrients
                                if let fiber = viewModel.detailedNutrition["fiber"] {
                                    nutritionItem("Fiber", value: fiber, unit: "g")
                                }
                                if let sugar = viewModel.detailedNutrition["sugar"] {
                                    nutritionItem("Sugar", value: sugar, unit: "g")
                                }
                                if let sodium = viewModel.detailedNutrition["sodium"] {
                                    nutritionItem("Sodium", value: sodium * 1000, unit: "mg")
                                }
                                
                                // Additional Nutritionix data (if available)
                                if let saturatedFat = viewModel.detailedNutrition["saturatedFat"], saturatedFat > 0 {
                                    nutritionItem("Sat Fat", value: saturatedFat, unit: "g")
                                }
                                if let cholesterol = viewModel.detailedNutrition["cholesterol"], cholesterol > 0 {
                                    nutritionItem("Cholesterol", value: cholesterol, unit: "mg")
                                }
                                if let potassium = viewModel.detailedNutrition["potassium"], potassium > 0 {
                                    nutritionItem("Potassium", value: potassium, unit: "mg")
                                }
                                if let calcium = viewModel.detailedNutrition["calcium"], calcium > 0 {
                                    nutritionItem("Calcium", value: calcium, unit: "mg")
                                }
                                if let iron = viewModel.detailedNutrition["iron"], iron > 0 {
                                    nutritionItem("Iron", value: iron, unit: "mg")
                                }
                                if let vitaminC = viewModel.detailedNutrition["vitaminC"], vitaminC > 0 {
                                    nutritionItem("Vitamin C", value: vitaminC, unit: "mg")
                                }
                            }
                            
                            // Data source indicator
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(ColorTheme.secondaryText)
                                    .font(.caption)
                                Text("Data from Nutritionix & Open Food Facts")
                                    .font(.caption2)
                                    .foregroundColor(ColorTheme.secondaryText)
                                Spacer()
                            }
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(ColorTheme.surface)
                        .cornerRadius(12)
                    }
                    
                    // Add to meal button
                    Button(action: {
                        viewModel.createFoodItemFromScannedProduct()
                    }) {
                        Text("Add to Meal")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.accent)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: ColorTheme.shadowColor, radius: 10, y: -5)
                
            } else {
                // Default state - scan instructions and manual option
                VStack(spacing: 16) {
                    Text("Scan a food barcode")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Position the barcode within the frame")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Divider()
                    
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // This will be handled by the parent view
                        }
                    }) {
                        HStack {
                            Image(systemName: "keyboard")
                                .foregroundColor(ColorTheme.primary)
                            Text("Enter food manually")
                                .foregroundColor(ColorTheme.primary)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: ColorTheme.shadowColor, radius: 10, y: -5)
            }
        }
    }
}

// Camera preview using UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    let cameraSession: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        print("🎥 Creating camera preview view")
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        view.accessibilityLabel = "Camera Preview"
        view.accessibilityTraits = .image
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        print("🎥 Camera preview layer created with session running: \(cameraSession.isRunning)")
        print("🎥 Preview layer frame: \(previewLayer.frame)")
        print("🎥 View bounds: \(view.bounds)")
        
        // Use CATransaction to ensure smooth layer updates
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        view.layer.addSublayer(previewLayer)
        CATransaction.commit()
        
        print("🎥 Camera preview layer added to view")
        
        // Ensure the layer gets properly sized after the view layout
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
            print("🎥 Preview layer frame set to view bounds: \(view.bounds)")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer else { return }
        
        print("🎥 Updating preview layer frame from \(previewLayer.frame) to \(uiView.bounds)")
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = uiView.bounds
        CATransaction.commit()
        
        print("🎥 Preview layer frame updated to: \(previewLayer.frame)")
    }
}

// RoundedCorner shape modifier
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
